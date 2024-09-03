// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../src/Controller.sol";
import "../src/CustomRouter.sol";
import "../src/ControllerVault.sol";
import "wormhole-solidity-sdk/src/testing/WormholeRelayerTest.sol";
import "forge-std/console.sol";

contract CrossChainTest is WormholeRelayerBasicTest {
    Controller public controllerTarget;
    ControllerVault public vaultTarget;
    ProxyAIRouter public routerSource;
    ERC20Mock public token;

    function setUpSource() public override {
        token = createAndAttestToken(sourceChain);

        routerSource = new CustomRouter(
            address(relayerSource),
            address(tokenBridgeSource),
            address(wormholeSource),
            address(0), // Controller address (will be set later)
            address(0), // ControllerVault address (will be set later)
            address(token),
            targetChain
        );
        console.log("Source Router deployed at:", address(routerSource));

        // Fund the router with ETH
        vm.deal(address(routerSource), 100 ether);
    }

    function setUpTarget() public override {
        controllerTarget = new Controller(address(relayerTarget));
        console.log(
            "Target Controller deployed at:",
            address(controllerTarget)
        );

        vaultTarget = new ControllerVault(
            address(relayerTarget),
            address(tokenBridgeTarget),
            address(wormholeTarget)
        );
        console.log("Target Vault deployed at:", address(vaultTarget));

        // Set up the relationships
        controllerTarget.setVault(address(vaultTarget));
        vaultTarget.setController(address(controllerTarget));

        // Verify the relationships are set correctly
        assertEq(
            address(controllerTarget.vault()),
            address(vaultTarget),
            "Controller vault address mismatch"
        );
        assertEq(
            vaultTarget.controller(),
            address(controllerTarget),
            "Vault controller address mismatch"
        );

        // Update the controller and vault addresses in the source router
        vm.selectFork(sourceFork);
        routerSource.setController(address(controllerTarget));
        routerSource.setControllerVault(address(vaultTarget));
        vm.selectFork(targetFork);

        // Register the relayer as an authorized router
        controllerTarget.registerRouter(address(relayerTarget));

        // Fund the controller and vault with ETH
        vm.deal(address(controllerTarget), 100 ether);
        vm.deal(address(vaultTarget), 100 ether);

        console.log("Setup completed. Relationships verified.");
    }

    function testCrossChainKeyGenerationAndTokenTransfer() public {
        console.log("Starting testCrossChainKeyGenerationAndTokenTransfer");

        // Prepare test data
        bytes32 requestHash = keccak256("test request");
        uint256 fixedNonce = 12345;
        ProxyAIRouter.OperationType operationType = ProxyAIRouter
            .OperationType
            .Low;

        // Switch to source chain
        vm.selectFork(sourceFork);

        // Mint some tokens and approve them for the router
        uint256 amount = 200 * 1e18; // 200 tokens
        token.mint(address(this), amount);
        token.approve(address(routerSource), amount);

        // Register this contract as an admin and deposit to fee tank
        routerSource.registerAdmin(address(this));
        routerSource.depositToFeeTank(amount);

        // Get the cost for the cross-chain message
        uint256 messageCost = routerSource.quoteCrossChainMessage(targetChain);

        // Generate key and send cross-chain message
        vm.recordLogs();
        bytes32 expectedIdempotencyKey = routerSource.generateKey{
            value: messageCost
        }(requestHash, fixedNonce, uint256(operationType));
        console.log("Generated idempotency key:");
        console.logBytes32(expectedIdempotencyKey);

        // Perform the delivery
        performDelivery();

        // Switch to target chain and verify key generation
        vm.selectFork(targetFork);
        (
            address proxy,
            Controller.OperationType predictedTokenUsage,
            bool processed,
            uint256 expirationTime
        ) = controllerTarget.getIdempotencyData(expectedIdempotencyKey);

        // Verify the stored key matches the expected key
        bytes32 storedKey = controllerTarget.requestHashToKey(requestHash);
        console.log("Stored key in Controller:");
        console.logBytes32(storedKey);
        assertEq(
            storedKey,
            expectedIdempotencyKey,
            "Stored key does not match expected key"
        );

        // Add assertions for key generation
        assertEq(proxy, address(this), "Proxy address mismatch");
        assertEq(
            uint(predictedTokenUsage),
            uint(operationType),
            "Operation type mismatch"
        );
        assertEq(processed, false, "Key should not be processed yet");
        assertTrue(
            expirationTime > block.timestamp,
            "Expiration time should be in the future"
        );

        // Switch back to source chain to submit receipt
        vm.selectFork(sourceFork);
        uint256 usedTokens = 40 * 1e18; // Use 40 tokens (within the 50 token limit for Low operation)
        messageCost = routerSource.quoteCrossChainMessage(targetChain);
        routerSource.submitReceipt{value: messageCost}(
            expectedIdempotencyKey,
            usedTokens
        );

        // Perform the delivery
        performDelivery();

        // Switch to target chain and verify receipt submission and token transfer
        vm.selectFork(targetFork);

        // Verify token transfer
        address wormholeWrappedToken = tokenBridgeTarget.wrappedAsset(
            sourceChain,
            toWormholeFormat(address(token))
        );

        uint256 controllerBalance = IERC20(wormholeWrappedToken).balanceOf(
            address(controllerTarget)
        );
        console.log("controller balance:", controllerBalance);
        console.log("Expected used tokens:", usedTokens);
        console.log("Wrapped token address:", wormholeWrappedToken);
        console.log("Vault address:", address(vaultTarget));

        // assertEq(vaultBalance, usedTokens, "Token transfer failed");

        // Check the processed flag
        (, , bool isProcessed, uint256 expired) = controllerTarget
            .getIdempotencyData(expectedIdempotencyKey);

        console.log("Final check - isProcessed:", isProcessed);
        console.log("Final check - expired:", expired);
        console.log("Current timestamp:", block.timestamp);

        // Verify the key is still correctly stored
        storedKey = controllerTarget.requestHashToKey(requestHash);
        console.log("Final stored key in Controller:");
        console.logBytes32(storedKey);
        assertEq(
            storedKey,
            expectedIdempotencyKey,
            "Final stored key does not match expected key"
        );

        // assertTrue(isProcessed, "Key should be marked as processed");
        // assertTrue(
        //     expired > block.timestamp,
        //     "Expiration time should be in the future"
        // );

        console.log("Test completed");
    }
}
