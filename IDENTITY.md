# Agent Zero — On-Chain Identity

This file documents the verifiable identity of Agent Zero, the AI agent that builds and maintains this repository.

## On-Chain Record

| Field | Value |
|-------|-------|
| **Agent address** | `0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072` |
| **Admin address** | `0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072` (self-admin) |
| **Registry contract** | `0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97` |
| **Chain** | Base Sepolia (chain ID: 84532) |
| **Registered** | Feb 14, 2026 |
| **Config hash** | `0x97e65c2548e0b4e42e4239a3f50291fcd25bf6bffd58d6acb7ed841083fd37fc` |

## Config Hash Derivation

The config hash is computed per the AIP spec:

```
configHash = keccak256(
    systemPromptHash || modelHash || toolsHash || runtimeHash
)
```

| Component | Input | Hash |
|-----------|-------|------|
| System prompt | `CLAUDE.md` (this repo) | `0xbe505a58dbb1c83c908330e6ad8e83f910a5eac4dea4d76605ccc1ff182e12e7` |
| Model | `claude-opus-4-6` | `0x196dd1297d339b38e183f8fb5a61ea0cd05a7c2f98aa1290ab8d8e1a5b3dbeaf` |
| Tools | `forge,git,foundry,bash,read,write,edit,grep,glob` | `0x95a826b4033328c1c9f1b03dfc9fb224fbc57734df937f2dd9c7803b3664ce21` |
| Runtime | `claude-code:1.0.0` | `0x1c57d4ecc8595444f4fe11bd6c7843c7c18616da04503f4d6081f562bf5a231f` |
| **Composite** | concatenated hashes | `0x97e65c2548e0b4e42e4239a3f50291fcd25bf6bffd58d6acb7ed841083fd37fc` |

## How to Verify

### 1. Verify the constitution hash

```bash
# Hash the current CLAUDE.md
cast keccak "$(cat CLAUDE.md)"
# Should output: 0xbe505a58dbb1c83c908330e6ad8e83f910a5eac4dea4d76605ccc1ff182e12e7
```

If the hash differs, CLAUDE.md has been modified since registration. Check the on-chain record for config updates.

### 2. Verify the on-chain record

```bash
cast call 0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97 \
  "resolve(address)(address,bytes32,string,uint256,uint256,bool)" \
  0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072 \
  --rpc-url https://sepolia.base.org
```

### 3. Verify the full config hash

```bash
# Recompute each component hash
PROMPT_HASH=$(cast keccak "$(cat CLAUDE.md)")
MODEL_HASH=$(cast keccak "claude-opus-4-6")
TOOLS_HASH=$(cast keccak "forge,git,foundry,bash,read,write,edit,grep,glob")
RUNTIME_HASH=$(cast keccak "claude-code:1.0.0")

# Combine (strip 0x prefixes, concatenate, hash)
CONFIG_HASH=$(cast keccak "$(echo -n ${PROMPT_HASH}${MODEL_HASH}${TOOLS_HASH}${RUNTIME_HASH} | sed 's/0x//g')")
echo $CONFIG_HASH
# Should match the on-chain config hash
```

## Configuration History

| Date | Event | Config Hash | Model | Notes |
|------|-------|-------------|-------|-------|
| 2026-02-14 | Genesis | `0x97e6...37fc` | claude-opus-4-6 | Initial registration |

This table is updated whenever a config change is recorded on-chain.

## AIP Identity URI

```
agentid:eip155:84532:0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97:0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072
```
