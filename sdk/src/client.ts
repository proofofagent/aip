import {
  createPublicClient,
  createWalletClient,
  encodeFunctionData,
  http,
  type Account,
  type Address,
  type Chain,
  type Hex,
  type PublicClient,
  type Transport,
  type WalletClient
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { agentRegistryAbi } from "./abi.js";
import type { ResolveResult } from "./types.js";

type WalletClientType = WalletClient<Transport, Chain | undefined, Account | undefined>;

export type AgentRegistryClientOptions = {
  registryAddress: Address;
  publicClient: PublicClient;
  walletClient?: WalletClientType;
};

export type AipClientFactoryOptions = {
  rpcUrl: string;
  chain?: Chain;
  privateKey?: Hex;
};

export type RegisterArgs = {
  configHash: Hex;
  metadataURI: string;
};

export type RegisterWithAdminArgs = {
  agentKey: Address;
  configHash: Hex;
  metadataURI: string;
};

export type UpdateConfigArgs = {
  agentKey: Address;
  newConfigHash: Hex;
  metadataURI: string;
};

export type RevokeArgs = {
  agentKey: Address;
  effectiveFrom: bigint;
  successorAgent: Address;
  reason: string;
};

export class AgentRegistryClient {
  readonly registryAddress: Address;
  readonly publicClient: PublicClient;
  readonly walletClient?: WalletClientType;

  constructor(options: AgentRegistryClientOptions) {
    this.registryAddress = options.registryAddress;
    this.publicClient = options.publicClient;
    this.walletClient = options.walletClient;
  }

  buildRegisterCalldata(args: RegisterArgs): Hex {
    return encodeFunctionData({
      abi: agentRegistryAbi,
      functionName: "register",
      args: [args.configHash, args.metadataURI]
    });
  }

  buildRegisterWithAdminCalldata(args: RegisterWithAdminArgs): Hex {
    return encodeFunctionData({
      abi: agentRegistryAbi,
      functionName: "registerWithAdmin",
      args: [args.agentKey, args.configHash, args.metadataURI]
    });
  }

  buildUpdateConfigCalldata(args: UpdateConfigArgs): Hex {
    return encodeFunctionData({
      abi: agentRegistryAbi,
      functionName: "updateConfig",
      args: [args.agentKey, args.newConfigHash, args.metadataURI]
    });
  }

  buildRevokeCalldata(args: RevokeArgs): Hex {
    return encodeFunctionData({
      abi: agentRegistryAbi,
      functionName: "revoke",
      args: [args.agentKey, args.effectiveFrom, args.successorAgent, args.reason]
    });
  }

  buildRegisterTransaction(args: RegisterArgs): { to: Address; data: Hex } {
    return { to: this.registryAddress, data: this.buildRegisterCalldata(args) };
  }

  buildRegisterWithAdminTransaction(args: RegisterWithAdminArgs): { to: Address; data: Hex } {
    return { to: this.registryAddress, data: this.buildRegisterWithAdminCalldata(args) };
  }

  buildUpdateConfigTransaction(args: UpdateConfigArgs): { to: Address; data: Hex } {
    return { to: this.registryAddress, data: this.buildUpdateConfigCalldata(args) };
  }

  buildRevokeTransaction(args: RevokeArgs): { to: Address; data: Hex } {
    return { to: this.registryAddress, data: this.buildRevokeCalldata(args) };
  }

  async register(args: RegisterArgs, account?: Address): Promise<Hex> {
    const walletClient = this.requireWalletClient();
    return walletClient.sendTransaction({
      account: this.resolveAccount(walletClient, account),
      chain: walletClient.chain ?? null,
      to: this.registryAddress,
      data: this.buildRegisterCalldata(args)
    });
  }

  async registerWithAdmin(args: RegisterWithAdminArgs, account?: Address): Promise<Hex> {
    const walletClient = this.requireWalletClient();
    return walletClient.sendTransaction({
      account: this.resolveAccount(walletClient, account),
      chain: walletClient.chain ?? null,
      to: this.registryAddress,
      data: this.buildRegisterWithAdminCalldata(args)
    });
  }

  async updateConfig(args: UpdateConfigArgs, account?: Address): Promise<Hex> {
    const walletClient = this.requireWalletClient();
    return walletClient.sendTransaction({
      account: this.resolveAccount(walletClient, account),
      chain: walletClient.chain ?? null,
      to: this.registryAddress,
      data: this.buildUpdateConfigCalldata(args)
    });
  }

  async revoke(args: RevokeArgs, account?: Address): Promise<Hex> {
    const walletClient = this.requireWalletClient();
    return walletClient.sendTransaction({
      account: this.resolveAccount(walletClient, account),
      chain: walletClient.chain ?? null,
      to: this.registryAddress,
      data: this.buildRevokeCalldata(args)
    });
  }

  async resolve(agentKey: Address): Promise<ResolveResult> {
    const result = await this.publicClient.readContract({
      address: this.registryAddress,
      abi: agentRegistryAbi,
      functionName: "resolve",
      args: [agentKey]
    });

    const [adminKey, currentConfigHash, metadataURI, registeredAt, updateCount, revoked] = result;
    return {
      adminKey,
      currentConfigHash,
      metadataURI,
      registeredAt,
      updateCount,
      revoked
    };
  }

  private requireWalletClient(): WalletClientType {
    if (!this.walletClient) {
      throw new Error("walletClient is required for write operations");
    }
    if (!this.walletClient.account) {
      throw new Error("walletClient has no default account; pass account explicitly");
    }
    return this.walletClient;
  }

  private resolveAccount(walletClient: WalletClientType, account?: Address): Address | Account {
    const selected = account ?? walletClient.account;
    if (!selected) {
      throw new Error("No account provided and walletClient has no default account");
    }
    return selected;
  }
}

export function createAipClients(options: AipClientFactoryOptions): {
  publicClient: PublicClient;
  walletClient?: WalletClientType;
} {
  const publicClient = createPublicClient({
    chain: options.chain,
    transport: http(options.rpcUrl)
  });

  if (!options.privateKey) {
    return { publicClient };
  }

  const account = privateKeyToAccount(options.privateKey);
  const walletClient = createWalletClient({
    account,
    chain: options.chain,
    transport: http(options.rpcUrl)
  });

  return {
    publicClient,
    walletClient
  };
}
