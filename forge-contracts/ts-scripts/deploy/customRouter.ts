import { ethers } from "ethers";
import { CustomRouter__factory } from "../ethers-contracts";
import {
  getWallet,
  loadDeployedAddresses,
  storeDeployedAddresses,
  getChain,
} from "../utils";

export async function deployCustomRouter(
  chainId: number,
  tokenAddress: string,
  targetChainId: number
) {
  const chain = getChain(chainId);
  const signer = getWallet(chainId);

  const router = await new CustomRouter__factory(signer).deploy(
    chain.wormholeRelayer,
    chain.tokenBridge,
    chain.wormhole,
    ethers.constants.AddressZero, // Controller address (will be set later)
    ethers.constants.AddressZero, // ControllerVault address (will be set later)
    tokenAddress,
    targetChainId
  );
  await router.deployed();

  console.log(`CustomRouter deployed to ${router.address} on chain ${chainId}`);

  const deployed = await loadDeployedAddresses();
  deployed.customRouter[chainId] = router.address;
  await storeDeployedAddresses(deployed);

  return router;
}
