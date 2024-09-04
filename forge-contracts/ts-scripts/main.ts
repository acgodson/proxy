import { ethers } from "ethers";
import {
  deployController,
  deployControllerVault,
  deployCustomRouter,
  deployERC20Mock,
} from "./deploy";
import {
  getWallet,
  loadConfig,
  getChain,
  wait,
  getController,
  getControllerVault,
  getCustomRouter,
  getERC20Mock,
} from "./utils";
import {
  Controller__factory,
  ControllerVault__factory,
  CustomRouter__factory,
  ERC20Mock__factory,
} from "./ethers-contracts";
import {
  waitForDelivery,
  chainIdToName,
  DeliveryStatus,
} from "./wormhole-utils";

// Nonce Manager class
class NonceManager {
  private provider: ethers.providers.Provider;
  private address: string;
  private nextNonce: number | null = null;

  constructor(provider: ethers.providers.Provider, address: string) {
    this.provider = provider;
    this.address = address;
  }

  async getNextNonce(): Promise<number> {
    if (this.nextNonce === null) {
      this.nextNonce = await this.provider.getTransactionCount(this.address);
    }
    return this.nextNonce++;
  }

  reset() {
    this.nextNonce = null;
  }
}

// Retry function with exponential backoff
async function retry<T>(
  operation: () => Promise<T>,
  maxRetries: number = 3,
  delay: number = 1000
): Promise<T> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      console.log(`Operation failed, retrying... (${i + 1}/${maxRetries})`);
      await new Promise((resolve) =>
        setTimeout(resolve, delay * Math.pow(2, i))
      );
    }
  }
  throw new Error("Max retries reached");
}

async function main() {
  console.log("Starting Cross-Chain Key Generation and Token Transfer Test");

  const config = loadConfig();
  const sourceChain = config.sourceChain;
  const targetChain = config.targetChain;

  // Create nonce managers
  const sourceWallet = getWallet(sourceChain);
  const targetWallet = getWallet(targetChain);
  const sourceNonceManager = new NonceManager(
    sourceWallet.provider,
    sourceWallet.address
  );
  const targetNonceManager = new NonceManager(
    targetWallet.provider,
    targetWallet.address
  );

  // Deploy contracts on source chain
  console.log("Deploying contracts on source chain...");
  const token = await retry(() => deployERC20Mock(sourceChain));

  const sourceChainInfo = getChain(sourceChain);

  const routerSource = await retry(() =>
    deployCustomRouter(sourceChain, token.address, targetChain)
  );

  console.log("Source Router deployed at:", routerSource.address);

  // Deploy contracts on target chain
  console.log("Deploying contracts on target chain...");
  const targetChainInfo = getChain(targetChain);
  const controllerTarget = await retry(() => deployController(targetChain));
  console.log("Target Controller deployed at:", controllerTarget.address);

  const vaultTarget = await retry(() => deployControllerVault(targetChain));
  console.log("Target Vault deployed at:", vaultTarget.address);

  // Set up relationships
  await retry(() =>
    controllerTarget.setVault(vaultTarget.address, {
      nonce: targetNonceManager.getNextNonce(),
    })
  );
  await retry(() =>
    vaultTarget.setController(controllerTarget.address, {
      nonce: targetNonceManager.getNextNonce(),
    })
  );
  await retry(() =>
    routerSource.setController(controllerTarget.address, {
      nonce: sourceNonceManager.getNextNonce(),
    })
  );
  await retry(() =>
    routerSource.setControllerVault(vaultTarget.address, {
      nonce: sourceNonceManager.getNextNonce(),
    })
  );

  // Verify relationships
  console.log("Verifying relationships...");
  const controllerVaultAddress = await controllerTarget.vault();
  const vaultControllerAddress = await vaultTarget.controller();
  console.assert(
    controllerVaultAddress === vaultTarget.address,
    "Controller vault address mismatch"
  );
  console.assert(
    vaultControllerAddress === controllerTarget.address,
    "Vault controller address mismatch"
  );

  // Register the relayer as an authorized router
  await retry(() =>
    controllerTarget.registerRouter(targetChainInfo.wormholeRelayer, {
      nonce: targetNonceManager.getNextNonce(),
    })
  );

  console.log("Setup completed. Relationships verified.");

  // Prepare test data
  const requestHash = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("test request")
  );
  const fixedNonce = 12345;
  const operationType = 0; // Low

  // Mint tokens and approve them for the router
  // Mint tokens and approve them for the router
  const amount = ethers.utils.parseEther("1000"); // Increased amount for safety
  await token
    .mint(sourceWallet.address, amount, {
      nonce: await sourceNonceManager.getNextNonce(),
    })
    .then(wait);

  // Check token balance
  const balance = await token.balanceOf(sourceWallet.address);

  console.log("Token balance:", ethers.utils.formatEther(balance));

  if (balance.lt(amount)) {
    await token
      .mint(sourceWallet.address, amount.sub(balance), {
        nonce: await sourceNonceManager.getNextNonce(),
      })
      .then(wait);
  }

  // Check and increase token approval if necessary
  const currentAllowance = await token.allowance(
    sourceWallet.address,
    routerSource.address
  );

  if (currentAllowance.lt(amount)) {
    console.log("Increasing token approval...");
    await token
      .approve(routerSource.address, ethers.constants.MaxUint256, {
        nonce: await sourceNonceManager.getNextNonce(),
      })
      .then(wait);
  }

  // Register as admin and deposit to fee tank
  await retry(async () =>
    routerSource
      .registerAdmin(sourceWallet.address, {
        nonce: await sourceNonceManager.getNextNonce(),
      })
      .then(wait)
  );
  await retry(async () =>
    routerSource
      .depositToFeeTank(amount, {
        nonce: await sourceNonceManager.getNextNonce(),
      })
      .then(wait)
  );

  // Generate key and send cross-chain message
  console.log("Generating key and sending cross-chain message...");
  const messageCost = await routerSource.quoteCrossChainMessage(targetChain);
  const generateKeyTx = await retry(() =>
    routerSource.generateKey(requestHash, fixedNonce, operationType, {
      value: messageCost,
      nonce: sourceNonceManager.getNextNonce(),
    })
  );

  await generateKeyTx.wait();

  // Wait for the message to be delivered
  console.log("Waiting for message delivery...");
  const deliveryResult = await waitForDelivery(
    chainIdToName(sourceChain),
    generateKeyTx.hash
  );

  // Retrieve the generated key from the controller
  const expectedIdempotencyKey = await controllerTarget.requestHashToKey(
    requestHash
  );
  console.log("Generated idempotency key:", expectedIdempotencyKey);

  // Verify key generation on target chain
  console.log("Verifying key generation on target chain...");
  const idempotencyData = await controllerTarget.getIdempotencyData(
    expectedIdempotencyKey
  );
  console.log("Idempotency data:", idempotencyData);

  // Verify stored key
  const storedKey = await controllerTarget.requestHashToKey(requestHash);
  console.assert(
    storedKey === expectedIdempotencyKey,
    "Stored key does not match expected key"
  );

  // Submit receipt
  console.log("Submitting receipt...");
  const usedTokens = ethers.utils.parseEther("40");
  const submitReceiptTx = await retry(() =>
    routerSource.submitReceipt(expectedIdempotencyKey, usedTokens, {
      value: messageCost,
      nonce: sourceNonceManager.getNextNonce(),
    })
  );
  await submitReceiptTx.wait();

  // Wait for the receipt to be processed
  console.log("Waiting for receipt processing...");
  await waitForDelivery(chainIdToName(sourceChain), submitReceiptTx.hash);

  // Verify receipt submission and token transfer
  console.log("Verifying receipt submission and token transfer...");
  const tokenBridgeTarget = new ethers.Contract(
    targetChainInfo.tokenBridge,
    [
      "function wrappedAsset(uint16 chainId, bytes32 tokenAddress) view returns (address)",
    ],
    targetWallet
  );
  const wormholeWrappedToken = await tokenBridgeTarget.wrappedAsset(
    sourceChain,
    ethers.utils.hexZeroPad(token.address, 32)
  );
  const controllerBalance = await ERC20Mock__factory.connect(
    wormholeWrappedToken,
    targetWallet
  ).balanceOf(controllerTarget.address);

  console.log("Controller balance:", controllerBalance.toString());
  console.log("Expected used tokens:", usedTokens.toString());

  // Final checks
  const finalIdempotencyData = await controllerTarget.getIdempotencyData(
    expectedIdempotencyKey
  );
  console.log("Final idempotency data:", finalIdempotencyData);

  const finalStoredKey = await controllerTarget.requestHashToKey(requestHash);
  console.assert(
    finalStoredKey === expectedIdempotencyKey,
    "Final stored key does not match expected key"
  );

  console.log("Test completed");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
