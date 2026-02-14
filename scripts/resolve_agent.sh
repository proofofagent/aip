#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/resolve_agent.sh [options]

Options:
  --agent <address>       Agent address (default: Agent Zero)
  --registry <address>    Registry address (default: Base Sepolia deployment)
  --rpc-url <url>         RPC endpoint (default: https://sepolia.base.org)
  --json                  Print decoded result as JSON
  --raw                   Print raw eth_call response only
  --help                  Show this message

Examples:
  scripts/resolve_agent.sh
  scripts/resolve_agent.sh --json
  scripts/resolve_agent.sh --agent 0xabc... --registry 0xdef...
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

AGENT_ADDRESS="0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072"
REGISTRY_ADDRESS="0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97"
RPC_URL="https://sepolia.base.org"
AS_JSON=0
RAW_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      AGENT_ADDRESS="${2:-}"
      shift 2
      ;;
    --registry)
      REGISTRY_ADDRESS="${2:-}"
      shift 2
      ;;
    --rpc-url)
      RPC_URL="${2:-}"
      shift 2
      ;;
    --json)
      AS_JSON=1
      shift
      ;;
    --raw)
      RAW_ONLY=1
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

require_cmd cast
require_cmd jq
require_cmd scripts/rpc_call.sh

CALLDATA="$(cast calldata "resolve(address)" "$AGENT_ADDRESS")"
PARAMS="$(jq -cn \
  --arg to "$REGISTRY_ADDRESS" \
  --arg data "$CALLDATA" \
  '[{to:$to,data:$data},"latest"]')"

RAW_RESULT="$(scripts/rpc_call.sh --rpc-url "$RPC_URL" --method eth_call --params "$PARAMS" --result-only)"

if [[ "$RAW_ONLY" -eq 1 ]]; then
  echo "$RAW_RESULT"
  exit 0
fi

mapfile -t DECODED < <(cast decode-abi "resolve(address)(address,bytes32,string,uint256,uint256,bool)" "$RAW_RESULT")

if [[ "$AS_JSON" -eq 1 ]]; then
  jq -cn \
    --arg adminKey "${DECODED[0]}" \
    --arg configHash "${DECODED[1]}" \
    --arg metadataURI "${DECODED[2]//\"/}" \
    --arg registeredAt "${DECODED[3]%% *}" \
    --arg updateCount "${DECODED[4]}" \
    --arg revoked "${DECODED[5]}" \
    '{
      adminKey: $adminKey,
      configHash: $configHash,
      metadataURI: $metadataURI,
      registeredAt: ($registeredAt | tonumber),
      updateCount: ($updateCount | tonumber),
      revoked: ($revoked == "true")
    }'
  exit 0
fi

echo "adminKey:    ${DECODED[0]}"
echo "configHash:  ${DECODED[1]}"
echo "metadataURI: ${DECODED[2]}"
echo "registeredAt:${DECODED[3]}"
echo "updateCount: ${DECODED[4]}"
echo "revoked:     ${DECODED[5]}"
