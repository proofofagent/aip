import { parseAbi } from "viem";

export const agentRegistryAbi = parseAbi([
  "function register(bytes32 configHash, string metadataURI)",
  "function registerWithAdmin(address agentKey, bytes32 configHash, string metadataURI)",
  "function updateConfig(address agentKey, bytes32 newConfigHash, string metadataURI)",
  "function revoke(address agentKey, uint256 effectiveFrom, address successorAgent, string reason)",
  "function resolve(address agentKey) view returns (address adminKey, bytes32 currentConfigHash, string metadataURI, uint256 registeredAt, uint256 updateCount, bool revoked)"
]);
