// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "wormhole-solidity-sdk/src/WormholeRelayerSDK.sol";
import "wormhole-solidity-sdk/src/interfaces/IERC20.sol";
import "wormhole-solidity-sdk/src/interfaces/IWETH.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract ProxyAIRouter is Ownable, TokenSender {
    uint256 constant GAS_LIMIT = 250_000;

    address public controller;
    address public controllerVault;
    IERC20 public token;
    uint16 public controllerChainId;

    mapping(address => uint256) public feeTank;
    mapping(address => bool) public routerAdmins;
    mapping(bytes32 => uint256) public idempotencyKeyToTokenAmount;

    enum OperationType {
        Low,
        Medium,
        High
    }

    enum FunctionType {
        GenerateKey,
        SubmitReceipt
    }

    constructor(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole,
        address _controller,
        address _controllerVault,
        address _token,
        uint16 _controllerChainId
    ) TokenBase(_wormholeRelayer, _tokenBridge, _wormhole) {
        controller = _controller;
        controllerVault = _controllerVault;
        controllerChainId = _controllerChainId;
        token = IERC20(_token);
    }

    function setController(address _controller) external onlyOwner {
        controller = _controller;
    }

    function setControllerVault(address _controllerVault) external onlyOwner {
        controllerVault = _controllerVault;
    }

    function setControllerChainId(
        uint16 _controllerChainId
    ) external onlyOwner {
        controllerChainId = _controllerChainId;
    }

    function registerAdmin(address admin) external onlyOwner {
        routerAdmins[admin] = true;
    }

    function depositToFeeTank(uint256 amount) external {
        require(routerAdmins[msg.sender], "Only admin can deposit");
        feeTank[msg.sender] += amount;

        // Logic to handle ERC20 transfer
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
    }

    function withdrawFromFeeTank(uint256 amount) external {
        require(routerAdmins[msg.sender], "Only admin can withdraw");
        require(feeTank[msg.sender] >= amount, "Insufficient reserve");
        feeTank[msg.sender] -= amount;
        IERC20(token).transfer(msg.sender, amount);
    }

    function generateKey(
        bytes32 requestHash,
        uint256 fixedNonce,
        uint256 operationType
    ) external payable virtual returns (bytes32) {
        return _generateKey(requestHash, fixedNonce, operationType);
    }

    function submitReceipt(
        bytes32 idempotencyKey,
        uint256 usedTokens
    ) external payable virtual {
        _submitReceipt(idempotencyKey, usedTokens);
    }

    function _generateKey(
        bytes32 requestHash,
        uint256 fixedNonce,
        uint256 operationType
    ) internal returns (bytes32) {
        bytes memory payload = abi.encode(
            FunctionType.GenerateKey,
            abi.encode(msg.sender, requestHash, operationType, fixedNonce)
        );

        uint256 cost = quoteCrossChainMessage(controllerChainId);
        require(
            msg.value >= cost,
            "Insufficient payment for cross-chain message"
        );

        uint256 maxFee = calculateMaxFee(OperationType(operationType));

        // Ensure the admin (msg.sender) has sufficient fee balance
        require(
            feeTank[msg.sender] >= maxFee,
            "Insufficient token for service  payment"
        );

        // Deduct the maxFee from the feeTank
        feeTank[msg.sender] -= maxFee;

        //send only payload to Controller
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            controllerChainId,
            controller,
            payload,
            0,
            GAS_LIMIT
        );

        bytes32 idempotencyKey = keccak256(
            abi.encodePacked(msg.sender, requestHash, fixedNonce)
        );

        idempotencyKeyToTokenAmount[idempotencyKey] = maxFee;

        return idempotencyKey;
    }

    function _submitReceipt(
        bytes32 idempotencyKey,
        uint256 usedTokens
    ) internal {
        uint256 maxFee = idempotencyKeyToTokenAmount[idempotencyKey];
        require(maxFee > 0, "No tokens held for this idempotency key");
        require(usedTokens <= maxFee, "Used tokens cannot exceed max fee");

        uint256 cost = quoteCrossChainMessage(controllerChainId);

        require(
            msg.value >= cost,
            "Insufficient payment for cross-chain message"
        );

        uint256 refund = 0;
        if (uint256(maxFee) > usedTokens) {
            refund = uint256(maxFee) - usedTokens;
            feeTank[msg.sender] += refund;
        }

        // Combine vault and controller payloads
        bytes memory combinedPayload = abi.encode(
            address(this), // depositor router address
            idempotencyKey,
            address(token),
            usedTokens
        );

        sendTokenWithPayloadToEvm(
            controllerChainId,
            controllerVault,
            combinedPayload,
            0,
            GAS_LIMIT,
            address(token),
            usedTokens
        );

        delete idempotencyKeyToTokenAmount[idempotencyKey];

        _onReceipt(idempotencyKey, usedTokens);
    }

    function _onReceipt(
        bytes32 idempotencyKey,
        uint256 usedTokens
    ) internal virtual {
        // Default implementation (if any)
    }

    function quoteCrossChainMessage(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
    }

    function calculateMaxFee(
        OperationType operationType
    ) internal pure returns (uint256) {
        if (operationType == OperationType.Low) {
            return 50 * 1e18; // 50 tokens
        } else if (operationType == OperationType.Medium) {
            return 100 * 1e18; // 100 tokens
        } else if (operationType == OperationType.High) {
            return 200 * 1e18; // 200 tokens
        }
        return 0;
    }
}
