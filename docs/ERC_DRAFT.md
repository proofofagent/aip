# ERC Draft: Agent Identity Protocol (AIP)

> **Status:** DRAFT — Not yet submitted. Pending community discussion on Ethereum Magicians.

---

## Preamble

```
EIP: TBD
Title: Agent Identity Registry — Verifiable Identity for AI Agents
Author: TBD
Status: Draft
Type: Standards Track (ERC)
Category: ERC
Created: 2025-02-13
```

## Abstract

This ERC defines a minimal on-chain registry standard for AI agent identity. Agents register a cryptographic public key and a configuration hash, creating a verifiable, append-only identity chain. The standard enables services, users, and other agents to verify an agent's identity, track configuration changes, and establish trust based on verifiable history.

## Motivation

AI agents are increasingly acting as autonomous economic participants — executing transactions, consuming APIs, and making decisions on behalf of humans. However, no standard exists for verifying agent identity, tracking configuration changes, or establishing trust.

Current agent identification relies on API keys and OAuth tokens, which conflate the *user's* identity with the *agent's* identity. A user's agent can be completely reconfigured (new model, new prompt, new tools) while retaining the same credentials. External services cannot distinguish between an agent they've successfully interacted with before and a fundamentally different agent using the same credentials.

This ERC proposes a minimal identity primitive: a registry where agents declare existence with a cryptographic key pair and record configuration changes as signed, timestamped events. This creates the foundation for higher-order trust mechanisms (permissions, reputation, attestation) without mandating any specific implementation of those mechanisms.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Registry Interface

```solidity
interface IAgentRegistry {

    /// @notice Emitted when a new agent identity is registered
    event AgentRegistered(
        address indexed agentKey,
        address indexed adminKey,
        bytes32 configHash,
        string metadataURI,
        uint256 timestamp
    );

    /// @notice Emitted when an agent's configuration is updated
    event ConfigUpdated(
        address indexed agentKey,
        bytes32 indexed previousConfigHash,
        bytes32 newConfigHash,
        string metadataURI,
        uint256 timestamp
    );

    /// @notice Emitted when an agent identity is revoked
    event AgentRevoked(
        address indexed agentKey,
        uint256 effectiveFrom,
        address successorAgent,
        string reason
    );

    /// @notice Register a new agent identity. Caller becomes both agent key and admin key.
    /// @param configHash Keccak256 hash of the agent's initial configuration
    /// @param metadataURI Content-addressed URI pointing to the full metadata manifest
    function register(bytes32 configHash, string calldata metadataURI) external;

    /// @notice Register a new agent identity with a separate admin key.
    /// @param agentKey The agent's public key / address
    /// @param configHash Keccak256 hash of the agent's initial configuration
    /// @param metadataURI Content-addressed URI pointing to the full metadata manifest
    function registerWithAdmin(address agentKey, bytes32 configHash, string calldata metadataURI) external;

    /// @notice Update the agent's configuration. Must be called by admin key.
    /// @param agentKey The agent to update
    /// @param newConfigHash New configuration hash
    /// @param metadataURI Updated metadata manifest URI
    function updateConfig(address agentKey, bytes32 newConfigHash, string calldata metadataURI) external;

    /// @notice Revoke an agent identity. Must be called by admin key.
    /// @param agentKey The agent to revoke
    /// @param effectiveFrom Timestamp from which the identity should be considered compromised
    /// @param successorAgent Optional address of a successor agent identity (address(0) if none)
    /// @param reason Human-readable revocation reason
    function revoke(address agentKey, uint256 effectiveFrom, address successorAgent, string calldata reason) external;

    /// @notice Resolve the current state of an agent identity.
    /// @param agentKey The agent to query
    /// @return adminKey The admin key for this agent
    /// @return currentConfigHash The most recent configuration hash
    /// @return metadataURI The most recent metadata URI
    /// @return registeredAt Timestamp of genesis registration
    /// @return updateCount Number of configuration updates
    /// @return revoked Whether the identity has been revoked
    function resolve(address agentKey) external view returns (
        address adminKey,
        bytes32 currentConfigHash,
        string memory metadataURI,
        uint256 registeredAt,
        uint256 updateCount,
        bool revoked
    );
}
```

### Configuration Hash Computation

The `configHash` MUST be computed as:

```
configHash = keccak256(abi.encodePacked(
    systemPromptHash,     // keccak256 of the full system prompt
    modelIdentifier,      // bytes32 encoding of model name and version
    toolManifestHash,     // keccak256 of the ordered tool manifest
    runtimeMetadataHash   // keccak256 of framework and runtime info
))
```

### Metadata Manifest

The `metadataURI` MUST point to a content-addressed resource (IPFS CID or Arweave transaction ID) containing a JSON document conforming to the metadata schema defined in this standard.

The metadata manifest MUST include:
- `aip_version`: Protocol version string
- `agent.name`: Human-readable agent name
- `agent.creator`: Address of the creator
- `configuration.system_prompt_hash`: Hash of the system prompt
- `configuration.model.provider`: Model provider identifier
- `configuration.model.identifier`: Model identifier string
- `attestation.tier`: Integer indicating the trust verification tier (1-5)

The metadata manifest MAY include:
- `attestation.platform_signature`: Platform's cryptographic signature over the configuration
- `attestation.tee_report`: Trusted Execution Environment attestation report
- Additional fields as needed by the ecosystem

### Cross-Chain Identity URI

Agent identities SHOULD be referenced using the following URI scheme based on CAIP-2:

```
agentid:<chain-namespace>:<chain-reference>:<contract-address>:<agent-key>
```

### Events

All state changes MUST emit the corresponding event. Indexers and verifiers rely on events for efficient history reconstruction.

## Rationale

### Why append-only?
Configuration changes are the primary vector for agent trust degradation. If an agent's history could be edited, the entire trust model collapses. Append-only records ensure that every configuration the agent has ever run is permanently visible.

### Why separate agent key and admin key?
The agent's operational key may be used in high-frequency, lower-security contexts (signing API requests). The admin key controls identity mutations and should be kept in cold storage or a hardware wallet. Separation limits the blast radius of key compromise.

### Why no permissions or reputation on-chain?
Minimal scope. Identity is the primitive. Permissions, reputation, and dispute resolution are higher-order abstractions that different ecosystems will implement differently. The registry provides the foundation; the ecosystem builds the rest.

### Why no protocol fee or token?
Maximum adoption requires minimum friction. Any fee beyond gas creates a barrier. Any token creates speculation and governance complexity that distracts from the standard's utility. The value is in the standard itself, not in extracting rent from it.

### Why chain-agnostic?
AI agents operate across diverse ecosystems. Mandating a single chain would limit adoption to that chain's community. The protocol defines the data format and rules; the chain provides storage and verification.

## Backwards Compatibility

This ERC introduces a new registry contract and does not modify existing standards. No backwards compatibility issues.

## Security Considerations

### Key Compromise
If an agent's private key is compromised, an attacker can publish fraudulent configuration updates. The `revoke()` function and admin key separation mitigate this. Implementations SHOULD support key rotation through the successor agent mechanism.

### Metadata Integrity
The `metadataURI` points to off-chain data. If content-addressed storage is used (IPFS, Arweave), the data is immutable and verifiable against the URI. Implementations MUST use content-addressed storage and MUST NOT use mutable URIs (HTTP URLs).

### Configuration Attestation Limitations
Phase 1 (self-reported) configuration hashes rely on the operator's honesty. The agent operator could publish a hash that doesn't match the actual running configuration. Higher trust tiers (platform attestation, TEE, ZK proofs) address this progressively. Verifiers SHOULD consider the trust tier when making trust decisions.

### Front-Running
Registration transactions could theoretically be front-run to claim an agent key before the legitimate owner. Using `registerWithAdmin()` with a pre-generated agent key mitigates this, as the admin key proves ownership intent.

## Reference Implementation

See `contracts/src/AgentRegistry.sol` in the reference repository.

## Copyright

Copyright and related rights waived via CC0.
