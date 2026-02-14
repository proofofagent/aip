// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/AgentRegistry.sol";

contract DeployRegistry is Script {
    function run() external {
        vm.startBroadcast();
        AgentRegistry registry = new AgentRegistry();
        vm.stopBroadcast();

        console.log("AgentRegistry deployed at:", address(registry));
    }
}
