<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Field Note
## Local LLMs as Library Infrastructure vs. Rented Cognition
Date: 01/03/26
Context: ILETP experimentation using local Gemma and LLaMA on Apple Silicon (M-series), comparative discussions on open-weight vs proprietary models, and reflection on on-prem AI needs for regulated enterprises and SMBs

## Context
As local inference using open-weight models (Gemma, LLaMA) became stable and responsive on Apple Silicon, attention shifted from capability comparison toward usage framing.
A discussion with both models surfaced an analogy comparing model usage to library usage rather than API consumption. This prompted reflection on whether current deployment models — particularly the common split between on-prem orchestration and off-prem weights or inference — are structurally misaligned with the needs of regulated organizations.
The question was not whether local models can outperform frontier models, but whether the current business and deployment model of AI itself is optimized for trust, regulation, and broad accessibility.

## Observation
Both Gemma and LLaMA reasoned comfortably within a framing where models are treated as local resources rather than remote services. The discussion revealed that:
- Local models are experienced as **tools**, not agents acting elsewhere.
- Their use feels analogous to consulting a reference library:
    - inspectable,
    - repeatable,
    - locally governed,
    - and not mediated by external permission or pricing.
- In contrast, API-based proprietary models implicitly behave as rented cognition:
    - opaque,
    - usage-metered,
    - externally governed,
    - and unavailable when connectivity, policy, or pricing changes.
    
This contrast became more pronounced when considering **regulated environments** and **small organizations** without AI staff, legal teams, or tolerance for data egress.

## Key Insight
The dominant “hybrid” compromise — **on-prem systems paired with off-prem model ownership or inference** — optimizes vendor control, not user trust.
A clearer framing emerged:
**For regulated and resource-constrained organizations, AI must behave like infrastructure, not a service**.
Local, open-weight models function more like:
- installed software,
- owned reference material,
- or regulated equipment.
API-based models function like:
- outsourced judgment,
- contractual abstractions,
- or black-box consultants.
This distinction is experiential, not technical — and it materially affects trust.

## Interpretation
Treating AI models as *library infrastructure* reframes several assumptions:
- Trust does not begin with accuracy; it begins with **ownership and inspectability**.
- Regulation favors systems that are:
    - static enough to audit,
    - local enough to control,
    - and simple enough to explain.
- Small and mid-sized organizations (e.g., clinics, accounting firms, regional practices) are structurally excluded by AI offerings that assume:
    - continuous cloud access,
    - variable pricing,
    - legal negotiation,
    - and external data handling.
    
The issue is not that open-weight models are “good enough,” but that they are **deployable without permission**.

## Implications
- The current AI business model is misaligned with how regulated work is actually done.
- There exists a significant unmet need for **complete, local, enterprise-grade AI systems** — not frameworks — usable by organizations with no AI expertise.
- Local execution combined with ensemble accountability (rather than frontier scale) may offer a more defensible trust posture.
- Treating AI as owned infrastructure shifts cloud models into an escalation role, not a default dependency.
- This framing strengthens the case for inter-LLM trust systems: once AI is local and plural, **verification replaces deference**.

## Status
- Empirical reflection grounded in live system use
- Conceptual clarification, not a market prediction
- No claims made about model superiority
- Intended as a grounding note for future thinking on deployment models, regulation, and trust architecture