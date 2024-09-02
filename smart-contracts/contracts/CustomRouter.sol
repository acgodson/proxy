// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyAIRouter.sol";

contract CustomRouter is ProxyAIRouter {
    constructor(
        address _controller,
        address tokenAddress
    ) ProxyAIRouter(_controller, tokenAddress) {}

    // Function to generate idempotency key using the base contract's logic
    function generateKey(
        bytes32 requestHash,
        uint256 fixedNonce,
        uint256 operationType
    ) external returns (bytes32) {
        return _generateKey(requestHash, fixedNonce, operationType);
    }

    function _onReceipt(
        bytes32 idempotencyKey,
        uint256 usedTokens
    ) internal override {
        // Custom logic (if any)
    }
}
