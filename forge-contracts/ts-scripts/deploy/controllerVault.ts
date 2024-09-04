import { ControllerVault__factory } from "../ethers-contracts";
import {
  getWallet,
  loadDeployedAddresses,
  storeDeployedAddresses,
  getChain,
} from "../utils";

export async function deployControllerVault(chainId: number) {
  const chain = getChain(chainId);
  const signer = getWallet(chainId);

  const vault = await new ControllerVault__factory(signer).deploy(
    chain.wormholeRelayer,
    chain.tokenBridge,
    chain.wormhole
  );
  await vault.deployed();

  console.log(
    `ControllerVault deployed to ${vault.address} on chain ${chainId}`
  );

  const deployed = await loadDeployedAddresses();
  deployed.controllerVault[chainId] = vault.address;
  await storeDeployedAddresses(deployed);

  return vault;
}
