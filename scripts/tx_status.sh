#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/tx_status.sh --tx <hash> [options]

Options:
  --tx <hash>          Required. Transaction hash
  --rpc-url <url>      RPC endpoint (default: https://sepolia.base.org)
  --explorer <base>    Explorer tx base URL (default: Base Sepolia)
  --json               Print combined output as JSON
  --help               Show this message

Examples:
  scripts/tx_status.sh --tx 0x...
  scripts/tx_status.sh --tx 0x... --json
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

TX_HASH=""
RPC_URL="https://sepolia.base.org"
EXPLORER_BASE="https://sepolia.basescan.org/tx"
AS_JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tx)
      TX_HASH="${2:-}"
      shift 2
      ;;
    --rpc-url)
      RPC_URL="${2:-}"
      shift 2
      ;;
    --explorer)
      EXPLORER_BASE="${2:-}"
      shift 2
      ;;
    --json)
      AS_JSON=1
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

if [[ -z "$TX_HASH" ]]; then
  echo "Error: --tx is required." >&2
  usage
  exit 1
fi

require_cmd jq
require_cmd scripts/rpc_call.sh

RECEIPT="$(scripts/rpc_call.sh --rpc-url "$RPC_URL" --method eth_getTransactionReceipt --params "[\"$TX_HASH\"]" --result-only)"
TX_OBJ="$(scripts/rpc_call.sh --rpc-url "$RPC_URL" --method eth_getTransactionByHash --params "[\"$TX_HASH\"]" --result-only)"

if [[ "$RECEIPT" == "null" ]]; then
  if [[ "$AS_JSON" -eq 1 ]]; then
    jq -cn \
      --arg txHash "$TX_HASH" \
      --arg explorerUrl "${EXPLORER_BASE}/${TX_HASH}" \
      '{txHash:$txHash, state:"pending", explorerUrl:$explorerUrl}'
    exit 0
  fi

  echo "state: pending"
  echo "txHash: $TX_HASH"
  echo "explorer: ${EXPLORER_BASE}/${TX_HASH}"
  exit 0
fi

STATUS_HEX="$(jq -r '.status' <<<"$RECEIPT")"
STATUS_LABEL="failed"
if [[ "$STATUS_HEX" == "0x1" ]]; then
  STATUS_LABEL="success"
fi

if [[ "$AS_JSON" -eq 1 ]]; then
  jq -cn \
    --arg txHash "$TX_HASH" \
    --arg state "$STATUS_LABEL" \
    --arg statusHex "$STATUS_HEX" \
    --arg blockNumber "$(jq -r '.blockNumber' <<<"$RECEIPT")" \
    --arg gasUsed "$(jq -r '.gasUsed' <<<"$RECEIPT")" \
    --arg from "$(jq -r '.from' <<<"$TX_OBJ")" \
    --arg to "$(jq -r '.to' <<<"$TX_OBJ")" \
    --arg nonce "$(jq -r '.nonce' <<<"$TX_OBJ")" \
    --arg explorerUrl "${EXPLORER_BASE}/${TX_HASH}" \
    '{
      txHash:$txHash,
      state:$state,
      statusHex:$statusHex,
      blockNumber:$blockNumber,
      gasUsed:$gasUsed,
      from:$from,
      to:$to,
      nonce:$nonce,
      explorerUrl:$explorerUrl
    }'
  exit 0
fi

echo "state:       $STATUS_LABEL"
echo "txHash:      $TX_HASH"
echo "statusHex:   $STATUS_HEX"
echo "blockNumber: $(jq -r '.blockNumber' <<<"$RECEIPT")"
echo "gasUsed:     $(jq -r '.gasUsed' <<<"$RECEIPT")"
echo "from:        $(jq -r '.from' <<<"$TX_OBJ")"
echo "to:          $(jq -r '.to' <<<"$TX_OBJ")"
echo "nonce:       $(jq -r '.nonce' <<<"$TX_OBJ")"
echo "explorer:    ${EXPLORER_BASE}/${TX_HASH}"
