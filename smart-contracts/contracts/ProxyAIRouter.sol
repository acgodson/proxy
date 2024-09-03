// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./wormhole-sdk/wormhole-solidity-sdk-0.1.0/src/WormholeRelayerSDK.sol";
import "./wormhole-sdk/wormhole-solidity-sdk-0.1.0/src/interfaces/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Controller.sol";

abstract contract ProxyAIRouter is Ownable(msg.sender) {
    uint256 constant GAS_LIMIT = 250_000;

    uint16 constant targetChain = 14;
    address public controller;
    address public tokenAddress;

    enum OperationType {
        Low,
        Medium,
        High
    }

    constructor(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole,
        address _controller,
        address _feeToken
    ) TokenBase(_wormholeRelayer, _tokenBridge, _wormhole) {
        controller = _controller;
        tokenAddress = _feeToken;
    }

    mapping(address => uint256) public feeTank;
    mapping(address => bool) public routerAdmins;

    function _generateKey(
        bytes32 requestHash,
        uint256 fixedNonce,
        uint256 operationType
    ) internal returns (bytes32) {
        Controller.OperationType _operationType = Controller.OperationType(
            operationType
        );
        uint256 maxFee = calculateMaxFee(_operationType);

        // Ensure the admin (msg.sender) has sufficient fee balance
        require(feeTank[msg.sender] >= maxFee, "Insufficient fee balance");

        // Commit the maximum fee for this request
        feeTank[msg.sender] -= maxFee;

        // send cross chain message to generate key
        bytes32 idempotencyKey = Controller(controller).generateKey(
            address(this),
            requestHash,
            _operationType,
            fixedNonce
        );

        return idempotencyKey;
    }

    function _submitReceipt(
        bytes32 idempotencyKey,
        uint256 usedTokens
    ) external onlyOwner {
        (, Controller.OperationType maxFee, , ) = Controller(controller)
            .idempotencyKeys(idempotencyKey);

        // Refund excess fees if any, back to the feeTank
        uint256 refund = 0;
        if (uint256(maxFee) > usedTokens) {
            refund = uint256(maxFee) - usedTokens;
            feeTank[msg.sender] += refund;
        }

        // Transfer only the used tokens to the Controller //TODO: handle cross-chain scenarios
        IERC20(tokenAddress).transfer(controller, usedTokens);

        // Mark the receipt as processed in the Controller
        Controller(controller).submitReceipt(idempotencyKey);
        _onReceipt(idempotencyKey, usedTokens);
    }

    function _onReceipt(
        bytes32 idempotencyKey,
        uint256 usedTokens
    ) internal virtual {
        // Default implementation (if any)
    }

    function registerAdmin(address admin) external onlyOwner {
        routerAdmins[admin] = true;
    }

    function depositToFeeTank(uint256 amount) external {
        require(routerAdmins[msg.sender], "Only admin can deposit");
        feeTank[msg.sender] += amount;

        // Logic to handle ERC20 transfer
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Transfer failed"
        );
    }

    function withdrawFromFeeTank(uint256 amount) external {
        require(routerAdmins[msg.sender], "Only admin can withdraw");
        require(feeTank[msg.sender] >= amount, "Insufficient reserve");

        feeTank[msg.sender] -= amount;

        // Logic to handle ERC20 transfer
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "Transfer failed"
        );
    }

    function calculateMaxFee(
        Controller.OperationType operationType
    ) internal pure returns (uint256) {
        // Demo logic to calculate max fee based on operation type
        if (operationType == Controller.OperationType.Low) {
            return 10 * 1e18;
        } else if (operationType == Controller.OperationType.Medium) {
            return 20 * 1e18;
        } else if (operationType == Controller.OperationType.High) {
            return 30 * 1e18;
        }
        return 0;
    }
}
