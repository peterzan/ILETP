<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Field Note
## Semantic Anchoring and Divergence Sensitivity in Ensemble Responses
Date: 12/25/25
System: Local multi-LLM server (open-source models: Llama, Mixtral) with sentence-transformer–based divergence scoring
Purpose: Evaluate divergence behavior across open models under controlled prompt conditions

## Context
As part of testing divergence detection across proprietary and open-source LLMs (for enterprise on-prem deployment scenarios), a local server was configured using Llama and Mixtral. Divergence was computed using a sentence transformer to generate a normalized score indicating response convergence or divergence.
The goal was to understand how divergence scores behave when models are in full factual agreement but differ in verbosity or conversational style.

## Observation
For a simple factual question (“2 + 2”), both models produced correct and identical answers. However, earlier tests showed unexpectedly high divergence scores when one model (Mixtral) included conversational padding and meta-commentary, while the other (Llama) responded minimally.
After constraining the interaction such that both responses explicitly anchored on the core answer ("4"), the divergence score dropped significantly:
- Earlier case (style-heavy difference): divergence ≈ 0.73
- Anchored case (shared semantic nucleus): divergence ≈ 0.21
- 
This occurred even though Mixtral continued to add explanatory and stylistic commentary beyond the core answer.

## Key Insight
Sentence-transformer–based divergence scoring is highly sensitive to semantic anchoring.
Specifically:
- When responses share a clear, early semantic nucleus (e.g., identical factual tokens), similarity dominates the signal.
- Additional verbosity or stylistic padding contributes less to divergence once core alignment is established.
- Divergence is influenced not just by what is said, but where semantic alignment appears in the response.
- 
This demonstrates that divergence is not solely a model property — it is a conversation- and prompt-dependent phenomenon.

## Interpretation
This behavior indicates that embedding-based divergence detection:
- is elastic rather than binary,
- can be implicitly normalized through prompt constraints,
- and responds strongly to early semantic alignment.

The divergence score is therefore best understood as a composite signal, influenced by:
- content agreement,
- stylistic variance,
- response structure,
- and semantic positioning.
-
This explains why open-source models with more expressive or polite defaults may appear “more divergent” under unconstrained prompts, despite full substantive agreement.

## Implications for ILETP
This observation supports several architectural conclusions:
- Divergence detection can be steered, not merely observed.
- Lightweight prompt normalization (e.g., requiring a concise answer first) materially improves signal quality.
- Distinguishing between core-answer similarity and full-response similarity enables separation of:
    - substantive divergence
    - stylistic or posture divergence
    -
This reinforces the viability of using small, local sentence-transformer models as first-line divergence sensors, especially in enterprise or on-device settings.

## Broader Implication
The result suggests that trust-oriented ensemble systems should not rely on a single divergence metric. Instead, they should treat divergence as a layered signal whose meaning depends on interaction context.

Importantly, this insight was derived empirically through live system use, not theoretical modeling.

## Status
- Controlled experimental observation
- Confirms sensitivity of divergence metrics to semantic anchoring
- Provides practical guidance for reducing false positives in ensemble trust signaling
- Captured for future reference and architectural grounding