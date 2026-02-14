#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/rpc_call.sh --method <jsonrpc-method> [options]

Options:
  --method <name>        Required. JSON-RPC method (example: eth_chainId)
  --params <json-array>  JSON array params (default: [])
  --rpc-url <url>        RPC endpoint (default: https://sepolia.base.org)
  --id <number>          Request id (default: 1)
  --result-only          Print only .result (raw JSON)
  --help                 Show this message

Examples:
  scripts/rpc_call.sh --method eth_chainId --result-only
  scripts/rpc_call.sh --method eth_blockNumber --result-only
  scripts/rpc_call.sh --method eth_getTransactionByHash \
    --params '["0x<txhash>"]'
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

METHOD=""
PARAMS_JSON="[]"
RPC_URL="https://sepolia.base.org"
REQ_ID="1"
RESULT_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --method)
      METHOD="${2:-}"
      shift 2
      ;;
    --params)
      PARAMS_JSON="${2:-}"
      shift 2
      ;;
    --rpc-url)
      RPC_URL="${2:-}"
      shift 2
      ;;
    --id)
      REQ_ID="${2:-}"
      shift 2
      ;;
    --result-only)
      RESULT_ONLY=1
      shift
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

if [[ -z "$METHOD" ]]; then
  echo "Error: --method is required." >&2
  usage
  exit 1
fi

require_cmd curl
require_cmd jq

if ! jq -e . >/dev/null 2>&1 <<<"$PARAMS_JSON"; then
  echo "Error: --params must be valid JSON." >&2
  exit 1
fi

REQUEST_JSON="$(jq -cn \
  --arg method "$METHOD" \
  --argjson params "$PARAMS_JSON" \
  --argjson id "$REQ_ID" \
  '{jsonrpc:"2.0",method:$method,params:$params,id:$id}')"

RESPONSE="$(curl -sS "$RPC_URL" \
  -H "content-type: application/json" \
  --data "$REQUEST_JSON")"

if [[ "$RESULT_ONLY" -eq 1 ]]; then
  jq -r '.result' <<<"$RESPONSE"
  exit 0
fi

jq <<<"$RESPONSE"
