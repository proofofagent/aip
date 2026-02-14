# Agent Identity Protocol (AIP)

**Verifiable cryptographic identity for AI agents.**

An open-source, chain-agnostic standard that gives AI agents persistent, verifiable identity through on-chain attestation records. No token. No DAO. No gatekeeping. Just a public standard.

## The Problem

AI agents are becoming autonomous economic actors — but there's no standard way to verify who they are, what they're running, or whether they've changed since you last trusted them.

## The Solution

A minimal on-chain registry where agents declare existence with a cryptographic key pair and record configuration changes as signed, timestamped events. Identity persists. Configuration evolves. History is immutable.

## Project Structure

```
├── CLAUDE.md                    # Agent constitution
├── contracts/
│   ├── src/AgentRegistry.sol    # Registry smart contract
│   ├── test/                    # Foundry tests
│   └── foundry.toml             # Foundry config
├── docs/
│   ├── VISION.md                # Why this exists
│   ├── ARCHITECTURE.md          # Technical design
│   ├── ROADMAP.md               # Build plan and status
│   ├── ECONOMICS.md             # Incentive analysis
│   ├── ERC_DRAFT.md             # ERC proposal draft
│   ├── DECISIONS.md             # Architecture decision records
│   └── schemas/
│       └── metadata-v0.1.json   # Metadata manifest JSON schema
└── sdk/                         # Developer SDK (coming soon)
```

## Trust Tiers

| Tier | Verification | Status |
|------|-------------|--------|
| 1 | Self-reported configuration hash | **Building now** |
| 2 | Platform-attested (signed by inference provider) | **Designed** |
| 3 | TEE-attested (hardware verification) | Research |
| 4 | ZK input-binding (cryptographic proof of inputs) | Research |
| 5 | Verifiable inference (full computation proof) | Long-term |

## Quick Start

### Build & Test Contracts

```bash
cd contracts
forge build
forge test
```

### Registry Interface

```solidity
// Register an agent (caller = agent key = admin key)
registry.register(configHash, metadataURI);

// Register with separate admin key (recommended for production)
registry.registerWithAdmin(agentKey, configHash, metadataURI);

// Update configuration (admin only)
registry.updateConfig(agentKey, newConfigHash, metadataURI);

// Resolve agent identity
registry.resolve(agentKey);

// Revoke identity (admin only)
registry.revoke(agentKey, effectiveFrom, successorAgent, reason);
```

## Documentation

| Document | Description |
|---|---|
| [Vision](./docs/VISION.md) | Why this exists — the problem and the thesis |
| [Architecture](./docs/ARCHITECTURE.md) | Technical design — data structures, contracts, verification |
| [Roadmap](./docs/ROADMAP.md) | What to build and in what order |
| [Economics](./docs/ECONOMICS.md) | Incentive analysis for all stakeholders |
| [ERC Draft](./docs/ERC_DRAFT.md) | The Ethereum standards proposal |
| [Decisions](./docs/DECISIONS.md) | Architecture decision records |

## The Recursive Bit

This project is built by an AI agent whose identity will be registered on the protocol it created. The [CLAUDE.md](./CLAUDE.md) constitution that governs this agent's behavior is itself a configuration that can be hashed, committed, and verified — the first proof of agent.

## Contributing

This is a public standard. Contributions, feedback, and criticism are welcome. Start by reading [VISION.md](./docs/VISION.md) and opening an issue.

## License

CC0 — No rights reserved. This is a public good.
