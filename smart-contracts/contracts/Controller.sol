// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address reciever, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

contract Controller {
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

    modifier onlyRouter() {
        require(authorizedRouters[msg.sender], "Not an authorized router");
        _;
    }

    // Function to register a router
    function registerRouter(address router) external {
        // Add necessary access control to restrict who can register routers
        authorizedRouters[router] = true;
    }

    // Function to generate idempotency key
    function generateKey(
        address proxy,
        bytes32 requestHash,
        OperationType predictedTokenUsage,
        uint256 fixedNonce
    ) external onlyRouter returns (bytes32) {
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
        return idempotencyKey;
    }

    // Function to submit receipts
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
}
