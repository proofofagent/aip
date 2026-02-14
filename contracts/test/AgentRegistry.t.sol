// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AgentRegistry.sol";

contract AgentRegistryTest is Test {
    AgentRegistry public registry;

    address public admin = address(0xA);
    address public agentKey = address(0xB);
    address public stranger = address(0xC);
    address public successor = address(0xD);

    bytes32 public configHash = keccak256("config-v1");
    bytes32 public configHash2 = keccak256("config-v2");
    string public metadataURI = "ipfs://QmInitial";
    string public metadataURI2 = "ipfs://QmUpdated";

    function setUp() public {
        registry = new AgentRegistry();
    }

    // =========== Registration ===========

    function test_register() public {
        vm.prank(agentKey);
        registry.register(configHash, metadataURI);

        (address adminKey, bytes32 hash, string memory uri, uint256 regAt, uint256 updates, bool revoked) =
            registry.resolve(agentKey);

        assertEq(adminKey, agentKey);
        assertEq(hash, configHash);
        assertEq(uri, metadataURI);
        assertGt(regAt, 0);
        assertEq(updates, 0);
        assertFalse(revoked);
    }

    function test_register_emits_event() public {
        vm.prank(agentKey);
        vm.expectEmit(true, true, false, true);
        emit IAgentRegistry.AgentRegistered(agentKey, agentKey, configHash, metadataURI, block.timestamp);
        registry.register(configHash, metadataURI);
    }

    function test_registerWithAdmin() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        (address adminKey,,,,, ) = registry.resolve(agentKey);
        assertEq(adminKey, admin);
    }

    function test_register_revert_duplicate() public {
        vm.prank(agentKey);
        registry.register(configHash, metadataURI);

        vm.prank(agentKey);
        vm.expectRevert("AIP: already registered");
        registry.register(configHash, metadataURI);
    }

    function test_register_revert_zero_configHash() public {
        vm.prank(agentKey);
        vm.expectRevert("AIP: zero config hash");
        registry.register(bytes32(0), metadataURI);
    }

    function test_register_revert_empty_metadataURI() public {
        vm.prank(agentKey);
        vm.expectRevert("AIP: empty metadata URI");
        registry.register(configHash, "");
    }

    function test_registerWithAdmin_revert_zero_agentKey() public {
        vm.prank(admin);
        vm.expectRevert("AIP: zero agent key");
        registry.registerWithAdmin(address(0), configHash, metadataURI);
    }

    // =========== Config Update ===========

    function test_updateConfig() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        vm.prank(admin);
        registry.updateConfig(agentKey, configHash2, metadataURI2);

        (, bytes32 hash, string memory uri,, uint256 updates,) = registry.resolve(agentKey);
        assertEq(hash, configHash2);
        assertEq(uri, metadataURI2);
        assertEq(updates, 1);
    }

    function test_updateConfig_emits_event() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit IAgentRegistry.ConfigUpdated(agentKey, configHash, configHash2, metadataURI2, block.timestamp);
        registry.updateConfig(agentKey, configHash2, metadataURI2);
    }

    function test_updateConfig_revert_not_admin() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        vm.prank(stranger);
        vm.expectRevert("AIP: not admin");
        registry.updateConfig(agentKey, configHash2, metadataURI2);
    }

    function test_updateConfig_revert_not_registered() public {
        vm.prank(admin);
        vm.expectRevert("AIP: agent not registered");
        registry.updateConfig(agentKey, configHash2, metadataURI2);
    }

    function test_updateConfig_revert_zero_hash() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        vm.prank(admin);
        vm.expectRevert("AIP: zero config hash");
        registry.updateConfig(agentKey, bytes32(0), metadataURI2);
    }

    function test_updateConfig_revert_revoked() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        vm.prank(admin);
        registry.revoke(agentKey, block.timestamp, address(0), "compromised");

        vm.prank(admin);
        vm.expectRevert("AIP: agent revoked");
        registry.updateConfig(agentKey, configHash2, metadataURI2);
    }

    // =========== Revocation ===========

    function test_revoke() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        vm.prank(admin);
        registry.revoke(agentKey, block.timestamp, successor, "key compromised");

        (,,,,, bool revoked) = registry.resolve(agentKey);
        assertTrue(revoked);
    }

    function test_revoke_emits_event() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit IAgentRegistry.AgentRevoked(agentKey, block.timestamp, successor, "key compromised");
        registry.revoke(agentKey, block.timestamp, successor, "key compromised");
    }

    function test_revoke_revert_not_admin() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        vm.prank(stranger);
        vm.expectRevert("AIP: not admin");
        registry.revoke(agentKey, block.timestamp, address(0), "reason");
    }

    function test_revoke_revert_future_effectiveFrom() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        vm.prank(admin);
        vm.expectRevert("AIP: effectiveFrom in future");
        registry.revoke(agentKey, block.timestamp + 1, address(0), "reason");
    }

    function test_revoke_revert_already_revoked() public {
        vm.prank(admin);
        registry.registerWithAdmin(agentKey, configHash, metadataURI);

        vm.prank(admin);
        registry.revoke(agentKey, block.timestamp, address(0), "reason");

        vm.prank(admin);
        vm.expectRevert("AIP: agent revoked");
        registry.revoke(agentKey, block.timestamp, address(0), "again");
    }

    // =========== Resolution ===========

    function test_resolve_unregistered_returns_zeros() public view {
        (address adminKey, bytes32 hash, string memory uri, uint256 regAt, uint256 updates, bool revoked) =
            registry.resolve(address(0xDEAD));

        assertEq(adminKey, address(0));
        assertEq(hash, bytes32(0));
        assertEq(bytes(uri).length, 0);
        assertEq(regAt, 0);
        assertEq(updates, 0);
        assertFalse(revoked);
    }

    // =========== Multi-update history ===========

    function test_multiple_updates_increment_count() public {
        vm.prank(agentKey);
        registry.register(configHash, metadataURI);

        for (uint256 i = 1; i <= 5; i++) {
            vm.prank(agentKey);
            registry.updateConfig(agentKey, keccak256(abi.encodePacked("config-v", i)), metadataURI2);
        }

        (,,,, uint256 updates,) = registry.resolve(agentKey);
        assertEq(updates, 5);
    }
}
