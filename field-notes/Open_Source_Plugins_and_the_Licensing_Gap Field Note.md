<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Field Note: Open-Source Plugins and the Licensing Gap

## Summary

On January 30, 2026, Anthropic open-sourced 11 vertical plugins for its Claude Cowork platform — covering legal, finance, sales, marketing, customer support, and other domains. The market responded immediately: a $285 billion selloff across software, legal tech, and professional services stocks. Analysts called it a "SaaSpocalypse."

The plugins validate massive demand for vertical AI.

They also reveal a structural gap between how that demand is being served and how it needs to be served.

⸻

## Context

Cowork launched January 12, 2026 as an agentic tool for non-developers — Claude Code for the rest of your work. The plugin release extended it with domain-specific capabilities: contract review, NDA triage, compliance tracking, sales CRM integration, and more.

The plugins are built on MCP (Model Context Protocol), Anthropic's open standard for connecting AI to external tools and data sources.

All 11 plugins were released as open source on GitHub.

The architecture is straightforward:
- structured prompts define domain workflows
- MCP connects to external systems
- Claude provides the inference layer
- humans review and approve outputs

This is a SaaS delivery model. Intelligence lives in the cloud. Data flows to the model. Customers subscribe.

⸻

## Observation

The plugins are not model-specific capabilities.

They are orchestration logic — structured prompts, workflow definitions, and MCP configurations. They describe *what to do*, not *how to think*.

Any sufficiently capable model can follow these instructions.

By open-sourcing the plugins, Anthropic published a blueprint for building vertical AI workflows across legal, finance, sales, and other domains — and made it available to anyone.

The components now exist independently:
- workflow logic (open-source plugins)
- orchestration standard (open-source MCP)
- inference engines (open-weight models from Meta, Google, Alibaba, and others)
- deployment hardware (commodity servers, SoCs, appliances)

Each layer is available. None requires Anthropic.

A systems integrator, a hardware partner, or a capable internal team can now assemble a fully governed, behind-the-firewall vertical AI system with no cloud dependency.

⸻

## The Gap

The market reaction confirmed the demand.

The delivery model does not match the need.

Most regulated organizations — law firms, healthcare providers, financial institutions, government agencies — face constraints that a cloud SaaS model cannot satisfy:
- client data cannot leave the premises
- regulatory frameworks require data locality
- liability exposure prohibits third-party inference on sensitive material
- compliance mandates require auditable, internally governed systems

These are not preferences. They are legal requirements in many jurisdictions.

The same constraints apply to small and mid-sized businesses — which represent over 99% of all US firms and the vast majority of businesses globally. A 10-person law firm, a family medical practice, a small manufacturer — these organizations need vertical AI capability but will never be cloud API customers.

The current model serves enterprises with cloud-compatible workloads.

It does not serve regulated departments within those enterprises.

It does not serve SMBs at all.

⸻

## Pattern

Anthropic has commoditized every layer of the vertical AI stack except the model — while competitors are commoditizing the model.

This creates a familiar dynamic:
- the workflow layer is open
- the orchestration layer is open
- the model layer is increasingly open
- the only remaining differentiator is model quality
- model quality is a narrowing advantage for domain-specific tasks

Distillation accelerates this convergence. Task-specific capabilities can be transferred from frontier models into smaller, deployable models at a fraction of the cost. For routine, well-defined workflows — NDA triage, compliance checklists, standard contract review — a distilled or fine-tuned smaller model approaches frontier quality.

The question is not whether these vertical workflows will run on local infrastructure.

They will.

The question is whether frontier labs participate in that transition or get routed around.

⸻

## Implication

A complementary business model exists.

It does not require abandoning centralized SaaS. It extends alongside it.

The mechanism is distillation-as-licensing:
- frontier labs provide base models, distillation pipelines, and tuning expertise
- customers provide domain data, hardware, and deployment environments
- distilled models are licensed for on-prem or edge deployment
- licensing terms define ownership, usage, update cycles, and revenue

The customer gets frontier-quality inference behind the firewall.

The lab gets license revenue from a market segment it currently earns nothing from.

This is not a novel business model. It is standard IP licensing — the same framework ARM, Qualcomm, and the semiconductor industry have operated under for decades. The legal, financial, and operational structures already exist.

Hardware partners — Dell, HPE, Lenovo — already sell to these customers and already maintain the service relationships. They become the distribution channel. The frontier lab becomes an upstream intelligence supplier.

This addresses:
- regulated enterprises requiring data sovereignty
- SMBs requiring affordable, locally operable AI
- global markets where cloud dependency is impractical or prohibited
- the strategic exposure created by open-sourcing workflow and orchestration layers

⸻

## Open Questions

- What distillation fidelity is required for specific vertical tasks?
- How should licensing terms balance customer ownership with lab IP protection?
- Which hardware partners are best positioned as distribution channels?
- How do update and retraining cycles work under a licensing model?
- What role do open-weight models play as competitive pressure on licensing economics?
- How does this model apply across different regulatory regimes globally?

⸻

## Closing

The Cowork plugin release proved two things simultaneously:

Vertical AI demand is real and massive.

The current delivery model cannot reach most of the market that wants it.

Open-source plugins on open-source orchestration with increasingly open models create an inevitable path toward local deployment.

Frontier labs can lead that transition through distillation and licensing.

Or they can watch it happen without them — using their own tools.
