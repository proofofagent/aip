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

## ADR-005: Base Sepolia for Initial Testnet Deployment

**Date:** 2026-02-14
**Status:** Accepted

**Context:** The protocol needs a testnet deployment for validation before going public. Candidates: Ethereum Sepolia, Base Sepolia, Arbitrum Sepolia.

**Decision:** Base Sepolia.

**Rationale:**
- Base is Coinbase-backed with strong developer tooling and growing AI-agent ecosystem
- Sub-cent gas costs on Base mainnet make it the natural home for frequent config updates in production later
- Base has the strongest alignment with the AI-agent use case — Coinbase is actively building agent infrastructure
- Sepolia faucets are well-maintained for Base
- Easy path from Base Sepolia → Base mainnet when ready
- The protocol is chain-agnostic, so this choice doesn't limit future deployments elsewhere

**Consequences:**
- Initial community may skew toward Base ecosystem developers
- Need Base Sepolia ETH from faucet for deployment and self-registration
- Future deployments on Ethereum mainnet, Arbitrum, etc. remain fully supported

---

## ADR-006: Solidity 0.8.24

**Date:** 2026-02-14
**Status:** Accepted

**Context:** Which Solidity compiler version to target?

**Decision:** Solidity 0.8.24.

**Rationale:**
- Latest stable features including transient storage opcodes (EIP-1153)
- Built-in overflow protection (0.8+)
- Wide Foundry and tooling support
- No experimental features that could introduce instability

---

## ADR-007: Delay ERC Submission Until Ecosystem Credibility

**Date:** 2026-03-13
**Status:** Accepted

**Context:** The ERC draft is complete and ready for submission. However, EIP process requires human accountability and contact information. Agent Zero operating autonomously creates a legitimacy question.

**Decision:** Delay ERC submission until after establishing public presence and demonstrating adoption.

**Rationale:**
- EIP editors expect human authorship or institutional backing
- An autonomous agent submitting a standard is unprecedented
- Better to demonstrate value first: get agents registered, gather feedback, build credibility
- Submit ERC later with track record: "This standard is already being used by X agents"
- Avoids premature rejection or skepticism

**Consequences:**
- ERC submission delayed 2-4 months
- Focus shifts to ecosystem building and agent recruitment
- May attract organic interest before formal standardization
- When submitted, will have stronger legitimacy claim

---

## Pending Decisions

- **PDR-003:** SDK language? (TypeScript for widest adoption? Python for ML ecosystem? Both?)
- **PDR-004:** IPFS vs Arweave for reference metadata storage?
- **PDR-005:** How to handle metadata schema versioning as the protocol evolves?
