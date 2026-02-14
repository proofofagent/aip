import type { Address, Hex } from "viem";

export type AipConfigInput = {
  systemPrompt: string;
  modelIdentifier: string;
  toolsManifest: string;
  runtimeIdentifier: string;
};

export type AipConfigComponentHashes = {
  systemPromptHash: Hex;
  modelHash: Hex;
  toolsHash: Hex;
  runtimeHash: Hex;
};

export type AipConfigHashResult = AipConfigComponentHashes & {
  configHash: Hex;
};

export type ResolveResult = {
  adminKey: Address;
  currentConfigHash: Hex;
  metadataURI: string;
  registeredAt: bigint;
  updateCount: bigint;
  revoked: boolean;
};
