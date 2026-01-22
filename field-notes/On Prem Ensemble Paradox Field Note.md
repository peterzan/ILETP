<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Field Note
## The On-Prem / Ensemble Paradox in Enterprise AI
Date: 12/27/25
Context: Inter-LLM ensemble testing across proprietary and open-weight models
Systems: Proprietary LLM APIs; on-prem open-weight LLM servers (Llama, Mixtral, Qwen)
Focus: Trust, deployment constraints, and enterprise adoption risk

## Context
Enterprises increasingly require **on-prem or sovereign AI deployments** for reasons of compliance, security, cost, and control. At the same time, enterprises rely on **multi-model redundancy and cross-checking** to establish trust, especially in decision-adjacent or safety-critical workflows.
This creates an implicit requirement:
LLMs used on-prem must behave reliably in **inter-LLM ensemble environments**.
Testing was conducted across proprietary LLMs (cloud-hosted) and open-weight models deployed locally, focusing on divergence behavior, role stability, API tolerance, and participation under ensemble conditions.

## Observation
A consistent and troubling pattern emerged:
Proprietary models:
- behave predictably in ensemble contexts
- tolerate conversational ambiguity
- maintain stable identity
- degrade gracefully when context is imperfect
- support trust-oriented workflows
Open-weight models (on-prem):
- perform well in single-agent use
- exhibit persona bleed and mirroring in ensembles
- depend on brittle conversation contracts
- enforce strict role alternation
- fail unpredictably or refuse participation under multi-assistant flows
- 
In some cases (e.g., Mixtral), the failure mode is not degraded output but hard API rejection, preventing participation altogether.

## Key Insight
A structural paradox becomes clear:
*The models that behave best in inter-LLM trust environments are precisely the ones enterprises cannot deploy on-prem.*
Conversely:
*The models enterprises are forced to deploy on-prem are the least prepared for ensemble-based trust architectures.*
This is not a coincidence, nor a question of model intelligence.

## Root Cause Analysis
The divergence arises from optimization pressure, not capability:
- Proprietary models have been hardened by:
    - chaotic real-world usage
    - enterprise integrations
    - layered tooling
    - tolerance for conversational messiness
- Open-weight models and their APIs have been optimized for:
    - clean, single-agent interactions
    - strict protocol compliance
    - benchmark performance
    - idealized conversational flows
    - 
As a result, ensemble safety and participation discipline were never first-class design goals in open-model serving infrastructure.

## Enterprise Implications
This paradox creates an adoption ceiling:
- Enterprises cannot rely solely on proprietary models due to deployment constraints.
- Enterprises cannot fully trust open-model ensembles due to infrastructure fragility.
- Trust instrumentation becomes noisy, brittle, or misleading.
- High-value use cases (agentic workflows, decision support, safety-critical systems) are delayed or avoided.
The risk is not immediate failure, but quiet stagnation:
- pilots that do not scale
- enthusiasm that softens
- expectations that are gradually repriced

## Industry-Level Risk
If unaddressed, this paradox represents a **systemic risk**:
- AI-driven growth assumptions depend on enterprise adoption
- Enterprise adoption depends on trust under constraint
- Trust under constraint currently fails at the infrastructure layer
Because this issue is:
- foreseeable
- technically fixable
- and currently under-recognized
…it represents a higher-order risk than model capability limits.

## Strategic Implication
This is not a call for better models, but for ensemble-grade infrastructure:
- API contracts that tolerate multi-assistant participation
- behavioral guarantees under ambiguity
- identity isolation and role discipline
- predictable failure modes
- explicit support for trust primitives
Until this layer matures, enterprises will be forced to choose between:
- sovereignty and trust
- control and reliability
- Neither choice is sustainable.

Status
- Observed empirically through hands-on system use
- Reinforced across multiple models and failure modes
- Not yet widely acknowledged in open-model ecosystems
- Likely to surface broadly as on-prem enterprise AI adoption accelerates