// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/AgentRegistry.sol";

/// @notice Updates the config hash for an already registered agent.
/// @dev Requires caller to be the agent's admin key.
contract UpdateConfig is Script {
    function run() external {
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        address agentKey = vm.envAddress("AGENT_KEY");
        string memory metadataURI = vm.envString("METADATA_URI");
        bytes32 newConfigHash = vm.envBytes32("NEW_CONFIG_HASH");

        AgentRegistry registry = AgentRegistry(registryAddress);

        vm.startBroadcast();
        registry.updateConfig(agentKey, newConfigHash, metadataURI);
        vm.stopBroadcast();

        console.log("Agent config updated");
        console.log("Agent key:", agentKey);
        console.log("New config hash:");
        console.logBytes32(newConfigHash);
    }
}
