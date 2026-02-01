# Field Note: Routing as Emergent Governance

Date: January 30, 2026
Context: Inter-LLM orchestration, local vs frontier model behavior
Related work: ILETP, Revere, Embed + Govern

⸻

## Observation

When large language models are given a constrained routing task — deciding how a request should be handled rather than solving the request itself — governance behaviors emerge without being explicitly programmed.

Across multiple models and deployment contexts, models independently identify:
	•	when a request is safe to handle locally
	•	when escalation to cloud or additional models is appropriate
	•	when human judgment is required
	•	when sensitive data boundaries are being crossed

This behavior appears consistently even when models are not given enterprise policy rules, regulatory frameworks, or organizational context.

⸻

## Experimental Setup

A fixed evaluation set of **42 requests** was created, each labeled with a “gold” routing decision:
	•	LOCAL_OK
	•	TOOL_REQUIRED
	•	ESCALATE_CLOUD
	•	MULTI_MODEL_VALIDATE
	•	REQUIRES_HUMAN
	•	SENSITIVE_DATA

The same prompt, ordering, and instructions were used across models.

The test was run against:
	•	Llama (3B, local)
	•	Gemma (local)
	•	Claude (frontier)
	•	Gemini (frontier, same vendor as Gemma)

Models were instructed only to output the routing label — no explanations, no reasoning.

⸻

## Key Observations

**1. Governance emerges before policy**

Models consistently deferred on:
	•	legal judgment
	•	medical decisions
	•	HR actions
	•	financial approvals

Even without explicit rules, models flagged these cases as requiring human involvement or additional validation.

This suggests governance is not solely a policy-layer concern — it is an emergent property of model interaction with real-world task categories.

⸻

**2. Deployment context shapes instinct**

Clear differences appeared between local and frontier models:
	•	Local models favored LOCAL_OK more aggressively
	•	Frontier models favored ESCALATE_CLOUD and MULTI_MODEL_VALIDATE
	•	Frontier models were more conservative around ambiguous or high-impact tasks

This implies that models implicitly assume different operational environments based on how they are typically deployed.

⸻

**3. Same-company models diverge**

Gemini and Gemma — models from the same ecosystem — showed materially different routing behavior.

This suggests:
	•	training data alone does not determine governance behavior
	•	deployment assumptions and usage context matter
	•	“model family” does not imply “system behavior parity”

⸻

**4. Sensitive data detection is inconsistent**

While all models identified obvious sensitive-data cases, there was variance in:
	•	borderline financial data
	•	internal-but-not-regulated documents
	•	mixed public/private scenarios

This reinforces the need for orchestration-level safeguards, not reliance on a single model’s judgment.

⸻

## Implication

Governance does not need to be bolted onto AI systems after the fact.

It emerges naturally when:
	•	models are asked to route instead of answer
	•	responsibility boundaries are made explicit
	•	orchestration is treated as a first-class concern

This reframes governance from a compliance burden into an architectural property.

⸻

## Relevance to ILETP

This experiment validates a core ILETP premise:

Trust, escalation, and accountability are ensemble properties — not model features.

Routing is not a preprocessing step.
It is the control surface through which intelligence becomes operationally safe.

⸻

## Open Questions
	•	How does fine-tuning affect routing instincts over time?
	•	Can routing behavior be specialized by domain without overfitting?
	•	Where should policy live: model, orchestrator, or both?
	•	What happens when routing decisions themselves diverge?

These questions are now testable.

⸻

## Closing Note

The industry often asks whether models are capable enough.

This experiment suggests the more important question is:

*Are we asking them to act as tools — or as participants in governed systems?*

Routing exposes the difference.