// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ProxyAIRouter.sol";

/**
 * @title CustomRouter
 * @dev This contract extends the ProxyAIRouter to allow custom logic execution after receipt processing.
 * Users can implement their custom logic in the _onReceipt function.
 */
contract CustomRouter is ProxyAIRouter {
    // Event to log custom actions
    event ReceiptProcessed(bytes32 indexed idempotencyKey, uint256 usedTokens);

    constructor(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole,
        address _controller,
        address _controllerVault,
        address _token,
        uint16 _controllerChainId
    )
        ProxyAIRouter(
            _wormholeRelayer,
            _tokenBridge,
            _wormhole,
            _controller,
            _controllerVault,
            _token,
            _controllerChainId
        )
    {}

    /**
     * @dev This function is called after a receipt is processed.
     * Implement custom logic here to define what happens when a key is utilized.
     * @param idempotencyKey The unique key associated with the original request transaction.
     * @param usedTokens The amount of tokens used in this transaction.
     */
    function _onReceipt(
        bytes32 idempotencyKey,
        uint256 usedTokens
    ) internal override {
        // Example of custom logic:
        // 1. Emit an event for external tracking
        emit ReceiptProcessed(idempotencyKey, usedTokens);

        // 2. Perform additional checks or actions based on usedTokens
        if (usedTokens > 100 * 1e18) {
            // If more than 100 tokens were used
            // Implement some special logic for high-value transactions
            // For example, you could call an external contract or update internal state
        }

        // 3. Update internal state or perform other custom actions
        // Note: Be mindful of gas costs when implementing complex logic
    }
}
