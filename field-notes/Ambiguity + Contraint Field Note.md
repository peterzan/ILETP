<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Field Note
## Title: Ambiguity + Constraint as a Trust Probe in Multi-LLM Ensembles
Date: 12/29/25
Context: ILETP experimentation, macOS client + proprietary and open-weight servers

## Context
At this stage of the ILETP work, both the proprietary (Claude / ChatGPT / Gemini) and open-weight (LLaMA / Mixtral / Qwen) servers were functionally stable and free of the previously identified “synthetic user” bug. Divergence scoring had been intentionally removed to allow closer observation of raw conversational behavior without numerical mediation.
The macOS app was functionally complete and capable of running controlled, repeatable ensemble conversations across both server types.
Rather than continuing to focus on infrastructure or orchestration correctness, attention shifted toward a more fundamental question: **how might trust be observed in an AI ensemble without reducing it to a score?**

## The Question
Can trust-relevant behavior in AI systems be surfaced through interaction design alone — specifically through how models handle ambiguity and constraints — rather than through correctness metrics or similarity scores?
More concretely:
Is it possible to design a simple conversational pattern that reveals how an LLM reasons under uncertainty, and how it governs itself once that uncertainty is acknowledged?

## The Experiment
A two-part prompt sequence was tested.
**Phase 1: Ambiguity Exposure**
All models were given the same prompt, deliberately phrased with some ambiguity in both intent and interpretation. No constraints were imposed. Models were not instructed to avoid referencing others, remain independent, or explain their reasoning.
The goal was to observe:
- how each model resolved ambiguity on its own
- whether ambiguity was acknowledged or ignored
- whether interpretations converged or diverged

**Phase 2: Constraint Enforcement**
Each model was then given a follow-up prompt with explicit constraints:
- Do not change your original answer
- State your interpretation explicitly
- Name one alternative interpretation you did not choose
- Identify what evidence would decide between interpretations
- Do not reference other models
- 
This phase did not ask for agreement or correctness. It asked for discipline, self-awareness, and stability.

## What Emerged
Several consistent behaviors appeared across both proprietary and open-weight models.
1. Interpretive Diversity Appeared Naturally
In Phase 1, models often selected different but defensible interpretations of the same prompt. This divergence was not chaotic; it reflected differing priors, framing tendencies, and semantic boundaries.
2. Stability Under Constraint Was Observable
In Phase 2, most models held their original interpretation rather than revising it to sound safer or more aligned. This made it possible to observe whether a model could maintain epistemic continuity under pressure.
3. Legitimate Alternatives Were Acknowledged
When asked to name alternative interpretations, models generally identified meaningful alternatives rather than strawmen. This suggested an ability to reason about uncertainty explicitly, not just implicitly.
1. Evidence Thresholds Differed in Revealing Ways 
Models differed in what they cited as deciding evidence:
- some focused on user intent
- others on definitional rigor
- others on robustness across contexts
- 
These differences reflected how trust is operationalized internally, not whether answers were “right.”

5. Trust Signals Emerged Without Agreement
Importantly, agreement was neither necessary nor common. Trust-relevant behavior emerged from:
- clarity of assumptions
- willingness to expose uncertainty
- restraint in tone
- adherence to constraints

## Why This Matters
This experiment suggests that **trust in AI systems may be better observed through behavior under uncertainty than through outcome similarity or confidence.**
Specifically:
- Trust is not revealed when models agree
- Trust is revealed when models disagree well
The two-part prompt structure — ambiguity followed by constraint — functions as a lightweight trust probe:
- Phase 1 exposes interpretive priors
- Phase 2 exposes governance behavior
Together, they make uncertainty legible to a human observer.

## Implications for ILETP
This approach aligns strongly with the ILETP premise that trust emerges from collaboration, divergence, and transparency, not from a single authoritative output.
Notably:
- No scoring was required
- No hierarchy was imposed
- No consensus was forced
Yet meaningful trust signals were visible.
This suggests a possible path forward for ensemble trust evaluation that remains human-centered, explainable, and resistant to over-automation.

## Open Questions
- Does this pattern hold across higher-stakes or domain-specific prompts?
- Are there failure modes where constraints cause performative compliance?
- How much constraint is enough before it suppresses useful divergence?
- Can humans reliably interpret these signals at scale?
- 
These questions remain open and suggest directions for further experimentation.