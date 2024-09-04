import { ethers } from "ethers";
import { readFileSync, writeFileSync } from "fs";
import config, { Config, ChainInfo } from "./config";
import {
  Controller__factory,
  ControllerVault__factory,
  CustomRouter__factory,
  ERC20Mock__factory,
} from "./ethers-contracts";
import "dotenv/config";

export interface DeployedAddresses {
  controller: Record<number, string>;
  controllerVault: Record<number, string>;
  customRouter: Record<number, string>;
  erc20s: Record<number, string[]>;
}

export function loadConfig(): Config {
  return config;
}

export function getChain(chainId: number): ChainInfo {
  const chain = config.chains[chainId];
  if (!chain) {
    throw new Error(`Chain ${chainId} not found`);
  }
  return chain;
}

export function getWallet(chainId: number): ethers.Wallet {
  const rpc = getChain(chainId).rpc;
  const provider = new ethers.providers.JsonRpcProvider(rpc);
  if (!process.env.PRIVATE_KEY) {
    throw Error(
      "No private key provided (use the PRIVATE_KEY environment variable)"
    );
  }
  return new ethers.Wallet(process.env.PRIVATE_KEY, provider);
}

export async function loadDeployedAddresses(): Promise<DeployedAddresses> {
  try {
    const data = readFileSync("./ts-scripts/testnet/deployed-addresses.json", {
      encoding: "utf-8",
    });
    return JSON.parse(data);
  } catch (error) {
    return {
      controller: {},
      controllerVault: {},
      customRouter: {},
      erc20s: {},
    };
  }
}

export async function storeDeployedAddresses(
  deployed: DeployedAddresses
): Promise<DeployedAddresses> {
  writeFileSync(
    "./ts-scripts/testnet/deployed-addresses.json",
    JSON.stringify(deployed, null, 2)
  );
  return deployed;
}

export async function getController(chainId: number) {
  const deployed = (await loadDeployedAddresses()).controller[chainId];
  if (!deployed) {
    throw new Error(`No deployed controller on chain ${chainId}`);
  }
  return Controller__factory.connect(deployed, getWallet(chainId));
}

export async function getControllerVault(chainId: number) {
  const deployed = (await loadDeployedAddresses()).controllerVault[chainId];
  if (!deployed) {
    throw new Error(`No deployed controller vault on chain ${chainId}`);
  }
  return ControllerVault__factory.connect(deployed, getWallet(chainId));
}

export async function getCustomRouter(chainId: number) {
  const deployed = (await loadDeployedAddresses()).customRouter[chainId];
  if (!deployed) {
    throw new Error(`No deployed custom router on chain ${chainId}`);
  }
  return CustomRouter__factory.connect(deployed, getWallet(chainId));
}

export async function getERC20Mock(chainId: number, index: number = 0) {
  const deployed = (await loadDeployedAddresses()).erc20s[chainId];
  if (!deployed || !deployed[index]) {
    throw new Error(
      `No deployed ERC20 mock (index ${index}) on chain ${chainId}`
    );
  }
  return ERC20Mock__factory.connect(deployed[index], getWallet(chainId));
}

export const wait = (tx: ethers.ContractTransaction) => tx.wait();

export function checkFlag(flag: string): boolean {
  return process.argv.includes(flag);
}

export function getArg(flag: string): string | undefined {
  const index = process.argv.indexOf(flag);
  return index !== -1 ? process.argv[index + 1] : undefined;
}
