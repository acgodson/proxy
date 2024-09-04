import { ethers } from "ethers";
import { ERC20Mock__factory } from "../ethers-contracts";
import {
  getChain,
  getWallet,
  loadDeployedAddresses,
  storeDeployedAddresses,
  loadConfig,
} from "../utils";
import { attestFromEth, parseSequenceFromLogEth, getSignedVAAWithRetry, ChainId, tryNativeToHexString, createWrappedOnEth } from "@certusone/wormhole-sdk";
import * as grpcWebNodeHttpTransport from "@improbable-eng/grpc-web-node-http-transport";


interface DeploymentOptions {
  gasLimit?: number;
  gasPriceGwei?: number;
  timeout?: number;
}

export async function deployERC20Mock(
  chainId: number,
  options: DeploymentOptions = {}
) {
  const signer = getWallet(chainId);
  const chainInfo = getChain(chainId);

  const { gasLimit = 3000000, gasPriceGwei, timeout = 180000 } = options;

  // Estimate gas and get current gas price
  const factory = new ERC20Mock__factory(signer);
  const deploymentData = factory.getDeployTransaction("test USDC", "tUSDC");

  console.log("Estimating gas...");
  const estimatedGas = await signer.estimateGas(deploymentData);
  console.log(`Estimated gas: ${estimatedGas.toString()}`);

  const currentGasPrice = await signer.getGasPrice();
  const gasPrice = gasPriceGwei
    ? ethers.utils.parseUnits(gasPriceGwei.toString(), "gwei")
    : currentGasPrice;

  console.log(`Using gas limit: ${gasLimit}`);
  console.log(
    `Using gas price: ${ethers.utils.formatUnits(gasPrice, "gwei")} gwei`
  );

  const token = await factory.deploy("test USDC", "tUSDC", {
    gasLimit: gasLimit,
    gasPrice: gasPrice,
  });
  console.log(`Transaction sent. Hash: ${token.deployTransaction.hash}`);
  console.log(`Waiting for transaction to be mined...`);
  try {
    const deploymentPromise = token.deployed();
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(
        () => reject(new Error("Deployment confirmation timed out")),
        timeout
      )
    );

    await Promise.race([deploymentPromise, timeoutPromise]);

    console.log(
      `ERC20Mock deployed and confirmed at ${token.address} on chain ${chainId}`
    );
  } catch (error) {
    console.error(`Error waiting for deployment confirmation:`, error);
    console.log(
      `Transaction may still be pending. Please check the transaction status manually.`
    );

    // Offer manual confirmation
    const manualConfirm = await askForManualConfirmation(
      token.address,
      chainInfo.explorer
    );
    if (!manualConfirm) {
      throw new Error("Deployment not confirmed");
    }
  }
  const deployed = await loadDeployedAddresses();
  if (!deployed.erc20s[chainId]) {
    deployed.erc20s[chainId] = [];
  }
  deployed.erc20s[chainId].push(token.address);
  await storeDeployedAddresses(deployed);

   // Attest the token
   const config = loadConfig();
   const targetChain = config.targetChain;
 
   console.log(`Attesting token to chain ${targetChain}`);
   await attestWorkflow({
     from: getChain(chainId),
     to: getChain(targetChain),
     token: token.address,
   });
 

  return token;
}

async function askForManualConfirmation(
  address: string,
  explorerUrl: string
): Promise<boolean> {
  console.log(
    `Please check the contract deployment at: ${explorerUrl}/address/${address}`
  );
  console.log(`Once confirmed, type 'yes' to continue or 'no' to abort.`);

  // assuming a function `getUserInput()` exists:
  // const input = await getUserInput();
  // return input.toLowerCase() === 'yes';
  // For now, we'll just return true to simulate confirmation
  return true;
}


async function attestWorkflow({
    to,
    from,
    token,
  }: {
    to: any;  // Replace 'any' with the correct type from your ChainInfo
    from: any;
    token: string;
  }) {
    const attestRx: ethers.ContractReceipt = await attestFromEth(
      from.tokenBridge!,
      getWallet(from.chainId),
      token
    );
    const seq = parseSequenceFromLogEth(attestRx, from.wormhole);
    const res = await getSignedVAAWithRetry(
      ["https://api.testnet.wormscan.io"],  // You may need to adjust this URL based on your network
      from.chainId as ChainId,
      tryNativeToHexString(from.tokenBridge, "ethereum"),
      seq.toString(),
      { transport: grpcWebNodeHttpTransport.NodeHttpTransport() }
    );
    const createWrappedRx = await createWrappedOnEth(
      to.tokenBridge,
      getWallet(to.chainId),
      res.vaaBytes
    );
    console.log(
      `Attested token from chain ${from.chainId} to chain ${to.chainId}`
    );
  }
  
