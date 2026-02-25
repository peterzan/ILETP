<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# ILETP Glossary
## Core Terminology for Multi-Model AI Orchestration and Governance
Version 1.0 — February 21, 2026

---

## Purpose

This document defines key terms used across the ILETP (Independent Large Language Model Ensemble Trust Protocol) framework, including field notes, specifications, and related publications. Definitions emerged from operational experience building and governing multi-model AI systems, not from theoretical taxonomy. They reflect real architectural and governance distinctions encountered in practice.

This glossary is intended as a shared reference for all ILETP documentation. Contributors, partners, and adopters should use these terms consistently to avoid ambiguity.

---

## Architecture Terms

### Inter-LLM Ensemble
A coordinated group of language models sourced from **different providers** (e.g., Claude + Gemini + ChatGPT), orchestrated to process the same input and produce independent outputs for comparison.

The value of an inter-LLM ensemble derives from the **independence** of its members. Models trained on different data, built on different architectures, and developed by organizations with different incentives produce genuinely independent perspectives. Divergence between ensemble members is a strong governance signal precisely because the models share no common lineage.

Analogy: A jazz quartet — different instruments, different voices, one composition.

### Multi-LLM Fleet
A coordinated group of language models sourced from the **same provider or model family** (e.g., multiple fine-tuned variants of Llama, or Sonnet + Opus within the Claude family), deployed for different roles, tasks, or departments within an organization.

Fleet models share lineage — training methodology, base architecture, and often base training data. Divergence within a fleet is a weaker governance signal because models may share the same blind spots. Fleet value derives from **specialization** — different models optimized for different operational roles.

Analogy: A vehicle fleet — same manufacturer, different routes, shared maintenance infrastructure.

### Hybrid Architecture
A deployment that combines an inter-LLM ensemble with one or more multi-LLM fleets. For example, an enterprise might run a Llama fleet for routine departmental inference while maintaining a cross-provider ensemble for high-stakes validation and trust verification.

Hybrid architectures require governance policies that account for both fleet management and ensemble integrity simultaneously.

### Orchestration Layer
The software infrastructure that manages model selection, request routing, parallel execution, response collection, and result synthesis across an ensemble or fleet. The orchestration layer handles the mechanics of multi-model operation.

Distinct from the governance layer, which manages policy, trust, and lifecycle decisions.

### Governance Layer
The policy and process infrastructure that manages trust verification, divergence thresholds, lifecycle policy, upgrade decisions, audit logging, and human escalation rules. The governance layer makes decisions about whether the ensemble is operating correctly and what to do when it isn't.

Distinct from the orchestration layer, which handles execution mechanics.

---

## Signal Terms

### Divergence
A measurable disagreement between models in an ensemble or fleet when given the same input. Divergence is the primary signal in ILETP's trust verification methodology.

Divergence can manifest as:
- **Factual disagreement**: Models assert contradictory facts.
- **Structural disagreement**: Models agree on facts but organize or prioritize them differently.
- **Absence divergence**: One model addresses a dimension that others omit entirely.
- **Confidence divergence**: Models reach the same conclusion with meaningfully different certainty.

Not all divergence indicates a problem. Some divergence is expected and healthy — it reflects genuine uncertainty or legitimate alternative perspectives.

### Consensus
Agreement among ensemble members on a given output. Consensus is a trust-building signal, but it is not proof of correctness. Correlated failures — where all models share the same blind spot — produce false consensus.

The value of consensus is proportional to the independence of the models producing it. Consensus across an inter-LLM ensemble is a stronger signal than consensus within a multi-LLM fleet.

### Divergence Threshold
A configured boundary that determines when divergence between model outputs triggers an action — such as flagging for human review, requesting additional model input, or halting automated processing. Thresholds are domain-specific and risk-stratified.

### Correlated Failure
A failure mode where multiple models in an ensemble produce the same incorrect or incomplete output. Correlated failure is more likely within a fleet (shared lineage) than across an ensemble (independent providers), but it can occur in both architectures.

Correlated failure is the primary risk that ensemble governance is designed to detect and mitigate. It is also the reason human governance cannot be fully automated away.

---

## Lifecycle Terms

### Model Artifact
A specific, deployable instance of a language model — pinned to a version, configured for a target environment, and governed under a defined compliance regime. A model artifact is an owned asset, distinct from a model accessed as a service via API.

In the distillation-as-licensing framework, the model artifact is the delivered product: a customer-specific, distilled model deployed on-prem or at the edge.

### Model Service
A language model accessed via API as a continuously available service, typically hosted by the provider. The customer does not own, version-control, or govern the underlying model directly. Model behavior may change as the provider updates the service.

### Version Pinning
The practice of specifying an exact, dated model version in API calls rather than using a floating alias that the provider may silently update. Version pinning ensures that ensemble behavior remains stable and that divergence signals are not contaminated by uncontrolled model changes.

Version pinning is a baseline governance requirement for any production ensemble deployment.

### Shadow Testing
A validation practice where a new model version runs in parallel alongside the production ensemble without affecting live outputs. Shadow results are compared against production to evaluate whether the upgrade changes divergence patterns, consensus behavior, or output quality before cutover.

### Lifecycle Policy
The set of rules governing when and how model versions are upgraded, tested, validated, and retired within an ensemble or fleet. Lifecycle policies are risk-stratified — the same ensemble architecture may operate under different policies depending on the domain it serves.

See: Field Note — Model Lifecycle Governance in Multi-LLM Ensembles.

---

## Governance Terms

### Health Check
A structured validation process that evaluates whether an ensemble is operating within expected parameters at a point in time. The ILETP Health Check specification defines a four-phase validation covering model availability, response quality, divergence behavior, and trust signal integrity.

Distinct from lifecycle governance, which ensures the ensemble remains healthy over time as models and configurations change.

### Lifecycle Governance
The ongoing practice of managing model versions, upgrade cycles, regression testing, and configuration changes across an ensemble or fleet over its operational lifetime. Lifecycle governance extends Health Check from a point-in-time validation to a continuous assurance process.

### Human-in-the-Loop
The governance principle that human judgment remains the final authority in ensemble decision-making, particularly for high-stakes domains. The ensemble surfaces information, identifies divergence, and flags uncertainty — but a human makes the final call.

This is not a limitation of the technology. It is a design principle. The ensemble's value is in making human judgment better-informed, not in replacing it.

### Risk Stratification
The practice of calibrating governance policies — divergence thresholds, lifecycle policies, validation requirements, human review gates — based on the consequences of error in a given domain.

The determining question: **What happens if this system gives a wrong answer?**

Low-stakes domains tolerate faster cycles and lighter validation. High-stakes domains require conservative policies, extended testing, and external validation.

---

## Business Model Terms

### Distillation-as-Licensing
A business model framework in which frontier AI labs function as intelligence manufacturers — providing base models, distillation pipelines, validation tooling, and licensing frameworks — to produce customer-specific model artifacts that are deployed on-prem, governed locally, and contractually owned by the customer.

Shifts intelligence from a continuously rented service to a manufactured and delivered product.

See: Field Note — Licensed Distillation as Intelligence Product.

### Intelligence Artifact
The output of a distillation-as-licensing engagement: a customer-specific model, optimized for target hardware, validated against domain requirements, and delivered as an owned asset. The customer governs the artifact under their compliance regime. The provider retains IP rights to the base model and distillation methodology.

### Departmental Wedge
The observation that AI adoption in enterprises occurs department by department rather than enterprise-wide. Regulated departments — Finance, HR, Legal, R&D, Security — adopt isolated AI systems driven by compliance requirements, creating millions of internal "AI islands" across global enterprises.

The departmental wedge is the primary adoption pattern driving enterprise AI infrastructure redistribution.

### Services Multiplier
The historical observation that enterprise infrastructure investment carries an additional 1.3–1.5x in services spending (integration, governance, tuning, operations). Applied to the enterprise AI redistribution, this multiplier significantly expands the total addressable market beyond hardware and software alone.

---

## Methodology Terms

### Ping-Pong Methodology
An orchestration approach where a task is passed between multiple AI models iteratively, with each model building on, refining, or challenging the previous model's output. Distinct from parallel execution (where all models process the same input simultaneously).

Ping-pong leverages the different strengths and perspectives of each model across sequential passes rather than comparing simultaneous outputs.

### Ensemble as Thinking Tool
The practice of using multi-model orchestration not to produce more output faster, but to improve the quality of human reasoning. The ensemble surfaces blind spots, reveals gaps, and identifies disagreements that inform better human judgment.

Distinct from using AI as a production tool (generating content) or an automation tool (replacing human tasks).

---

## Document References

- ILETP Ensemble Health Check Specification
- Field Note: Licensed Distillation as Intelligence Product
- Field Note: Model Lifecycle Governance in Multi-LLM Ensembles
- Field Note: MCP as Nervous System for Multi-Model Code Review & Governance
- Field Note: Open-Source Plugins and the Licensing Gap
- Enterprise Reborn: The Redistribution of AI Infrastructure
- The Paul Revere Paper (Self-Knowledge Gap in AI Models)

---

## Versioning

This glossary is a living document. Terms will be added, refined, or deprecated as the ILETP framework matures and operational experience accumulates. Version history:

- **v1.0 (February 21, 2026)**: Initial publication. Core architecture, signal, lifecycle, governance, business model, and methodology terms.
