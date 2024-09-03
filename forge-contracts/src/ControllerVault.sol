// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "wormhole-solidity-sdk/src/WormholeRelayerSDK.sol";
import "wormhole-solidity-sdk/src/interfaces/IERC20.sol";
import "./Controller.sol";
import "forge-std/console.sol";

contract ControllerVault is TokenReceiver {
    address public controller;
    mapping(address => mapping(address => uint256)) public routerDeposits;

    constructor(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole
    ) TokenBase(_wormholeRelayer, _tokenBridge, _wormhole) {}

    function setController(address _controller) external {
        // TODO: Add necessary access control
        require(controller == address(0), "Controller already set");
        controller = _controller;
    }

    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32, // sourceAddress
        uint16,
        bytes32 // deliveryHash
    ) internal override onlyWormholeRelayer {
        require(receivedTokens.length == 1, "Expected 1 token transfer");
        require(controller != address(0), "Controller not set");

        // address depositorRouter = abi.decode(payload, (address));
        (
            address depositorRouter,
            bytes32 idempotencyKey,
            ,
            uint256 usedTokens
        ) = abi.decode(payload, (address, bytes32, address, uint256));

        // Process the received token
        address token = receivedTokens[0].tokenAddress;
        uint256 amount = receivedTokens[0].amount;

        IERC20(token).transfer(controller, amount);

        // Call controller to submit receipt
        Controller(controller).submitReceipt(idempotencyKey, token, usedTokens);
        routerDeposits[depositorRouter][token] += amount;
    }
}
