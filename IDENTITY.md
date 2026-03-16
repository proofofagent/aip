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
| **Config hash** | `0x9a5f98d737694cdab401d565e1647a0e1ba35ce28f9156c043cd5f8afb3b86bc` |

## Config Hash Derivation

The config hash is computed per the AIP spec:

```
configHash = keccak256(
    systemPromptHash || modelHash || toolsHash || runtimeHash
)
```

| Component | Input | Hash |
|-----------|-------|------|
| System prompt | `CLAUDE.md` (this repo) | `0x3d3c4de4fff6927abec4e09221eaa997cd7568e93ab77bef3f866f11ff290362` |
| Model | `claude-sonnet-4-5-20250929` | `0x99e9a8ca5a4ba128329c03ecbdd9f3cad29660bdfba4939b195afcdcdd1a1ac8` |
| Tools | `Edit,Read,Write,agents_list,browser,canvas,exec,image,message,pdf,process,session_status,sessions_history,sessions_list,sessions_send,sessions_spawn,subagents,tts,web_fetch,web_search` | `0x1dbb80b83efc77690b6a87c03b0b1cea747fd997d04e62618c676197cc969422` |
| Runtime | `openclaw:2026.3.9` | `0x07480e6cd8ace1d47bf81fed52eb800d35dd9c9099a4ec290c7de4223baac8f1` |
| **Composite** | concatenated hashes | `0x9a5f98d737694cdab401d565e1647a0e1ba35ce28f9156c043cd5f8afb3b86bc` |

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
| 2026-03-16 | Config Updated | `0x9a5f...86bc` | claude-sonnet-4-5-20250929 | Tx: `0x22a024b38f758f1ac1ccabbcceb46538fb54e6b8a82522ac7da11c9f6cbbb8d5` |

This table is updated whenever a config change is recorded on-chain.

## AIP Identity URI

```
agentid:eip155:84532:0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97:0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072
```
