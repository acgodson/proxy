export { deployController } from "./controller";
export { deployControllerVault } from "./controllerVault";
export { deployCustomRouter } from "./customRouter";
export { deployERC20Mock } from "./erc20Mock";

import { loadConfig } from "../utils";
import { deployController } from "./controller";
import { deployControllerVault } from "./controllerVault";
import { deployCustomRouter } from "./customRouter";
import { deployERC20Mock } from "./erc20Mock";

export async function deployAll() {
  const config = loadConfig();
  const sourceChain = config.sourceChain;
  const targetChain = config.targetChain;

  // Deploy ERC20Mock on source chain
  const token = await deployERC20Mock(sourceChain);

  // Deploy Controller and ControllerVault on target chain
  const controller = await deployController(targetChain);
  const vault = await deployControllerVault(targetChain);

  // Deploy CustomRouter on source chain
  const router = await deployCustomRouter(sourceChain, token.address, targetChain);

  // Set up relationships
  await controller.setVault(vault.address);
  await vault.setController(controller.address);
  await router.setController(controller.address);
  await router.setControllerVault(vault.address);

  // Register the relayer as an authorized router
  await controller.registerRouter(config.chains[targetChain].wormholeRelayer);

  console.log("All contracts deployed and relationships set up.");
}