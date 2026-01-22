<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Field Note
## Enterprise Dependence on Immature Open-Model Infrastructure
Date: 12/27/25
Context: Multi-LLM ensemble testing using open-weight models for on-prem deployment
Systems: Local open-model servers (Llama, Mixtral, Qwen, etc.), proprietary LLMs for comparison
Focus: Trust, divergence, and enterprise readiness

## Context
As part of ongoing divergence testing and trust instrumentation for inter-LLM ensembles (ILETP), attention shifted from model behavior itself to the **infrastructure assumptions surrounding open-weight LLM deployments.**
This investigation was motivated by a practical enterprise constraint:
**proprietary LLMs cannot currently be deployed on premises**, forcing enterprises to rely on open models for sovereignty, compliance, and cost control.
The question explored was not whether open models are capable, but whether the systems surrounding them are ready for enterprise trust requirements.

## Observation
Open-weight LLMs generally perform well in single-agent scenarios. However, when used in ensemble or cross-checking configurations — the exact pattern enterprises use to establish trust — several systemic issues emerge:
- APIs and conversation frameworks assume **single assistant / strict turn-taking**
- Role confusion appears when multiple models participate
- Pattern propagation and persona bleed occur across models
- Divergence signals fluctuate unpredictably due to stylistic variance
- Infrastructure failures are easily misattributed to “model hallucination”

These issues were observed consistently across multiple open-model servers and did not correlate strongly with model intelligence or correctness.

By contrast, proprietary LLMs exhibited more stable behavior in ensemble contexts — not because they are inherently better models, but because their APIs and behavioral constraints have been hardened through enterprise exposure.

## Key Insight
A critical dependency inversion becomes visible:
*Enterprises are forced to depend on open models precisely in the environments where behavioral reliability matters most — yet the surrounding infrastructure is not ensemble-safe.*

This creates a structural risk:
- Enterprises require multi-model redundancy for trust
- Open models are the only viable on-prem option
- Open infrastructure has not yet been designed for multi-agent trust hygiene
The result is not simply degraded performance, but fragile trust signaling.

## Why This Is Concerning
Most enterprises have not yet encountered these issues because current deployments are limited to:
- summarization
- search augmentation
- copilots
- low-risk advisory tasks

As enterprises move toward:
- agentic workflows
- decision-adjacent AI
- safety-critical or regulated environments
…these infrastructure limitations will surface rapidly and non-linearly.

Importantly, when failures occur, they are likely to be:
- misdiagnosed as “model quality problems”
- treated with fine-tuning or prompt engineering
- patched locally and inconsistently
This delays systemic correction and increases fragmentation.

## Enterprise Reality Check
Enterprises cannot reasonably:
- rewrite open-model APIs
- enforce behavioral discipline across heterogeneous models
- normalize divergence signals manually
- absorb the liability of unreliable trust instrumentation
If upstream systems do not evolve, enterprises will be forced to:
- build heavy custom trust layers
- restrict ensemble usage
- delay autonomous or agentic adoption
- or retreat from high-value AI use cases altogether

## Strategic Implication
This is not a research gap — it is a **platform maturity gap**.
The next phase of enterprise AI adoption will be gated less by:
- model intelligence
- benchmark scores
- token economics
…and more by:
- governability
- predictability
- ensemble compatibility
- trust-primitive awareness
Vendors who address this upstream will unlock disproportionate enterprise value.
Those who do not will see AI adoption plateau at low-risk use cases.

## Status
- Observed through hands-on system use
- Not yet widely acknowledged in open-model ecosystems
- Likely to surface broadly within 12–24 months
- Captured for future reference and synthesis