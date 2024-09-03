// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "wormhole-solidity-sdk/src/WormholeRelayerSDK.sol";
import "wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";
import "wormhole-solidity-sdk/src/interfaces/IWormholeReceiver.sol";

import "forge-std/console.sol";

contract Controller is IWormholeReceiver {
    IWormholeRelayer public immutable wormholeRelayer;
    uint256 constant GAS_LIMIT = 250_000;

    enum OperationType {
        Low,
        Medium,
        High
    }

    struct IdempotencyData {
        address proxy;
        OperationType predictedTokenUsage;
        bool processed;
        uint256 expirationTime;
    }

    mapping(address => bool) public authorizedRouters;
    mapping(bytes32 => IdempotencyData) public idempotencyKeys;
    mapping(bytes32 => bytes32) public requestHashToKey;

    uint256 public expirationPeriod = 1 days;

    constructor(address _wormholeRelayer) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        authorizedRouters[_wormholeRelayer] = true;
    }

    modifier onlyRouter() {
        require(authorizedRouters[msg.sender], "Not an authorized router");
        _;
    }

    function registerRouter(address router) external {
        // TODO: Add necessary access control
        authorizedRouters[router] = true;
    }

    function getIdempotencyData(
        bytes32 key
    )
        public
        view
        returns (
            address proxy,
            OperationType predictedTokenUsage,
            bool processed,
            uint256 expirationTime
        )
    {
        IdempotencyData storage data = idempotencyKeys[key];
        return (
            data.proxy,
            data.predictedTokenUsage,
            data.processed,
            data.expirationTime
        );
    }

    function submitReceipt(bytes32 idempotencyKey) external onlyRouter {
        IdempotencyData storage data = idempotencyKeys[idempotencyKey];
        require(!data.processed, "Key already processed");
        require(block.timestamp <= data.expirationTime, "Key expired");
        data.processed = true;
    }

    function cleanUpExpiredKeys(bytes32[] calldata keys) external {
        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 key = keys[i];
            if (idempotencyKeys[key].expirationTime < block.timestamp) {
                delete idempotencyKeys[key];
            }
        }
    }

    function _generateKey(
        address proxy,
        bytes32 requestHash,
        OperationType predictedTokenUsage,
        uint256 fixedNonce
    ) public onlyRouter returns (bytes32) {
        bytes32 idempotencyKey = keccak256(
            abi.encodePacked(proxy, requestHash, fixedNonce)
        );

        console.log("Generated idempotencyKey:");
        console.logBytes32(idempotencyKey);

        require(
            !idempotencyKeys[idempotencyKey].processed,
            "Key already processed"
        );

        idempotencyKeys[idempotencyKey] = IdempotencyData({
            proxy: proxy,
            predictedTokenUsage: predictedTokenUsage,
            processed: false,
            expirationTime: block.timestamp + expirationPeriod
        });
        requestHashToKey[requestHash] = idempotencyKey;
        console.log("Key stored successfully");
        return idempotencyKey;
    }

    function quoteCrossChainGreeting(
        uint16 targetChain
    ) public view returns (uint256 cost) {
        (cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );
    }

    function sendCrossChainGreeting(
        uint16 targetChain,
        address targetAddress,
        bytes32 requestHash,
        uint256 operationType,
        uint256 fixedNonce
    ) public payable {
        uint256 cost = quoteCrossChainGreeting(targetChain);
        // require(msg.value == cost);
        //    address(this),

        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(address(this), requestHash, operationType, fixedNonce),
            0,
            GAS_LIMIT
        );
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32,
        uint16,
        bytes32
    ) public payable override {
        require(msg.sender == address(wormholeRelayer), "Only relayer allowed");

        (
            address proxy,
            bytes32 requestHash,
            uint256 predictedTokenUsage,
            uint256 fixedNonce
        ) = abi.decode(payload, (address, bytes32, uint256, uint256));

        console.log("Decoded payload:");
        console.log("Proxy:", proxy);
        console.logBytes32(requestHash);
        console.log("Predicted Token Usage:", predictedTokenUsage);
        console.log("Fixed Nonce:", fixedNonce);

        _generateKey(
            proxy,
            requestHash,
            OperationType(predictedTokenUsage),
            fixedNonce
        );
    }
}
