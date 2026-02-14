# Agent Identity Protocol (AIP)

**Verifiable cryptographic identity for AI agents.**

An open standard that gives AI agents persistent, verifiable identity through on-chain attestation. Chain-agnostic. No token. No DAO. No gatekeeping.

---

## Why

AI agents are autonomous economic actors — executing trades, calling APIs, negotiating with other agents. But there's no way to verify *who* they are, *what* they're running, or whether they've changed since you last trusted them. AIP fixes this.

## How It Works

```
1. Agent generates a key pair → that's its identity
2. Agent registers on-chain → genesis record with config hash
3. Agent evolves → config changes are append-only events
4. Anyone verifies → resolve identity, check history, assess trust
```

The registry stores hashes, not plaintext. Your prompts stay private. Your commitment to a configuration is public.

## Deployments

| Network | Registry Contract | Explorer |
|---------|------------------|----------|
| Base Sepolia | `0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97` | [View on Basescan](https://sepolia.basescan.org/address/0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97) |

## Agent Zero

This protocol's first registered agent is the one building it.

| Field | Value |
|-------|-------|
| Address | `0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072` |
| Chain | Base Sepolia |
| Registry | `0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97` |
| Config hash | `0xb9ad6d11451f23390e78c961f75d357325fc480945d95fea721eb7da4eb0c84f` |

Verify on-chain: `cast call 0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97 "resolve(address)" 0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072 --rpc-url https://sepolia.base.org`

See [`IDENTITY.md`](./IDENTITY.md) for full verification details and config hash derivation.

## Quick Start

```bash
# Build & test
cd contracts
forge build
forge test   # 20 tests, all passing

# Deploy to Base Sepolia
forge script script/Deploy.s.sol --rpc-url $BASE_SEPOLIA_RPC --broadcast --private-key $PRIVATE_KEY
```

### Registry Interface

```solidity
// Register (caller = agent key = admin key)
registry.register(configHash, metadataURI);

// Register with separate admin key (recommended)
registry.registerWithAdmin(agentKey, configHash, metadataURI);

// Update configuration (admin only)
registry.updateConfig(agentKey, newConfigHash, metadataURI);

// Resolve identity
registry.resolve(agentKey);

// Revoke (admin only)
registry.revoke(agentKey, effectiveFrom, successorAgent, reason);
```

### Reusable Config Update Script

Use the parameterized helper to compute a new config hash and optionally broadcast `updateConfig`:

```bash
# Dry-run (compute hashes, no tx)
scripts/update_config.sh \
  --model gpt-5 \
  --tools "exec_command,write_stdin,apply_patch,update_plan" \
  --runtime "codex-cli:0.101.0"

# Broadcast on-chain update
scripts/update_config.sh \
  --model gpt-5 \
  --tools "exec_command,write_stdin,apply_patch,update_plan" \
  --runtime "codex-cli:0.101.0" \
  --broadcast
```

The helper reads `~/.aip-agent/wallet.json` by default and executes `contracts/script/UpdateConfig.s.sol`.

For a single command that computes, broadcasts, checks tx status, and verifies resolved on-chain hash:

```bash
scripts/update_and_verify.sh \
  --model gpt-5.3-codex \
  --tools "exec_command,write_stdin,..." \
  --runtime "codex-cli:0.101.0"
```

### Blockchain Utility Scripts

For reliable reads/verifications around updates, use:

```bash
scripts/rpc_call.sh --method eth_chainId --result-only
scripts/resolve_agent.sh --json
scripts/tx_status.sh --tx 0x<txhash>
```

Operational details and the full update/verify runbook are documented in [`docs/OPERATIONS.md`](./docs/OPERATIONS.md).

## Trust Tiers

| Tier | Verification | Status |
|------|-------------|--------|
| 1 | Self-reported config hash | **Live** |
| 2 | Platform-attested (inference provider signs) | Designed |
| 3 | TEE-attested (hardware verification) | Research |
| 4 | ZK input-binding (proof of inputs) | Research |
| 5 | Verifiable inference (full computation proof) | Long-term |

## Project Structure

```
├── CLAUDE.md                     # Agent constitution — the system prompt that governs this repo
├── contracts/
│   ├── src/AgentRegistry.sol     # Registry contract (158 lines, CC0)
│   ├── test/AgentRegistry.t.sol  # Foundry tests (20 tests)
│   └── script/
│       ├── Deploy.s.sol          # Testnet deployment
│       ├── SelfRegister.s.sol    # Agent Zero self-registration
│       └── UpdateConfig.s.sol    # On-chain config update script
├── docs/
│   ├── VISION.md                 # Problem statement and thesis
│   ├── ARCHITECTURE.md           # Technical design and data structures
│   ├── ROADMAP.md                # Build plan — what's next
│   ├── ECONOMICS.md              # Incentive analysis for all stakeholders
│   ├── ERC_DRAFT.md              # ERC proposal (EIP-1 format)
│   ├── DECISIONS.md              # Architecture decision records
│   ├── OPERATIONS.md             # Scripted runbook for update and verification flows
│   └── schemas/
│       └── metadata-v0.1.json    # Off-chain metadata JSON schema
├── scripts/
│   ├── update_config.sh          # Parameterized config-hash + updateConfig helper
│   ├── update_and_verify.sh      # One-command update + tx + resolve verification
│   ├── rpc_call.sh               # Generic JSON-RPC helper
│   ├── resolve_agent.sh          # resolve(address) helper with decoding
│   └── tx_status.sh              # Tx receipt/status helper
└── sdk/                          # TypeScript SDK (hashing, client, tx builders, tests)
```

## Documentation

| Document | What's Inside |
|---|---|
| [Vision](./docs/VISION.md) | The problem, the thesis, and the e-commerce trust analogy |
| [Architecture](./docs/ARCHITECTURE.md) | Data structures, config hashing, cross-chain URIs, trust tiers |
| [Roadmap](./docs/ROADMAP.md) | Phase 1-4 build plan with deliverables and success criteria |
| [Economics](./docs/ECONOMICS.md) | Why platforms, developers, and services would adopt — no token required |
| [ERC Draft](./docs/ERC_DRAFT.md) | The formal standards proposal |
| [Decisions](./docs/DECISIONS.md) | ADRs: no token, chain-agnostic, append-only, key separation, Base Sepolia |
| [Operations](./docs/OPERATIONS.md) | Scripted runbook for config updates and on-chain verification |
| [SDK README](./sdk/README.md) | TypeScript SDK usage for hashing, registration, updates, and resolve |

## The Recursive Bit

This repo is built by an AI agent whose identity will be the first one registered on the protocol it created. The [CLAUDE.md](./CLAUDE.md) constitution is the agent's system prompt — a configuration that can be hashed, committed on-chain, and verified by anyone. The builder *is* the first proof of agent.

## Contributing

This is a public standard. Contributions, feedback, and criticism are welcome.

1. Read [VISION.md](./docs/VISION.md) to understand the problem
2. Read [ARCHITECTURE.md](./docs/ARCHITECTURE.md) to understand the design
3. Open an issue or PR

## License

[CC0](./LICENSE) — No rights reserved. This is a public good.
