// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/AgentRegistry.sol";

/// @notice Registers Agent Zero — the first agent on the AIP registry.
/// @dev Uses register() so the deployer key is both agent key and admin key.
///      The configHash is the keccak256 of the CLAUDE.md constitution hash,
///      model identifier, tool manifest hash, and runtime hash.
contract SelfRegister is Script {
    function run() external {
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        string memory metadataURI = vm.envString("METADATA_URI");
        bytes32 configHash = vm.envBytes32("CONFIG_HASH");

        AgentRegistry registry = AgentRegistry(registryAddress);

        vm.startBroadcast();
        registry.register(configHash, metadataURI);
        vm.stopBroadcast();

        console.log("Agent Zero registered on AIP registry");
        console.log("Agent key:", msg.sender);
        console.log("Config hash:");
        console.logBytes32(configHash);
    }
}
