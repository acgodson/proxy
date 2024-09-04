# ProxyAI (working title)


give me a readme adjustments from the cross compatibility section, help me describe how our contracts use wormhole relayer SDK and co


# wormhole proxy 


A decentralized middleware that allows users to securely share, access, and pay for AI services like GPT, using tokenized credits across multiple blockchain network.



### **Problem Summary**

Access to pro-level APIs from popular AI models like OpenAI is severely limited by discriminatory Web2 payment options, such as Stripe, which is only available in 48 countries.

This restriction disproportionately affects developers in developing regions, like Nigeria, where as much as 3 million developers struggle with payment limitations.

Additionally, the whole cost of some of the APIs, such as Claude's $20 per month fee, makes these services unaffordable for many, particularly in countries where this cost exceeds the minimum wage.

Even though some existing Web3 SaaS platforms offer partitioned access to some APIs. They lack verifiability in usage metrics and force users into rigid, non-customizable interfaces.

ProxyAI provides a decentralized, customizable, and verifiable middleware for accessing AI services with tokens as a bypass to traditional payment systems and native gas fees. Making AI services truly verifable, and more accessible to a global audience.

Decentralized middleware that allows developers to securely share, access, and pay for AI usage with tokenized credits from across multiple blockchains

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



## Testing 

```bash
cd forge-contracts
npm install
`

```bash

```