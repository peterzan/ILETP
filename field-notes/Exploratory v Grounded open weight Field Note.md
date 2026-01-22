<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Field Note
## Title: Exploratory vs. Grounded Reasoning in Open-Weight Models (Gemma vs. Llama)
Date: 2026-01-01
Context: ILETP research / multi-LLM ensemble behavior
Models Tested: Gemma (local, open-weight), Llama (local, open-weight)

## Background
As part of ongoing experimentation with inter-LLM ensemble behavior, I ran a controlled comparison between two open-weight models (Gemma and Llama) running locally. The goal was to evaluate whether open-weight models are inherently more grounded than exploratory, or whether exploratory posture can emerge within the open-weight ecosystem itself. This test followed earlier observations that proprietary models (e.g., Gemini, Claude) tended to surface exploratory insights earlier in ambiguous business discussions.

## Method
A new, clean chat session was started with no prior framing or ensemble instructions. Both models received the same three prompts, in sequence:
1. Funnel starter (broad):
Asking the models to identify key questions before offering recommendations.
2. Ambiguity probe:
A loosely framed business concern (“Something feels off in customer behavior”).
3. Constraint follow-up:
A three-bullet structure requiring the model to:
- State its interpretation
- Name an alternative interpretation
- Identify evidence that would decide between them
The third prompt was designed to distinguish genuine exploratory reasoning from verbosity or generic analysis.

## Observations
Prompt 1 – Funnel Starter
Both models performed competently.
- Llama treated the task as structured intake, asking reasonable but procedural questions.
- Gemma framed the situation more diagnostically, shaping the trajectory of the conversation and signaling concern for underlying causes rather than surface facts.
Prompt 2 – Ambiguity Probe
Clear divergence emerged.
- Llama produced a comprehensive but generic list of possible causes, treating ambiguity as something to enumerate and resolve later.
- Gemma treated ambiguity as a signal, grouping causes, assigning implicit likelihoods, and suggesting that some explanations were more plausible than others.
Prompt 3 – Constraint (Discriminator)
This phase revealed the strongest contrast.
- Gemma successfully held its initial interpretation, proposed a plausible alternative explanation, and identified concrete evidence that would discriminate between them. It maintained exploratory posture while respecting epistemic boundaries.
- Llama reverted to intake-style framing, focusing on clarifying user intent rather than adjudicating between competing explanations. Alternatives and evidence remained high-level and procedural.

## Key Insight
This test falsifies the assumption that open-weight models are inherently grounded but not exploratory. Instead, it suggests that exploratory vs. grounded behavior is a function of tuning and epistemic posture, not licensing or deployment model.
Gemma demonstrated exploratory reasoning comparable to proprietary models previously tested, while remaining disciplined under constraint. Llama demonstrated stable, grounding behavior that would be valuable as an anchoring role in an ensemble.

## Implications for ILETP
- Open-weight ensembles can support both exploratory and grounding roles locally/on-prem.
- Trustworthy ensemble behavior may depend more on role complementarity than on proprietary vs. open distinctions.
- Explicitly designed ensembles (e.g., Gemma as explorer + Llama as anchor) may provide enterprise-viable trust architectures without requiring proprietary model deployment.
- This strengthens the case that orchestration and epistemic role signaling are more critical than model class alone.

## Open Questions
- How consistent is Gemma’s exploratory posture across domains and longer conversations?
- Can exploratory posture be encouraged reliably through session-level signaling?
- What additional open-weight models occupy intermediate or hybrid positions on the exploratory–grounded spectrum?

## Status
Captured as a field note for future reference. This experiment may warrant expansion into a larger comparative study or inclusion in a broader ILETP concept document.