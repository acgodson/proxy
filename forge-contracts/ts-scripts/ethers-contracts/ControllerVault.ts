/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PayableOverrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
} from "./common";

export interface ControllerVaultInterface extends utils.Interface {
  functions: {
    "controller()": FunctionFragment;
    "receiveWormholeMessages(bytes,bytes[],bytes32,uint16,bytes32)": FunctionFragment;
    "routerDeposits(address,address)": FunctionFragment;
    "setController(address)": FunctionFragment;
    "setRegisteredSender(uint16,bytes32)": FunctionFragment;
    "tokenBridge()": FunctionFragment;
    "wormhole()": FunctionFragment;
    "wormholeRelayer()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "controller"
      | "receiveWormholeMessages"
      | "routerDeposits"
      | "setController"
      | "setRegisteredSender"
      | "tokenBridge"
      | "wormhole"
      | "wormholeRelayer"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "controller",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "receiveWormholeMessages",
    values: [BytesLike, BytesLike[], BytesLike, BigNumberish, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "routerDeposits",
    values: [string, string]
  ): string;
  encodeFunctionData(
    functionFragment: "setController",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "setRegisteredSender",
    values: [BigNumberish, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "tokenBridge",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "wormhole", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "wormholeRelayer",
    values?: undefined
  ): string;

  decodeFunctionResult(functionFragment: "controller", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "receiveWormholeMessages",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "routerDeposits",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setController",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setRegisteredSender",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "tokenBridge",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "wormhole", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "wormholeRelayer",
    data: BytesLike
  ): Result;

  events: {
    "TokensWithdrawn(address,address,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "TokensWithdrawn"): EventFragment;
}

export interface TokensWithdrawnEventObject {
  router: string;
  token: string;
  amount: BigNumber;
}
export type TokensWithdrawnEvent = TypedEvent<
  [string, string, BigNumber],
  TokensWithdrawnEventObject
>;

export type TokensWithdrawnEventFilter = TypedEventFilter<TokensWithdrawnEvent>;

export interface ControllerVault extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: ControllerVaultInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    controller(overrides?: CallOverrides): Promise<[string]>;

    receiveWormholeMessages(
      payload: BytesLike,
      additionalVaas: BytesLike[],
      sourceAddress: BytesLike,
      sourceChain: BigNumberish,
      deliveryHash: BytesLike,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<ContractTransaction>;

    routerDeposits(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    setController(
      _controller: string,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    setRegisteredSender(
      sourceChain: BigNumberish,
      sourceAddress: BytesLike,
      overrides?: Overrides & { from?: string }
    ): Promise<ContractTransaction>;

    tokenBridge(overrides?: CallOverrides): Promise<[string]>;

    wormhole(overrides?: CallOverrides): Promise<[string]>;

    wormholeRelayer(overrides?: CallOverrides): Promise<[string]>;
  };

  controller(overrides?: CallOverrides): Promise<string>;

  receiveWormholeMessages(
    payload: BytesLike,
    additionalVaas: BytesLike[],
    sourceAddress: BytesLike,
    sourceChain: BigNumberish,
    deliveryHash: BytesLike,
    overrides?: PayableOverrides & { from?: string }
  ): Promise<ContractTransaction>;

  routerDeposits(
    arg0: string,
    arg1: string,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  setController(
    _controller: string,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  setRegisteredSender(
    sourceChain: BigNumberish,
    sourceAddress: BytesLike,
    overrides?: Overrides & { from?: string }
  ): Promise<ContractTransaction>;

  tokenBridge(overrides?: CallOverrides): Promise<string>;

  wormhole(overrides?: CallOverrides): Promise<string>;

  wormholeRelayer(overrides?: CallOverrides): Promise<string>;

  callStatic: {
    controller(overrides?: CallOverrides): Promise<string>;

    receiveWormholeMessages(
      payload: BytesLike,
      additionalVaas: BytesLike[],
      sourceAddress: BytesLike,
      sourceChain: BigNumberish,
      deliveryHash: BytesLike,
      overrides?: CallOverrides
    ): Promise<void>;

    routerDeposits(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    setController(
      _controller: string,
      overrides?: CallOverrides
    ): Promise<void>;

    setRegisteredSender(
      sourceChain: BigNumberish,
      sourceAddress: BytesLike,
      overrides?: CallOverrides
    ): Promise<void>;

    tokenBridge(overrides?: CallOverrides): Promise<string>;

    wormhole(overrides?: CallOverrides): Promise<string>;

    wormholeRelayer(overrides?: CallOverrides): Promise<string>;
  };

  filters: {
    "TokensWithdrawn(address,address,uint256)"(
      router?: string | null,
      token?: string | null,
      amount?: null
    ): TokensWithdrawnEventFilter;
    TokensWithdrawn(
      router?: string | null,
      token?: string | null,
      amount?: null
    ): TokensWithdrawnEventFilter;
  };

  estimateGas: {
    controller(overrides?: CallOverrides): Promise<BigNumber>;

    receiveWormholeMessages(
      payload: BytesLike,
      additionalVaas: BytesLike[],
      sourceAddress: BytesLike,
      sourceChain: BigNumberish,
      deliveryHash: BytesLike,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<BigNumber>;

    routerDeposits(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    setController(
      _controller: string,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    setRegisteredSender(
      sourceChain: BigNumberish,
      sourceAddress: BytesLike,
      overrides?: Overrides & { from?: string }
    ): Promise<BigNumber>;

    tokenBridge(overrides?: CallOverrides): Promise<BigNumber>;

    wormhole(overrides?: CallOverrides): Promise<BigNumber>;

    wormholeRelayer(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    controller(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    receiveWormholeMessages(
      payload: BytesLike,
      additionalVaas: BytesLike[],
      sourceAddress: BytesLike,
      sourceChain: BigNumberish,
      deliveryHash: BytesLike,
      overrides?: PayableOverrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    routerDeposits(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    setController(
      _controller: string,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    setRegisteredSender(
      sourceChain: BigNumberish,
      sourceAddress: BytesLike,
      overrides?: Overrides & { from?: string }
    ): Promise<PopulatedTransaction>;

    tokenBridge(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    wormhole(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    wormholeRelayer(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
