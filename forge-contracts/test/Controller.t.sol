// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../src/Controller.sol";
import "wormhole-solidity-sdk/src/testing/WormholeRelayerTest.sol";
import "forge-std/console.sol";

contract ControllerTest is WormholeRelayerBasicTest {
    Controller controllerSource;
    Controller controllerTarget;

    function setUpSource() public override {
        controllerSource = new Controller(address(relayerSource));
        console.log("Source Controller deployed at:", address(controllerSource));
        console.log("Source Relayer:", address(relayerSource));
    }

    function setUpTarget() public override {
        controllerTarget = new Controller(address(relayerTarget));
        console.log("Target Controller deployed at:", address(controllerTarget));
        console.log("Target Relayer:", address(relayerTarget));
    }

    function testCrossChainKeyGeneration() public {
        console.log("Starting testCrossChainKeyGeneration");

        // Register the contracts as authorized routers
        controllerSource.registerRouter(address(controllerSource));
        console.log("Source Controller registered as router");
        vm.selectFork(targetFork);
        controllerTarget.registerRouter(address(controllerTarget));
        console.log("Target Controller registered as router");
        vm.selectFork(sourceFork);

        // Prepare test data
        bytes32 requestHash = keccak256("test request");
        uint256 operationType = 0; // Low
        uint256 fixedNonce = 12345;

        console.log("Request Hash:");
        console.logBytes32(requestHash);
        console.log("Operation Type:", operationType);
        console.log("Fixed Nonce:", fixedNonce);

        // Quote and send cross-chain greeting
        uint256 cost = controllerSource.quoteCrossChainGreeting(targetChain);
        console.log("Quoted cost:", cost);
        vm.recordLogs();
        
        controllerSource.sendCrossChainGreeting{value: cost}(
            targetChain,
            address(controllerTarget),
            requestHash,
            operationType,
            fixedNonce
        );
        console.log("Cross-chain greeting sent");

        // Perform the delivery
        console.log("Performing delivery...");
        performDelivery();
        console.log("Delivery performed");

        // Switch to target chain and verify key generation
        vm.selectFork(targetFork);
        console.log("Switched to target fork");

        // Calculate the expected idempotency key
        bytes32 expectedKey = keccak256(
            abi.encodePacked(address(controllerSource), requestHash, fixedNonce)
        );
        console.log("Expected key:");
        console.logBytes32(expectedKey);

        // Check if the key exists
        bytes32 storedKey = controllerTarget.requestHashToKey(requestHash);
        console.log("Stored key:");
        console.logBytes32(storedKey);

        if (storedKey == bytes32(0)) {
            console.log("WARNING: No key stored for the given requestHash");
        } else {
            console.log("Key found in requestHashToKey mapping");
        }

        // Verify the key was generated and stored correctly
        (
            address proxy,
            Controller.OperationType predictedTokenUsage,
            bool processed,
            uint256 expirationTime
        ) = controllerTarget.getIdempotencyData(storedKey);

        console.log("Retrieved IdempotencyData:");
        console.log("Proxy:", proxy);
        console.log("Predicted Token Usage:", uint(predictedTokenUsage));
        console.log("Processed:", processed);
        console.log("Expiration Time:", expirationTime);

        // Add assertions here
        assertEq(storedKey, expectedKey, "Stored key mismatch");
        assertEq(proxy, address(controllerSource), "Proxy address mismatch");
        assertEq(uint(predictedTokenUsage), operationType, "Operation type mismatch");
        assertEq(processed, false, "Key should not be processed yet");
        assertTrue(expirationTime > block.timestamp, "Expiration time should be in the future");

        console.log("Test completed");
    }
}