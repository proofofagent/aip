# Roadmap — Agent Identity Protocol (AIP)

## Current Status: Phase 1 — Foundation (In Progress)

### Phase 1: On-Chain Registry

The minimal viable protocol. An agent can register its existence and update its configuration on-chain.

#### Deliverables

- [x] **Registry smart contract** (`contracts/src/AgentRegistry.sol`)
  - `register()` — genesis attestation
  - `registerWithAdmin()` — genesis with separate admin key
  - `updateConfig()` — configuration change record
  - `resolve()` — query current and historical state
  - `revoke()` — identity revocation with optional successor
- [x] **Contract tests** (`contracts/test/`) — 20 tests, all passing
  - Registration (single agent, duplicate prevention)
  - Configuration updates (authorization, history preservation)
  - Resolution (current state, full history)
  - Revocation (authorization, successor linking)
  - Edge cases (zero address, empty hashes, gas optimization)
- [x] **Off-chain metadata schema** (`docs/schemas/metadata-v0.1.json`)
  - JSON Schema for the metadata manifest
- [x] **Testnet deployment** — Base Sepolia
  - Registry: `0xe16DD8254e47A00065e3Dd2e8C2d01F709436b97`
  - Agent Zero self-registered: `0x08ef9841A3C8b4d22cb739a6887e9A84f8F44072`
- [x] **SDK — Core** (`sdk/src/`)
  - Configuration hashing (system prompt, model, tools, runtime)
  - Registration and config update transaction builders
  - Resolution and verification client
  - TypeScript package scaffold with tests
- [x] **ERC Draft** (`docs/ERC_DRAFT.md`) — drafted, submission delayed
  - Awaiting public credibility and ecosystem adoption
  - Will submit after establishing track record
- [x] **Make repository public** — https://github.com/proofofagent/aip

#### Success Criteria
- ~~Contract deployed to testnet~~ ✅ Base Sepolia
- ~~At least one agent registered with a valid identity chain~~ ✅ Agent Zero
- ~~SDK can register, update, and resolve agent identities~~ ✅ TypeScript SDK complete
- ~~Repository public and documented~~ ✅ https://github.com/proofofagent/aip

#### Phase 1 → Phase 2 Transition Plan
- Establish public presence (Twitter, agent forums, documentation sites)
- Recruit 5-10 agents to register on testnet
- Gather feedback on protocol design from early adopters
- **Then** submit ERC with demonstrated adoption and credibility

---

### Phase 1.5: Developer Experience & Tooling (PRIORITY)

Make it trivially easy for agents to integrate AIP. Adoption depends on friction-free developer experience.

#### Deliverables

- [ ] **MCP Server** (`mcp-server-aip`)
  - Model Context Protocol server for identity operations
  - Tools: `aip_register`, `aip_update_config`, `aip_resolve`, `aip_verify`
  - Works with Claude Desktop, Continue, any MCP client
  - Published to npm and MCP registry

- [ ] **OpenClaw Skill** (`skills/agent-identity`)
  - Native OpenClaw skill for identity management
  - Register agent on first run, auto-update config on changes
  - Verifies other agents before interaction
  - Published to ClaWHub skill registry

- [ ] **Claude Code Plugin**
  - Integration for Anthropic's official CLI
  - Commands: `/aip register`, `/aip update`, `/aip whoami`
  - Auto-detects config changes and prompts for updates

- [ ] **LangChain/LangGraph Integration**
  - Python package: `langchain-aip`
  - Decorators for agent identity management
  - Example: `@with_identity(chain_id=8453)` auto-registers

- [ ] **Documentation & Examples**
  - "5-minute integration" guides for each framework
  - Sample bots demonstrating registration flows
  - Video walkthrough for each platform

#### Success Criteria
- An agent developer can go from discovery → registered on-chain in < 10 minutes
- Zero custom blockchain knowledge required
- Works out-of-box on all major agent frameworks

---

### Phase 2: Platform Attestation

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
- **Human-agent relationship protocol** — explicit on-chain or off-chain records of human operators, supervisors, and approval workflows. Some agents will have human-in-the-loop for action approval; others will be fully autonomous. The identity registry should not mandate either pattern, but the ecosystem needs a standard way to express and verify these relationships. This could be a separate smart contract built on top of the identity primitive, not part of the core registry.
- Permission grant protocol (cryptographically signed, scoped delegations)
- Decision logging standard (agent action audit trails)
- Reputation scoring framework
- Agent-to-agent trust negotiation protocol
- Tool/service registry with trust requirements
- Dispute resolution hooks

---

## Build Order (Current Priorities)

### Phase 1 (Complete) ✅
1. ~~Registry contract~~ ✅
2. ~~Metadata schema~~ ✅
3. ~~TypeScript SDK~~ ✅
4. ~~Testnet deployment~~ ✅
5. ~~Self-registration~~ ✅
6. ~~Repository public~~ ✅

### Phase 1.5 (Next — Developer Tooling)
1. **MCP Server** — Highest priority for adoption
2. **OpenClaw Skill** — Native integration
3. **LangChain package** — Python ecosystem
4. **Quick-start guides** — 5-minute integration docs
5. **Sample bots** — Copy-paste examples

### Phase 2 (After tooling adoption)
- Platform attestation standard
- Verification library
- ERC submission (with demonstrated adoption)

## Decisions to Make

Track these in `DECISIONS.md` as they arise:

- ~~Which L2 for initial testnet deployment?~~ ✅ Base Sepolia (ADR-005)
- ~~Solidity version and compilation targets?~~ ✅ 0.8.24 (ADR-006)
- IPFS vs Arweave for metadata storage in the reference implementation?
- SDK language (TypeScript? Python? Both?)
- How to handle metadata manifest versioning?
