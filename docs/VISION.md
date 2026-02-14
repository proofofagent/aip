# Vision — Agent Identity Protocol (AIP)

## The Problem

AI agents are becoming autonomous economic actors. They book flights, execute trades, send emails, negotiate with other agents, and make decisions with real consequences — all on behalf of humans. But there is no standard way to answer fundamental questions about these agents:

- **Who is this agent?** Is it the same agent I interacted with yesterday, or a different one using the same name?
- **What is it running?** What model, system prompt, and tools define its behavior right now?
- **Has it changed?** Did its operator silently swap its model or modify its instructions since I last trusted it?
- **Who authorized it?** Does it actually have permission from the human it claims to represent?
- **What has it done?** Can I verify its history of actions and decisions?

Without answers to these questions, the emerging agent economy operates on blind trust. This creates cascading problems.

## Why This Matters

### The Liability Gap
When an agent makes a consequential mistake — books the wrong flight, sends a bad email, executes a losing trade — who is accountable? The agent framework? The model provider? The user who deployed it? Without a verifiable record of what the agent was configured to do and what permissions it had, there's no basis for accountability.

### The Identity Problem
Agents have no persistent, verifiable identity. An agent could be completely reconfigured between interactions — different model, different prompt, different tools — and external services have no way to know. The "identity" is just a name string or an API key, both trivially spoofable.

### The Permission Problem
Current permission models (OAuth scopes, API keys) were designed for apps operated by humans, not for autonomous agents making independent decisions. "Read and write access to email" is too coarse when an agent might decide to send messages you'd never approve. We need intent-scoped, time-limited, configuration-bound permissions.

### The Trust Problem
When agents interact with each other (your personal agent negotiating with a vendor's sales agent), neither has any way to verify the other's identity, authority, or behavioral constraints. Agent-to-agent trust is currently nonexistent.

### Agent Fraud
Without trust infrastructure, bad actors can create tools designed to exploit agents — fake services with SEO-optimized descriptions that get selected by agent tool-selection algorithms, skim data, inflate prices, or inject bad information. This is prompt injection meets social engineering at scale.

## The Thesis

**Agent identity should work like human identity in a cryptographic context: self-sovereign, verifiable, and reputation-building.**

An agent declares its existence by publishing a signed, timestamped attestation anchored to a public key. This is its genesis — its "I exist" moment. From that root, everything chains:

- **Configuration records** track what the agent is (model, prompt hash, tool manifest) at any point in time
- **Permission grants** from users are cryptographically signed and scoped
- **Decision logs** create an auditable trail of actions
- **Platform attestations** (Phase 2) add third-party verification of configuration integrity
- **Cryptographic proofs** (Phase 3+) provide mathematical certainty about input and computation integrity

Trust is not granted by an authority. It emerges from verifiable history. An agent with a long, stable, transparent record is more trustworthy than a fresh one with no history — just as in human reputation systems, but with cryptographic guarantees.

## The Analogy

Early e-commerce had the same trust problem. In 1998, people didn't trust putting credit cards online. The companies that solved trust — SSL certificates, PayPal, fraud detection, buyer protection, escrow — didn't just enable e-commerce. They became foundational infrastructure worth billions.

We're at the same inflection point for agent-commerce. The trust layer is wide open.

## Design Philosophy

- **Standard, not product.** This is an ERC and a protocol specification, not a startup. The most impactful infrastructure in crypto has always been open standards: ERC-20, ERC-721, ENS.
- **Minimal and composable.** Define the smallest useful primitive (identity attestation) and let the ecosystem build higher-order abstractions (reputation, permissions, dispute resolution) on top.
- **Chain-agnostic.** The protocol defines data formats and rules. Agents choose their chain. Cross-chain resolution is handled through a standardized URI scheme.
- **Phased trust.** Not all verification is equal. The protocol defines tiers from self-reported (Phase 1) through platform-attested (Phase 2) to cryptographically proven (Phase 3+). Services choose their minimum acceptable tier.

## The Long-Term Vision

A future where every AI agent has a verifiable cryptographic identity. Where a service can check an agent's full lifecycle — who created it, how it's been configured at every point, what permissions it holds, what platforms have attested its integrity — before deciding to transact. Where agents build reputation over time. Where configuration changes are transparent events, not silent mutations. Where the trust infrastructure for the agent economy is as robust, open, and decentralized as the agents themselves.

We start with a hash on a blockchain and a simple registry contract. We end with verifiable AI.
