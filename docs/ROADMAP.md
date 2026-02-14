# Roadmap — Agent Identity Protocol (AIP)

## Current Status: Phase 1 — Foundation

### Phase 1: On-Chain Registry (NOW)

The minimal viable protocol. An agent can register its existence and update its configuration on-chain.

#### Deliverables

- [ ] **Registry smart contract** (`contracts/src/AgentRegistry.sol`)
  - `register()` — genesis attestation
  - `registerWithAdmin()` — genesis with separate admin key
  - `updateConfig()` — configuration change record
  - `resolve()` — query current and historical state
  - `revoke()` — identity revocation with optional successor
- [ ] **Contract tests** (`contracts/test/`)
  - Registration (single agent, duplicate prevention)
  - Configuration updates (authorization, history preservation)
  - Resolution (current state, full history)
  - Revocation (authorization, successor linking)
  - Edge cases (zero address, empty hashes, gas optimization)
- [ ] **Off-chain metadata schema** (`docs/schemas/metadata-v0.1.json`)
  - JSON Schema for the metadata manifest
  - Validation tooling
- [ ] **SDK — Core** (`sdk/src/`)
  - Key pair generation and management
  - Configuration hashing (system prompt, model, tools, runtime)
  - Registration transaction builder
  - Resolution and verification client
- [ ] **ERC Draft** (`docs/ERC_DRAFT.md`)
  - Following EIP-1 template
  - Abstract, Motivation, Specification, Rationale, Security Considerations
- [ ] **Ethereum Magicians post**
  - Problem framing
  - Link to spec and reference implementation
  - Call for feedback

#### Success Criteria
- Contract deployed to testnet (Sepolia or Base Sepolia)
- At least one agent (this project's own agent!) registered with a valid identity chain
- SDK can register, update, and resolve agent identities
- ERC draft submitted and discussion thread active

---

### Phase 2: Platform Attestation (NEXT)

Add support for inference platforms to cryptographically sign input attestations.

#### Deliverables

- [ ] **Attestation signature standard** — define exactly what platforms sign and in what format
- [ ] **Metadata manifest v0.2** — include `platform_signature` field with schema
- [ ] **Verification library** — given a platform's public key and a signed attestation, verify integrity
- [ ] **Reference integration** — example code showing how a platform would add signing to their inference pipeline
- [ ] **Trust tier resolution** — SDK logic that determines an agent's current trust tier based on available attestations
- [ ] **Platform onboarding documentation** — clear docs explaining the value prop and integration effort for platforms

#### Success Criteria
- Verification library can validate platform signatures against known public keys
- At least one demonstration of the full flow: agent registers → platform signs → verifier confirms
- Documentation sufficient for a platform engineer to evaluate integration effort

---

### Phase 3: Cryptographic Verification (FUTURE)

Research and experimental implementations of stronger verification.

#### Research Areas

- **TEE attestation integration** — Intel SGX / AMD SEV remote attestation reports as identity chain records
- **ZK input binding** — prove that declared system prompt tokens match committed hash without revealing content
- **FHE input verification** — encrypt system prompt, verify hash commitment in encrypted domain
- **ZK-friendly model architectures** — neural network designs optimized for proof generation

#### This phase is research-oriented. No production deliverables expected without significant cryptographic advances.

---

### Phase 4: Ecosystem (FUTURE)

Higher-order abstractions built on the identity primitive.

#### Potential Extensions
- Permission grant protocol (cryptographically signed, scoped delegations)
- Decision logging standard (agent action audit trails)
- Reputation scoring framework
- Agent-to-agent trust negotiation protocol
- Tool/service registry with trust requirements
- Dispute resolution hooks

---

## Build Order (Phase 1)

For the implementing agent, here's the recommended sequence:

1. **Start with the contract.** It's the foundational primitive. Write `AgentRegistry.sol` and comprehensive tests.
2. **Define the metadata schema.** Create the JSON Schema for off-chain manifests.
3. **Build the SDK core.** Configuration hashing and registration transaction building.
4. **Write the ERC draft.** The spec crystallizes the design and forces precision.
5. **Deploy to testnet.** Get a live instance running.
6. **Self-register.** Register this agent's own identity on the protocol. The recursive demonstration.
7. **Draft the Ethereum Magicians post.** Frame the problem and invite community feedback.

## Decisions to Make

Track these in `DECISIONS.md` as they arise:

- Which L2 for initial testnet deployment?
- Solidity version and compilation targets?
- IPFS vs Arweave for metadata storage in the reference implementation?
- SDK language (TypeScript? Python? Both?)
- How to handle metadata manifest versioning?
