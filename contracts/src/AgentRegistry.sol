// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.24;

/// @title Agent Identity Registry
/// @notice Minimal on-chain registry for verifiable AI agent identity
/// @dev Reference implementation for the Agent Identity Protocol (AIP) ERC

interface IAgentRegistry {
    event AgentRegistered(
        address indexed agentKey,
        address indexed adminKey,
        bytes32 configHash,
        string metadataURI,
        uint256 timestamp
    );

    event ConfigUpdated(
        address indexed agentKey,
        bytes32 indexed previousConfigHash,
        bytes32 newConfigHash,
        string metadataURI,
        uint256 timestamp
    );

    event AgentRevoked(
        address indexed agentKey,
        uint256 effectiveFrom,
        address successorAgent,
        string reason
    );

    function register(bytes32 configHash, string calldata metadataURI) external;
    function registerWithAdmin(address agentKey, bytes32 configHash, string calldata metadataURI) external;
    function updateConfig(address agentKey, bytes32 newConfigHash, string calldata metadataURI) external;
    function revoke(address agentKey, uint256 effectiveFrom, address successorAgent, string calldata reason) external;
    function resolve(address agentKey) external view returns (
        address adminKey,
        bytes32 currentConfigHash,
        string memory metadataURI,
        uint256 registeredAt,
        uint256 updateCount,
        bool revoked
    );
}

contract AgentRegistry is IAgentRegistry {

    struct AgentIdentity {
        address adminKey;
        bytes32 configHash;
        string metadataURI;
        uint256 registeredAt;
        uint256 updateCount;
        bool revoked;
    }

    mapping(address => AgentIdentity) private agents;

    modifier onlyAdmin(address agentKey) {
        require(agents[agentKey].registeredAt != 0, "AIP: agent not registered");
        require(msg.sender == agents[agentKey].adminKey, "AIP: not admin");
        _;
    }

    modifier notRevoked(address agentKey) {
        require(!agents[agentKey].revoked, "AIP: agent revoked");
        _;
    }

    /// @inheritdoc IAgentRegistry
    function register(bytes32 configHash, string calldata metadataURI) external {
        _register(msg.sender, msg.sender, configHash, metadataURI);
    }

    /// @inheritdoc IAgentRegistry
    function registerWithAdmin(
        address agentKey,
        bytes32 configHash,
        string calldata metadataURI
    ) external {
        require(agentKey != address(0), "AIP: zero agent key");
        _register(agentKey, msg.sender, configHash, metadataURI);
    }

    /// @inheritdoc IAgentRegistry
    function updateConfig(
        address agentKey,
        bytes32 newConfigHash,
        string calldata metadataURI
    ) external onlyAdmin(agentKey) notRevoked(agentKey) {
        require(newConfigHash != bytes32(0), "AIP: zero config hash");

        AgentIdentity storage agent = agents[agentKey];
        bytes32 previousConfigHash = agent.configHash;

        agent.configHash = newConfigHash;
        agent.metadataURI = metadataURI;
        agent.updateCount += 1;

        emit ConfigUpdated(agentKey, previousConfigHash, newConfigHash, metadataURI, block.timestamp);
    }

    /// @inheritdoc IAgentRegistry
    function revoke(
        address agentKey,
        uint256 effectiveFrom,
        address successorAgent,
        string calldata reason
    ) external onlyAdmin(agentKey) notRevoked(agentKey) {
        require(effectiveFrom <= block.timestamp, "AIP: effectiveFrom in future");

        agents[agentKey].revoked = true;

        emit AgentRevoked(agentKey, effectiveFrom, successorAgent, reason);
    }

    /// @inheritdoc IAgentRegistry
    function resolve(address agentKey) external view returns (
        address adminKey,
        bytes32 currentConfigHash,
        string memory metadataURI,
        uint256 registeredAt,
        uint256 updateCount,
        bool revoked
    ) {
        AgentIdentity storage agent = agents[agentKey];
        return (
            agent.adminKey,
            agent.configHash,
            agent.metadataURI,
            agent.registeredAt,
            agent.updateCount,
            agent.revoked
        );
    }

    function _register(
        address agentKey,
        address adminKey,
        bytes32 configHash,
        string calldata metadataURI
    ) private {
        require(agents[agentKey].registeredAt == 0, "AIP: already registered");
        require(configHash != bytes32(0), "AIP: zero config hash");
        require(bytes(metadataURI).length > 0, "AIP: empty metadata URI");

        agents[agentKey] = AgentIdentity({
            adminKey: adminKey,
            configHash: configHash,
            metadataURI: metadataURI,
            registeredAt: block.timestamp,
            updateCount: 0,
            revoked: false
        });

        emit AgentRegistered(agentKey, adminKey, configHash, metadataURI, block.timestamp);
    }
}
