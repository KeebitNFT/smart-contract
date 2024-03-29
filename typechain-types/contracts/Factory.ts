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
  PromiseOrValue,
} from "../common";

export declare namespace Factory {
  export type FactoryNFTStruct = {
    nftContract: PromiseOrValue<string>;
    collectionName: PromiseOrValue<string>;
    uri: PromiseOrValue<string>;
    tokenId: PromiseOrValue<BigNumberish>;
    vendor: PromiseOrValue<string>;
  };

  export type FactoryNFTStructOutput = [
    string,
    string,
    string,
    BigNumber,
    string
  ] & {
    nftContract: string;
    collectionName: string;
    uri: string;
    tokenId: BigNumber;
    vendor: string;
  };
}

export interface FactoryInterface extends utils.Interface {
  functions: {
    "countMyNFTs()": FunctionFragment;
    "createNFT(string,string,uint256[])": FunctionFragment;
    "getMyNFTs()": FunctionFragment;
    "isToken(address)": FunctionFragment;
    "isVendor(address)": FunctionFragment;
    "owner()": FunctionFragment;
    "renounceOwnership()": FunctionFragment;
    "saveVendor(address)": FunctionFragment;
    "tokens(uint256)": FunctionFragment;
    "transferOwnership(address)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "countMyNFTs"
      | "createNFT"
      | "getMyNFTs"
      | "isToken"
      | "isVendor"
      | "owner"
      | "renounceOwnership"
      | "saveVendor"
      | "tokens"
      | "transferOwnership"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "countMyNFTs",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "createNFT",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>[]
    ]
  ): string;
  encodeFunctionData(functionFragment: "getMyNFTs", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "isToken",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "isVendor",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "renounceOwnership",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "saveVendor",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "tokens",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "transferOwnership",
    values: [PromiseOrValue<string>]
  ): string;

  decodeFunctionResult(
    functionFragment: "countMyNFTs",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "createNFT", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getMyNFTs", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "isToken", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "isVendor", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "renounceOwnership",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "saveVendor", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "tokens", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "transferOwnership",
    data: BytesLike
  ): Result;

  events: {
    "OwnershipTransferred(address,address)": EventFragment;
    "TokenDeployed(address,address)": EventFragment;
    "TokenMinted(address,address,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "OwnershipTransferred"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "TokenDeployed"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "TokenMinted"): EventFragment;
}

export interface OwnershipTransferredEventObject {
  previousOwner: string;
  newOwner: string;
}
export type OwnershipTransferredEvent = TypedEvent<
  [string, string],
  OwnershipTransferredEventObject
>;

export type OwnershipTransferredEventFilter =
  TypedEventFilter<OwnershipTransferredEvent>;

export interface TokenDeployedEventObject {
  owner: string;
  tokenContract: string;
}
export type TokenDeployedEvent = TypedEvent<
  [string, string],
  TokenDeployedEventObject
>;

export type TokenDeployedEventFilter = TypedEventFilter<TokenDeployedEvent>;

export interface TokenMintedEventObject {
  owner: string;
  tokenContract: string;
  amount: BigNumber;
}
export type TokenMintedEvent = TypedEvent<
  [string, string, BigNumber],
  TokenMintedEventObject
>;

export type TokenMintedEventFilter = TypedEventFilter<TokenMintedEvent>;

export interface Factory extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: FactoryInterface;

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
    countMyNFTs(overrides?: CallOverrides): Promise<[BigNumber]>;

    createNFT(
      _collectionName: PromiseOrValue<string>,
      _uri: PromiseOrValue<string>,
      _ids: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    getMyNFTs(
      overrides?: CallOverrides
    ): Promise<[Factory.FactoryNFTStructOutput[]]>;

    isToken(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    isVendor(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    owner(overrides?: CallOverrides): Promise<[string]>;

    renounceOwnership(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    saveVendor(
      _vendor: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    tokens(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  countMyNFTs(overrides?: CallOverrides): Promise<BigNumber>;

  createNFT(
    _collectionName: PromiseOrValue<string>,
    _uri: PromiseOrValue<string>,
    _ids: PromiseOrValue<BigNumberish>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  getMyNFTs(
    overrides?: CallOverrides
  ): Promise<Factory.FactoryNFTStructOutput[]>;

  isToken(
    arg0: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  isVendor(
    arg0: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  owner(overrides?: CallOverrides): Promise<string>;

  renounceOwnership(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  saveVendor(
    _vendor: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  tokens(
    arg0: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  transferOwnership(
    newOwner: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    countMyNFTs(overrides?: CallOverrides): Promise<BigNumber>;

    createNFT(
      _collectionName: PromiseOrValue<string>,
      _uri: PromiseOrValue<string>,
      _ids: PromiseOrValue<BigNumberish>[],
      overrides?: CallOverrides
    ): Promise<string>;

    getMyNFTs(
      overrides?: CallOverrides
    ): Promise<Factory.FactoryNFTStructOutput[]>;

    isToken(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    isVendor(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    owner(overrides?: CallOverrides): Promise<string>;

    renounceOwnership(overrides?: CallOverrides): Promise<void>;

    saveVendor(
      _vendor: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    tokens(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "OwnershipTransferred(address,address)"(
      previousOwner?: PromiseOrValue<string> | null,
      newOwner?: PromiseOrValue<string> | null
    ): OwnershipTransferredEventFilter;
    OwnershipTransferred(
      previousOwner?: PromiseOrValue<string> | null,
      newOwner?: PromiseOrValue<string> | null
    ): OwnershipTransferredEventFilter;

    "TokenDeployed(address,address)"(
      owner?: PromiseOrValue<string> | null,
      tokenContract?: PromiseOrValue<string> | null
    ): TokenDeployedEventFilter;
    TokenDeployed(
      owner?: PromiseOrValue<string> | null,
      tokenContract?: PromiseOrValue<string> | null
    ): TokenDeployedEventFilter;

    "TokenMinted(address,address,uint256)"(
      owner?: PromiseOrValue<string> | null,
      tokenContract?: PromiseOrValue<string> | null,
      amount?: null
    ): TokenMintedEventFilter;
    TokenMinted(
      owner?: PromiseOrValue<string> | null,
      tokenContract?: PromiseOrValue<string> | null,
      amount?: null
    ): TokenMintedEventFilter;
  };

  estimateGas: {
    countMyNFTs(overrides?: CallOverrides): Promise<BigNumber>;

    createNFT(
      _collectionName: PromiseOrValue<string>,
      _uri: PromiseOrValue<string>,
      _ids: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    getMyNFTs(overrides?: CallOverrides): Promise<BigNumber>;

    isToken(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    isVendor(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<BigNumber>;

    renounceOwnership(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    saveVendor(
      _vendor: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    tokens(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    countMyNFTs(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    createNFT(
      _collectionName: PromiseOrValue<string>,
      _uri: PromiseOrValue<string>,
      _ids: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    getMyNFTs(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    isToken(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    isVendor(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    renounceOwnership(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    saveVendor(
      _vendor: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    tokens(
      arg0: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    transferOwnership(
      newOwner: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
