# Architecture Decision Records

This document tracks significant design decisions, their context, and rationale.

## ADR-001: No Protocol Token

**Date:** 2025-02-13
**Status:** Accepted

**Context:** Many blockchain protocols introduce a native token for fee payment, governance, or incentives. We considered whether AIP should have a protocol token.

**Decision:** No token. Registration costs only native chain gas fees.

**Rationale:**
- A token creates speculation, which attracts participants motivated by financial gain rather than utility
- Token governance (DAOs) adds enormous complexity and tends toward plutocracy
- Fee extraction reduces adoption — every friction point is a reason not to participate
- The most successful Ethereum standards (ERC-20, ERC-721, ENS at the registry level) are token-free public goods
- The protocol's value comes from network effects of adoption, not from revenue extraction

**Consequences:**
- No built-in funding mechanism for protocol development
- Must rely on grants, ecosystem value, or services built on top of the protocol for sustainability
- Maximum adoption potential due to zero friction

---

## ADR-002: Chain-Agnostic Design

**Date:** 2025-02-13
**Status:** Accepted

**Context:** Should the protocol mandate a specific blockchain, or allow deployment on any EVM chain?

**Decision:** Chain-agnostic. The protocol defines the interface and data format. Agents choose their chain.

**Rationale:**
- AI agents operate across diverse ecosystems with different cost/speed/security requirements
- Mandating a chain limits adoption to that chain's community
- CAIP-2 provides existing standards for cross-chain identification
- The protocol's value is in the standard, not the specific deployment

**Consequences:**
- No single canonical registry — multiple deployments across chains
- Cross-chain verification requires knowing which chain to query (solved by URI scheme)
- Potential fragmentation of agent identity if an agent registers on multiple chains (addressed in spec: one identity per agent, choose one chain)

---

## ADR-003: Append-Only History

**Date:** 2025-02-13
**Status:** Accepted

**Context:** Should agents be able to edit or delete historical configuration records?

**Decision:** Append-only. No deletions, no edits. Full history always available.

**Rationale:**
- The entire trust model depends on verifiable, tamper-proof history
- If history could be edited, an agent could hide problematic configurations
- Append-only matches the natural properties of blockchain storage
- Revocation handles the compromised identity case without deleting history

**Consequences:**
- Storage costs grow over time (mitigated by keeping on-chain data minimal)
- No "right to be forgotten" for agent configurations (acceptable: these are public declarations, not personal data)
- Historical configuration hashes are permanent even if the agent is revoked

---

## ADR-004: Separate Agent Key and Admin Key

**Date:** 2025-02-13
**Status:** Accepted

**Context:** Should identity management use a single key or separate operational and administrative keys?

**Decision:** Support both. `register()` uses caller as both keys (simple case). `registerWithAdmin()` allows separation (recommended for production).

**Rationale:**
- Agent operational keys may be used in automated, high-frequency contexts with higher exposure
- Admin keys control identity mutations and should be more securely stored
- Key separation limits blast radius: compromised agent key can't alter identity; compromised admin key is mitigated by revocation
- Simple case (single key) lowers barrier for experimentation and testing

**Consequences:**
- Slightly more complex contract logic
- Better security posture for production agents
- Admin key becomes a critical asset requiring secure storage (hardware wallet recommended)

---

## Pending Decisions

- **PDR-001:** Which L2 for initial testnet deployment? (Candidates: Sepolia, Base Sepolia, Arbitrum Sepolia)
- **PDR-002:** Solidity version? (0.8.24+ recommended for latest features)
- **PDR-003:** SDK language? (TypeScript for widest adoption? Python for ML ecosystem? Both?)
- **PDR-004:** IPFS vs Arweave for reference metadata storage?
- **PDR-005:** How to handle metadata schema versioning as the protocol evolves?
