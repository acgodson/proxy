# ProxyAI (working title)

A decentralized middleware that allows users to securely share, access, and pay for AI services like GPT, using tokenized credits across multiple blockchain network.


### Cross-chain compatibility with Wormhole

1. **Controller Contract**:

   - Central contract that manages idempotency key generation and token usage.
   - Only allows certain `ProxyAIRouter` contracts (one per chain) to interact with it.
   - Handles fee transfers from the `ProxyAIRouter`.

2. **ProxyAIRouter Contract**:

   - Acts as a router on each chain.
   - Calls the `Controller` contract to generate keys and submit receipts.
   - Manages gas fee payments and token transfers on behalf of users.
   - Has permissions to interact with the `Controller`.

3. **CustomRouter Contract**:
   - Customizable contract deployed by users.
   - Uses the `ProxyAIRouter` to interact with the `Controller`.
   - Allows users/developers to implement custom logic around key generation and receipt handling.

## Forge Test

````bash
cd forge-contracts
npm install
`

```bash

````

## Typescript test

