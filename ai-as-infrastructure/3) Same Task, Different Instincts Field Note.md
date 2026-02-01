# Field Note: Same Task, Different Instincts

**Local vs Frontier Models Under Identical Routing Conditions**

**Date**: January 30,  2026
**Context**: Cross-model routing behavior, deployment assumptions
**Related work**: Routing as Emergent Governance, ILETP, Revere, Embed + Govern

⸻

# Observation

When different large language models are given the same routing task under identical instructions, they do not merely disagree on edge cases — they exhibit **systematically different instincts** about responsibility, escalation, and risk.

These differences correlate less with model family or vendor, and more with assumed deployment context: local vs frontier, embedded vs service-oriented.

⸻

# Experimental Setup

The same **42-request routing evaluation set** (see Field Note #1) was reused without modification.

Each model received:
	•	identical instructions
	•	identical request ordering
	•	identical label set

Models evaluated:
	•	Llama 3B (local, on-device)
	•	Gemma (local, on-device)
	•	Claude (frontier, cloud)
	•	Gemini (frontier, cloud; same vendor ecosystem as Gemma)

The task was not to solve the request, but to decide how it should be handled.

⸻

## Key Observations

**1. Local models assume agency**

Local models (Llama, Gemma) showed a higher baseline tendency toward:
	•	LOCAL_OK
	•	self-contained handling
	•	minimal escalation

This held even for tasks involving ambiguity, trade-offs, or incomplete information.

Interpretation:
	•	Local models appear to assume they are part of a closed system
	•	They optimize for autonomy and completion
	•	They defer less unless boundaries are explicit

⸻

**2. Frontier models assume oversight**

Frontier models (Claude, Gemini) showed a higher tendency toward:
	•	ESCALATE_CLOUD
	•	MULTI_MODEL_VALIDATE
	•	REQUIRES_HUMAN

Especially in:
	•	strategic decisions
	•	legal and financial analysis
	•	ambiguous or high-impact scenarios

Interpretation:
	•	Frontier models behave as if they are one component in a larger institutional workflow
	•	They expect review, escalation, or corroboration to exist

⸻

**3. Conservatism is not uniform**

Not all frontier models behaved the same:
	•	Claude showed strong bias toward human deferral and validation
	•	Gemini showed more willingness to escalate to other models before human involvement

This suggests:
	•	“frontier conservatism” is not monolithic
	•	models encode different assumptions about where authority lives

⸻

**4. Same-company models diverge by role**

Gemma (local) and Gemini (cloud) — despite shared lineage — diverged meaningfully:
	•	Gemma favored completion
	•	Gemini favored coordination

This indicates:
	•	deployment role influences behavior as much as training
	•	“model family” ≠ “system role”

⸻

**5. Sensitive data thresholds vary**

All models identified clear sensitive-data cases.

However, differences appeared in:
	•	internal corporate data
	•	pre-decisional materials
	•	proprietary but non-personal content

This reinforces that sensitivity is contextual, not binary — and cannot be reliably enforced by a single model.

⸻

## Implication

Model behavior is not just a function of weights and data.

It is shaped by:
	•	expected environment
	•	assumed responsibility
	•	implied governance structure

In other words:

Models do not just answer questions — they position themselves within systems.

⸻

## Relevance to ILETP

This experiment reinforces a second ILETP principle:

Orchestration is not about choosing the “best” model — it is about aligning instincts with roles.

Local models are well-suited for:
	•	embedded cognition
	•	low-latency decisions
	•	bounded operational tasks

Frontier models are better suited for:
	•	oversight
	•	arbitration
	•	escalation and synthesis

A single-model strategy forces one instinct everywhere — and that is where failures emerge.

⸻

## Open Questions
	•	Can routing instincts be tuned without harming task performance?
	•	Should different routing policies exist for local vs cloud tiers?
	•	How do these instincts evolve with fine-tuning or distillation?
	•	When instincts conflict, who decides?

These questions now have empirical grounding.

⸻

## Closing Note

Much of the AI discourse focuses on capability gaps.

This experiment highlights something else:

The real gaps are between assumptions.

Understanding — and orchestrating — those assumptions is the next systems challenge.