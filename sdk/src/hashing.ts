import { concatHex, isHex, keccak256, stringToHex, type Hex } from "viem";
import type {
  AipConfigComponentHashes,
  AipConfigHashResult,
  AipConfigInput
} from "./types.js";

function assertBytes32(value: Hex, fieldName: string): void {
  if (!isHex(value, { strict: true }) || value.length !== 66) {
    throw new Error(`${fieldName} must be a 32-byte hex value (bytes32)`);
  }
}

export function hashUtf8(value: string): Hex {
  return keccak256(stringToHex(value));
}

export function computeConfigHashes(input: AipConfigInput): AipConfigHashResult {
  const systemPromptHash = hashUtf8(input.systemPrompt);
  const modelHash = hashUtf8(input.modelIdentifier);
  const toolsHash = hashUtf8(input.toolsManifest);
  const runtimeHash = hashUtf8(input.runtimeIdentifier);

  const configHash = computeConfigHashFromComponents({
    systemPromptHash,
    modelHash,
    toolsHash,
    runtimeHash
  });

  return {
    systemPromptHash,
    modelHash,
    toolsHash,
    runtimeHash,
    configHash
  };
}

export function computeConfigHashFromComponents(hashes: AipConfigComponentHashes): Hex {
  assertBytes32(hashes.systemPromptHash, "systemPromptHash");
  assertBytes32(hashes.modelHash, "modelHash");
  assertBytes32(hashes.toolsHash, "toolsHash");
  assertBytes32(hashes.runtimeHash, "runtimeHash");

  // Compatibility with current on-chain records:
  // hash( strip0x(h1) || strip0x(h2) || strip0x(h3) || strip0x(h4) ) as UTF-8 text.
  // This mirrors the repository's existing registration/update scripts.
  const concatenated = concatHex([
    hashes.systemPromptHash,
    hashes.modelHash,
    hashes.toolsHash,
    hashes.runtimeHash
  ]).slice(2);

  return keccak256(stringToHex(concatenated));
}
