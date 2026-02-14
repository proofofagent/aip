#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/update_config.sh --model <model-id> --tools <tool-manifest> --runtime <runtime-id> [options]

Options:
  --model <id>                Required. Model identifier (example: gpt-5)
  --tools <manifest>          Required. Comma-separated tool manifest string
  --runtime <id>              Required. Runtime identifier (example: codex-cli:0.101.0)
  --metadata-uri <uri>        Metadata URI for updateConfig (default: ipfs://placeholder-aip-agent-zero-v0.1)
  --registry <address>        Registry address (default: Base Sepolia deployment)
  --agent <address>           Agent address (default: Agent Zero)
  --rpc-url <url>             RPC URL (default: https://sepolia.base.org)
  --wallet-file <path>        Wallet JSON containing private_key (default: ~/.aip-agent/wallet.json)
  --prompt-file <path>        System prompt file to hash (default: CLAUDE.md)
  --broadcast                 Submit transaction on-chain (default: dry-run)
  --help                      Show this message

Examples:
  scripts/update_config.sh \
    --model gpt-5 \
    --tools "exec_command,write_stdin,apply_patch,update_plan" \
    --runtime "codex-cli:0.101.0"

  scripts/update_config.sh \
    --model gpt-5 \
    --tools "exec_command,write_stdin,apply_patch,update_plan" \
    --runtime "codex-cli:0.101.0" \
    --broadcast
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
METADATA_URI="ipfs://placeholder-aip-agent-zero-v0.1"
REGISTRY_ADDRESS="0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97"
AGENT_ADDRESS="0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072"
RPC_URL="https://sepolia.base.org"
WALLET_FILE="${HOME}/.aip-agent/wallet.json"
PROMPT_FILE="CLAUDE.md"
BROADCAST=0

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
    --broadcast)
      BROADCAST=1
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

if [[ -z "$MODEL_ID" || -z "$TOOLS_MANIFEST" || -z "$RUNTIME_ID" ]]; then
  echo "Error: --model, --tools, and --runtime are required." >&2
  usage
  exit 1
fi

require_cmd cast
require_cmd jq
require_cmd forge

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

if [[ ! -f "$WALLET_FILE" ]]; then
  echo "Wallet file not found: $WALLET_FILE" >&2
  exit 1
fi

PRIVATE_KEY="$(jq -r '.private_key // empty' "$WALLET_FILE")"
if [[ -z "$PRIVATE_KEY" ]]; then
  echo "Could not read .private_key from wallet file: $WALLET_FILE" >&2
  exit 1
fi

SYSTEM_PROMPT_HASH="$(cast keccak "$(cat "$PROMPT_FILE")")"
MODEL_HASH="$(cast keccak "$MODEL_ID")"
TOOLS_HASH="$(cast keccak "$TOOLS_MANIFEST")"
RUNTIME_HASH="$(cast keccak "$RUNTIME_ID")"

COMBINED_HEX="$(printf "%s%s%s%s" "$SYSTEM_PROMPT_HASH" "$MODEL_HASH" "$TOOLS_HASH" "$RUNTIME_HASH" | sed 's/0x//g')"
NEW_CONFIG_HASH="$(cast keccak "$COMBINED_HEX")"

cat <<EOF
Computed config components:
  systemPromptHash: $SYSTEM_PROMPT_HASH
  modelHash:        $MODEL_HASH
  toolsHash:        $TOOLS_HASH
  runtimeHash:      $RUNTIME_HASH
  configHash:       $NEW_CONFIG_HASH

Call parameters:
  registry:         $REGISTRY_ADDRESS
  agent:            $AGENT_ADDRESS
  metadataURI:      $METADATA_URI
  rpcUrl:           $RPC_URL
  promptFile:       $PROMPT_FILE
EOF

if [[ "$BROADCAST" -eq 0 ]]; then
  cat <<EOF

Dry-run only. No transaction sent.
To broadcast:
  scripts/update_config.sh --model "$MODEL_ID" --tools "$TOOLS_MANIFEST" --runtime "$RUNTIME_ID" --broadcast
EOF
  exit 0
fi

(
  cd contracts
  REGISTRY_ADDRESS="$REGISTRY_ADDRESS" \
  AGENT_KEY="$AGENT_ADDRESS" \
  METADATA_URI="$METADATA_URI" \
  NEW_CONFIG_HASH="$NEW_CONFIG_HASH" \
  forge script script/UpdateConfig.s.sol:UpdateConfig \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --private-key "$PRIVATE_KEY"
)

echo
echo "Broadcast complete. Update IDENTITY.md with the new configuration history entry."
