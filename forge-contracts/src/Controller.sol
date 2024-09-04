// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "wormhole-solidity-sdk/src/WormholeRelayerSDK.sol";
import "wormhole-solidity-sdk/src/interfaces/IWormholeReceiver.sol";
import "./ControllerVault.sol";

contract Controller is IWormholeReceiver {
    uint256 public expirationPeriod = 1 days;
    IWormholeRelayer public immutable wormholeRelayer;
    ControllerVault public vault;

    enum OperationType {
        Low,
        Medium,
        High
    }

    enum FunctionType {
        GenerateKey,
        SubmitReceipt
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

    event KeyGenerated(
        bytes32 indexed idempotencyKey,
        address proxy,
        uint16 sourceChain,
        bytes32 sourceAddress
    );
    event ReceiptSubmitted(
        bytes32 indexed idempotencyKey,
        address token,
        uint256 usedTokens
    );

    constructor(address _wormholeRelayer) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    modifier onlyAuthorizedRouter() {
        require(authorizedRouters[msg.sender], "Not an authorized router");
        _;
    }

    function setVault(address _vault) external {
        // TODO: Add necessary access control
        require(address(vault) == address(0), "Vault already set");
        vault = ControllerVault(_vault);
    }

    function registerRouter(address router) external {
        // TODO: Add necessary access control
        authorizedRouters[router] = true;
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory,
        bytes32,
        uint16 sourceChain,
        bytes32 sourceAddress
    ) public payable override onlyAuthorizedRouter {
        (FunctionType functionType, bytes memory functionPayload) = abi.decode(
            payload,
            (FunctionType, bytes)
        );

        if (functionType == FunctionType.GenerateKey) {
            _handleGenerateKey(functionPayload, sourceChain, sourceAddress);
        } else {
            revert("Unsupported function");
        }
    }

    function _handleGenerateKey(
        bytes memory functionPayload,
        uint16 sourceChain,
        bytes32 sourceAddress
    ) internal {
        (
            address proxy,
            bytes32 requestHash,
            OperationType predictedTokenUsage,
            uint256 fixedNonce
        ) = abi.decode(
                functionPayload,
                (address, bytes32, OperationType, uint256)
            );

        bytes32 idempotencyKey = keccak256(
            abi.encodePacked(proxy, requestHash, fixedNonce)
        );

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

        // Emit an event or perform any other necessary actions
        emit KeyGenerated(idempotencyKey, proxy, sourceChain, sourceAddress);
    }

    function submitReceipt(
        bytes32 idempotencyKey,
        address token,
        uint256 usedTokens
    ) external {
        require(msg.sender == address(vault), "Only vault can submit receipt");
        IdempotencyData storage data = idempotencyKeys[idempotencyKey];
        require(!data.processed, "Key already processed");
        require(block.timestamp <= data.expirationTime, "Key expired");

        data.processed = true;
        emit ReceiptSubmitted(idempotencyKey, token, usedTokens);
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

    function cleanUpExpiredKeys(bytes32[] calldata keys) external {
        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 key = keys[i];
            if (idempotencyKeys[key].expirationTime < block.timestamp) {
                delete idempotencyKeys[key];
            }
        }
    }
}
