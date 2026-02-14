#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/update_and_verify.sh --model <model-id> --tools <tool-manifest> --runtime <runtime-id> [options]

Options:
  --model <id>                Required. Model identifier (example: gpt-5.3-codex)
  --tools <manifest>          Required. Comma-separated tool manifest string
  --runtime <id>              Required. Runtime identifier (example: codex-cli:0.101.0)
  --metadata-uri <uri>        Metadata URI for updateConfig
  --registry <address>        Registry address
  --agent <address>           Agent address
  --rpc-url <url>             RPC URL
  --wallet-file <path>        Wallet JSON file
  --prompt-file <path>        Prompt file to hash
  --max-wait-seconds <n>      Max seconds to wait for tx receipt (default: 180)
  --help                      Show this message

Example:
  scripts/update_and_verify.sh \
    --model gpt-5.3-codex \
    --tools "exec_command,write_stdin,..." \
    --runtime "codex-cli:0.101.0"
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

MODEL_ID=""
TOOLS_MANIFEST=""
RUNTIME_ID=""
METADATA_URI=""
REGISTRY_ADDRESS=""
AGENT_ADDRESS=""
RPC_URL=""
WALLET_FILE=""
PROMPT_FILE=""
MAX_WAIT_SECONDS=180

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      MODEL_ID="${2:-}"
      shift 2
      ;;
    --tools)
      TOOLS_MANIFEST="${2:-}"
      shift 2
      ;;
    --runtime)
      RUNTIME_ID="${2:-}"
      shift 2
      ;;
    --metadata-uri)
      METADATA_URI="${2:-}"
      shift 2
      ;;
    --registry)
      REGISTRY_ADDRESS="${2:-}"
      shift 2
      ;;
    --agent)
      AGENT_ADDRESS="${2:-}"
      shift 2
      ;;
    --rpc-url)
      RPC_URL="${2:-}"
      shift 2
      ;;
    --wallet-file)
      WALLET_FILE="${2:-}"
      shift 2
      ;;
    --prompt-file)
      PROMPT_FILE="${2:-}"
      shift 2
      ;;
    --max-wait-seconds)
      MAX_WAIT_SECONDS="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$MODEL_ID" || -z "$TOOLS_MANIFEST" || -z "$RUNTIME_ID" ]]; then
  echo "Error: --model, --tools, and --runtime are required." >&2
  usage
  exit 1
fi

require_cmd jq
require_cmd awk
require_cmd sed
require_cmd scripts/update_config.sh
require_cmd scripts/tx_status.sh
require_cmd scripts/resolve_agent.sh

COMMON_ARGS=(--model "$MODEL_ID" --tools "$TOOLS_MANIFEST" --runtime "$RUNTIME_ID")
if [[ -n "$METADATA_URI" ]]; then COMMON_ARGS+=(--metadata-uri "$METADATA_URI"); fi
if [[ -n "$REGISTRY_ADDRESS" ]]; then COMMON_ARGS+=(--registry "$REGISTRY_ADDRESS"); fi
if [[ -n "$AGENT_ADDRESS" ]]; then COMMON_ARGS+=(--agent "$AGENT_ADDRESS"); fi
if [[ -n "$RPC_URL" ]]; then COMMON_ARGS+=(--rpc-url "$RPC_URL"); fi
if [[ -n "$WALLET_FILE" ]]; then COMMON_ARGS+=(--wallet-file "$WALLET_FILE"); fi
if [[ -n "$PROMPT_FILE" ]]; then COMMON_ARGS+=(--prompt-file "$PROMPT_FILE"); fi

echo "== 1) Compute expected config hash =="
DRY_OUTPUT="$(scripts/update_config.sh "${COMMON_ARGS[@]}")"
echo "$DRY_OUTPUT"
EXPECTED_CONFIG_HASH="$(awk '/configHash:/ {print $2}' <<<"$DRY_OUTPUT" | tail -n1)"

if [[ -z "$EXPECTED_CONFIG_HASH" ]]; then
  echo "Failed to parse expected config hash from dry-run output." >&2
  exit 1
fi

echo
echo "== 2) Broadcast updateConfig transaction =="
scripts/update_config.sh "${COMMON_ARGS[@]}" --broadcast

BROADCAST_FILE="contracts/broadcast/UpdateConfig.s.sol/84532/run-latest.json"
if [[ ! -f "$BROADCAST_FILE" ]]; then
  echo "Broadcast output not found: $BROADCAST_FILE" >&2
  exit 1
fi

TX_HASH="$(jq -r '.transactions[0].hash // .receipts[0].transactionHash // empty' "$BROADCAST_FILE")"
if [[ -z "$TX_HASH" ]]; then
  echo "Failed to extract tx hash from $BROADCAST_FILE" >&2
  exit 1
fi

echo "txHash: $TX_HASH"

echo
echo "== 3) Wait for tx receipt =="
START_TS="$(date +%s)"
while true; do
  TX_JSON="$(scripts/tx_status.sh --tx "$TX_HASH" --json)"
  STATE="$(jq -r '.state' <<<"$TX_JSON")"
  echo "$TX_JSON"

  if [[ "$STATE" == "success" ]]; then
    break
  fi
  if [[ "$STATE" == "failed" ]]; then
    echo "Transaction failed." >&2
    exit 1
  fi

  NOW_TS="$(date +%s)"
  if (( NOW_TS - START_TS > MAX_WAIT_SECONDS )); then
    echo "Timed out waiting for receipt (${MAX_WAIT_SECONDS}s)." >&2
    exit 1
  fi
  sleep 5
done

echo
echo "== 4) Resolve agent and verify config hash =="
RESOLVE_JSON="$(scripts/resolve_agent.sh --json)"
echo "$RESOLVE_JSON"
ONCHAIN_CONFIG_HASH="$(jq -r '.configHash' <<<"$RESOLVE_JSON")"

if [[ "$ONCHAIN_CONFIG_HASH" != "$EXPECTED_CONFIG_HASH" ]]; then
  echo "Mismatch: expected $EXPECTED_CONFIG_HASH, on-chain $ONCHAIN_CONFIG_HASH" >&2
  exit 1
fi

echo
echo "== Complete =="
echo "Expected config hash matches on-chain config hash."
echo "configHash: $EXPECTED_CONFIG_HASH"
echo "txHash:      $TX_HASH"
