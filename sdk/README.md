# AIP TypeScript SDK

Core SDK for Agent Identity Protocol (AIP) workflows.

## Scope (Phase 1 Core)

- Configuration hashing (`systemPrompt`, `model`, `tools`, `runtime`)
- Transaction builders for registry actions
- Registry read/write client for:
  - `register`
  - `registerWithAdmin`
  - `updateConfig`
  - `resolve`
  - `revoke`

Note: current config hash composition follows the repository's existing on-chain convention:
`keccak256(strip0x(h1) || strip0x(h2) || strip0x(h3) || strip0x(h4))` over UTF-8 text.

## Install

```bash
cd sdk
npm install
```

## Usage

```ts
import {
  AgentRegistryClient,
  computeConfigHashes,
  createAipClients
} from "@aip/sdk";

const { publicClient, walletClient } = createAipClients({
  rpcUrl: "https://sepolia.base.org",
  privateKey: "0x..."
});

const registry = new AgentRegistryClient({
  registryAddress: "0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97",
  publicClient,
  walletClient
});

const config = computeConfigHashes({
  systemPrompt: "...",
  modelIdentifier: "gpt-5.3-codex",
  toolsManifest: "exec_command,write_stdin,...",
  runtimeIdentifier: "codex-cli:0.101.0"
});

const txHash = await registry.updateConfig({
  agentKey: "0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072",
  newConfigHash: config.configHash,
  metadataURI: "ipfs://..."
});

const state = await registry.resolve("0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072");
console.log(txHash, state.currentConfigHash);
```
