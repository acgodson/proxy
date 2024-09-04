import { Controller__factory } from "../ethers-contracts";
import {
  getWallet,
  loadDeployedAddresses,
  storeDeployedAddresses,
  getChain,
} from "../utils";

export async function deployController(chainId: number) {
  const chain = getChain(chainId);
  const signer = getWallet(chainId);

  const controller = await new Controller__factory(signer).deploy(
    chain.wormholeRelayer
  );

  await controller.deployed();

  console.log(
    `Controller deployed to ${controller.address} on chain ${chainId}`
  );

  const deployed = await loadDeployedAddresses();
  deployed.controller[chainId] = controller.address;
  await storeDeployedAddresses(deployed);

  return controller;
}
