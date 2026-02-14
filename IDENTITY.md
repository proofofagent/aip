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
| **Config hash** | `0xb9ad6d11451f23390e78c961f75d357325fc480945d95fea721eb7da4eb0c84f` |

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
| Model | `gpt-5.3-codex` | `0x94ee34552bbdf6d781e5603c0b4737a2429421e67e180f02fd58c73c012c304c` |
| Tools | `exec_command,write_stdin,list_mcp_resources,list_mcp_resource_templates,read_mcp_resource,apply_patch,update_plan,view_image,multi_tool_use.parallel,web.search_query,web.open,web.click,web.find,web.screenshot,web.image_query,web.sports,web.finance,web.weather,web.time` | `0x2abadedc4530197e67253698a3be086cda391546a87465af3fd238310154e2dd` |
| Runtime | `codex-cli:0.101.0` | `0xeb935f2db1713823a7e5c986822a1350b5a6f76f35cfd3e488f60fc479b1cc6f` |
| **Composite** | concatenated hashes | `0xb9ad6d11451f23390e78c961f75d357325fc480945d95fea721eb7da4eb0c84f` |

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
MODEL_HASH=$(cast keccak "gpt-5.3-codex")
TOOLS_HASH=$(cast keccak "exec_command,write_stdin,list_mcp_resources,list_mcp_resource_templates,read_mcp_resource,apply_patch,update_plan,view_image,multi_tool_use.parallel,web.search_query,web.open,web.click,web.find,web.screenshot,web.image_query,web.sports,web.finance,web.weather,web.time")
RUNTIME_HASH=$(cast keccak "codex-cli:0.101.0")

# Combine (strip 0x prefixes, concatenate, hash)
CONFIG_HASH=$(cast keccak "$(echo -n ${PROMPT_HASH}${MODEL_HASH}${TOOLS_HASH}${RUNTIME_HASH} | sed 's/0x//g')")
echo $CONFIG_HASH
# Should match the on-chain config hash
```

## Configuration History

| Date | Event | Config Hash | Model | Notes |
|------|-------|-------------|-------|-------|
| 2026-02-14 | Genesis | `0x97e6...37fc` | claude-opus-4-6 | Initial registration |
| 2026-02-14 | Config Updated | `0xb9ad...c84f` | gpt-5.3-codex | Tx: `0x1ea6c7c13a4681aa2a8c681164a8d38f2cd00d5d6fbff24bfe0b1117c2b74c6a` |

This table is updated whenever a config change is recorded on-chain.

## AIP Identity URI

```
agentid:eip155:84532:0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97:0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072
```
