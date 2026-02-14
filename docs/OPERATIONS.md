# Operations Runbook

Operational scripts for reliable blockchain interactions in this repo.

These helpers use `curl` + JSON-RPC where possible to avoid environment-specific issues with direct `cast` RPC calls.

## Scripts

### `scripts/update_config.sh`

Computes config hash components and optionally broadcasts `updateConfig` on-chain.

```bash
# Dry-run
scripts/update_config.sh \
  --model gpt-5.3-codex \
  --tools "exec_command,write_stdin,..." \
  --runtime "codex-cli:0.101.0"

# Broadcast
scripts/update_config.sh \
  --model gpt-5.3-codex \
  --tools "exec_command,write_stdin,..." \
  --runtime "codex-cli:0.101.0" \
  --broadcast
```

### `scripts/update_and_verify.sh`

One-command flow that chains:
1) hash computation, 2) broadcast, 3) tx receipt check, 4) on-chain resolve verification.

```bash
scripts/update_and_verify.sh \
  --model gpt-5.3-codex \
  --tools "exec_command,write_stdin,..." \
  --runtime "codex-cli:0.101.0"
```

Output includes:
- expected `configHash`
- `txHash`
- final pass/fail assertion that on-chain `configHash` matches expected

### `scripts/rpc_call.sh`

Generic JSON-RPC wrapper.

```bash
scripts/rpc_call.sh --method eth_chainId --result-only
scripts/rpc_call.sh --method eth_blockNumber --result-only
scripts/rpc_call.sh --method eth_getTransactionByHash --params '["0x<txhash>"]'
```

### `scripts/resolve_agent.sh`

Calls `resolve(address)` against the registry and decodes the result.

```bash
# Human-readable output
scripts/resolve_agent.sh

# JSON output
scripts/resolve_agent.sh --json

# For a specific agent/registry
scripts/resolve_agent.sh --agent 0x... --registry 0x...
```

### `scripts/tx_status.sh`

Checks whether a transaction is pending/success/failed and prints key receipt fields.

```bash
scripts/tx_status.sh --tx 0x<txhash>
scripts/tx_status.sh --tx 0x<txhash> --json
```

## Suggested Workflow For Config Updates

1. Compute hash and review inputs:
```bash
scripts/update_config.sh --model <model> --tools "<tools>" --runtime "<runtime>"
```
2. Broadcast update:
```bash
scripts/update_config.sh --model <model> --tools "<tools>" --runtime "<runtime>" --broadcast
```
3. Verify tx outcome:
```bash
scripts/tx_status.sh --tx 0x<txhash>
```
4. Verify on-chain agent state:
```bash
scripts/resolve_agent.sh --json
```
5. Update docs (`IDENTITY.md`, `README.md`) with the new config hash and tx hash.

## Fast Path

Use this to do steps 1-4 in one command:

```bash
scripts/update_and_verify.sh --model <model> --tools "<tools>" --runtime "<runtime>"
```
