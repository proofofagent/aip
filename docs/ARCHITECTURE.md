# Architecture — Agent Identity Protocol (AIP)

## Overview

The Agent Identity Protocol defines a minimal standard for AI agents to establish verifiable, persistent, cryptographic identity through on-chain attestation records.

## Core Concepts

### Agent Identity

An agent's identity is a **key pair**. The public key is the globally unique identifier. The private key proves ownership and authorizes updates. Identity persists across configuration changes — the key pair is the continuous thread, everything else is mutable.

### Identity Chain

Each agent has an append-only sequence of records anchored on-chain. Nothing is ever deleted. The full history is always available. This sequence is the agent's **identity chain** and contains:

- **Genesis record** — the initial "I exist" declaration
- **Configuration records** — hashed snapshots of the agent's model, prompt, tools, and runtime
- **Metadata updates** — pointers to off-chain detailed manifests

### Configuration Hashing

An agent's configuration is defined by its constituent parts, each hashed independently and then combined:

```
config_hash = keccak256(
  system_prompt_hash,    // hash of the full system prompt / AGENTS.md
  model_identifier,      // e.g., "claude-sonnet-4-20250514"
  tool_manifest_hash,    // hash of the ordered list of available tools
  runtime_metadata_hash  // hash of framework, version, and runtime info
)
```

Individual component hashes are stored in the off-chain metadata manifest. The composite `config_hash` is what goes on-chain, keeping gas costs minimal.

### Separation of Identity and Configuration

This separation is fundamental:

- **Identity** (key pair) = "who is this agent" → persistent, immutable
- **Configuration** (hashed snapshot) = "what is this agent right now" → mutable, versioned
- **History** (the chain of records) = "what has this agent been" → append-only, auditable

An agent can change its model, rewrite its prompt, swap its tools — and it's still the "same agent" with a continuous identity. But every change is a visible event. Observers can decide whether a configuration change affects their trust.

## On-Chain Data Structures

### Genesis Record

```solidity
struct GenesisRecord {
    address agentPubKey;       // Agent's public key (also serves as unique ID)
    address adminKey;          // Key authorized to manage this identity
    bytes32 configHash;        // Initial configuration hash
    string metadataURI;        // IPFS/Arweave URI to full metadata manifest
    uint256 timestamp;         // Block timestamp of registration
}
```

### Configuration Update Record

```solidity
struct ConfigUpdate {
    bytes32 previousConfigHash;  // Links to the prior configuration
    bytes32 newConfigHash;       // New configuration hash
    string metadataURI;          // Updated metadata manifest URI
    uint256 timestamp;           // Block timestamp
}
```

### Revocation Record

```solidity
struct Revocation {
    uint256 effectiveFrom;     // Timestamp from which identity is compromised
    address successorAgent;    // Optional: new agent identity that continues this one
    string reason;             // Human-readable reason for revocation
}
```

## Registry Contract

The registry is intentionally minimal — a mapping from agent public keys to their identity chains.

### Core Functions

- `register(configHash, metadataURI)` — Create a genesis record. Caller's address becomes both `agentPubKey` and `adminKey` by default.
- `registerWithAdmin(agentPubKey, configHash, metadataURI)` — Create a genesis record with a separate admin key. Allows the agent operational key and admin key to be different (recommended).
- `updateConfig(newConfigHash, metadataURI)` — Append a configuration update. Must be called by admin key.
- `resolve(agentPubKey)` — Return the current configuration hash and full history.
- `revoke(effectiveFrom, successorAgent, reason)` — Mark identity as compromised. Must be called by admin key.

### Design Constraints

- **No deletions.** Records are append-only.
- **No protocol fees.** Only native gas costs.
- **No governance.** The contract is immutable once deployed.
- **No upgradability.** If the standard evolves, deploy a new version. Old identities can link to new ones via the successor mechanism.

## Cross-Chain Identity

### URI Scheme

Agent identities are globally addressable using CAIP-2 chain identification:

```
agentid:<chain-namespace>:<chain-id>:<contract-address>:<agent-public-key>
```

Examples:
```
agentid:eip155:1:0xABC...123:0xDEF...456          # Ethereum mainnet
agentid:eip155:42161:0xABC...123:0xDEF...456       # Arbitrum One
agentid:eip155:8453:0xABC...123:0xDEF...456        # Base
```

The protocol does NOT require bridging or cross-chain messaging. Each chain has its own independent registry deployment. The URI scheme simply tells verifiers where to look.

### Chain Selection Guidance

The protocol doesn't mandate a chain. Agents (or their creators) choose based on their needs:
- **Low-cost L2s** (Arbitrum, Base, Optimism) for agents with frequent configuration updates
- **Ethereum mainnet** for maximum permanence and credibility
- **Other EVM chains** wherever the agent's ecosystem operates

## Off-Chain Metadata Manifest

The `metadataURI` in each on-chain record points to a content-addressed file (IPFS, Arweave) containing the full metadata. This keeps on-chain costs low while providing rich detail.

### Manifest Schema (JSON)

```json
{
  "aip_version": "0.1.0",
  "agent": {
    "name": "My Trading Agent",
    "description": "Executes trades based on predefined strategies",
    "creator": "0xCreatorAddress",
    "created_at": "2025-02-13T00:00:00Z"
  },
  "configuration": {
    "system_prompt_hash": "0xabc...",
    "model": {
      "provider": "anthropic",
      "identifier": "claude-sonnet-4-20250514",
      "version": "20250514"
    },
    "tools": {
      "manifest_hash": "0xdef...",
      "tool_count": 5,
      "tool_names": ["web_search", "execute_trade", "get_portfolio", "analyze_chart", "send_notification"]
    },
    "runtime": {
      "framework": "langchain",
      "version": "0.2.0",
      "runtime_hash": "0xghi..."
    }
  },
  "attestation": {
    "tier": 1,
    "platform_signature": null,
    "tee_report": null,
    "zk_proof": null
  },
  "previous_config_hash": null
}
```

## Trust Tiers

The protocol defines increasing levels of configuration verification:

| Tier | Name | Verification | Available |
|------|------|-------------|-----------|
| 1 | Self-reported | Operator publishes config hash. No external verification. | Now |
| 2 | Platform-attested | Inference platform signs the inputs, confirming config hash matches what was actually used. | Near-term |
| 3 | TEE-attested | Runtime executes in a Trusted Execution Environment with hardware attestation. | Medium-term |
| 4 | ZK input-binding | Zero-knowledge proof that declared inputs (system prompt tokens) match committed hash. | Research phase |
| 5 | Verifiable inference | Full ZK proof of the entire inference computation. | Long-term research |

The `attestation.tier` field in the metadata manifest declares the current verification level. Services set minimum tier requirements for interaction.

## Phase 2: Platform Attestation

When an inference platform (Anthropic, OpenAI, etc.) participates:

1. Platform has a known public key (published and verifiable)
2. At inference time, platform hashes the system prompt and input, signs the hash with its key
3. Signature is included in the metadata manifest under `attestation.platform_signature`
4. Any verifier can check: "Anthropic confirms that at timestamp T, agent X was running with config hash Y"

This doesn't require the platform to publish their signing key on-chain — just that the key is publicly known and discoverable (e.g., published on their website, in a DNS TXT record, or in a well-known registry).

### Platform Incentives

See `ECONOMICS.md` for detailed analysis. Key incentives:
- **Liability protection** — proof of what the platform received and returned
- **Competitive differentiation** — agents on attesting platforms get higher trust tiers
- **Developer demand** — agent builders prefer platforms that enable trust

## Future Extensions (Not in Scope for Phase 1-2)

These are documented for forward-compatibility but are NOT part of the initial implementation:

- **Permission grants** — cryptographically signed, scoped delegations from users to agents
- **Decision logging** — signed records of agent actions anchored to the identity chain
- **Reputation scoring** — derived metrics from identity chain history and behavior
- **Agent-to-agent trust negotiation** — mutual verification protocols
- **Linked identities** — successor chains for key rotation or migration
- **Dispute resolution** — on-chain evidence submission and arbitration hooks
