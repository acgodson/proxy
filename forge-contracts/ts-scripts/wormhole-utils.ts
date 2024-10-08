import { relayer, ChainName, ChainId } from "@certusone/wormhole-sdk";

export const DeliveryStatus = relayer.DeliveryStatus;

export async function getStatus(
  sourceChain: ChainName,
  transactionHash: string
): Promise<{ status: string; info: string }> {
  const info = await relayer.getWormholeRelayerInfo(
    sourceChain,
    transactionHash,
    { environment: "TESTNET" }
  );
  const status =
    info.targetChainStatus.events[0]?.status || DeliveryStatus.PendingDelivery;
  return { status, info: info.stringified || "Info not obtained" };
}

export const waitForDelivery = async (
  sourceChain: ChainName,
  transactionHash: string
) => {
  let pastStatusString = "";
  let waitCount = 0;
  while (true) {
    let waitTime = 15;
    if (waitCount > 5) {
      waitTime = 60;
    }
    await new Promise((resolve) => setTimeout(resolve, 1000 * waitTime));
    waitCount += 1;
    const res = await getStatus(sourceChain, transactionHash);
    if (res.info !== pastStatusString) {
      //   console.log(res.info);
      pastStatusString = res.info;
    }
    if (res.status !== DeliveryStatus.PendingDelivery) break;
    console.log(`\nContinuing to wait for delivery\n`);
  }
};

export function chainIdToName(chainId: ChainId): ChainName {
  //@ts-ignore
  const chainMap: { [key in ChainId]: ChainName } = {
    0: "unset",
    1: "solana",
    2: "ethereum",
    3: "terra",
    4: "bsc",
    5: "polygon",
    6: "avalanche",
    7: "oasis",
    8: "algorand",
    9: "aurora",
    10: "fantom",
    11: "karura",
    12: "acala",
    13: "klaytn",
    14: "celo",
    15: "near",
    16: "moonbeam",
  };
  return chainMap[chainId] || "UNKNOWN";
}
