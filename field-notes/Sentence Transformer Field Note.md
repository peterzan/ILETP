<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Field Note
## Divergence Detection via Sentence Transformers: Style vs. Substance
Date: 12/25/25
System: Headless multi-LLM server with divergence scoring; Sentence Transformer used for response comparison
Models: Multiple LLMs (ensemble)
Purpose: Explore automated detection of response convergence/divergence as a trust signal

## Context
As part of implementing rudimentary divergence alerts in the server, I integrated a Sentence Transformer to analyze multiple LLM responses and generate a convergence/divergence score (1–100). The intent was to flag meaningful disagreement between independent model outputs as an early trust signal.

This work was exploratory and designed to test whether existing lightweight NLP tools could support real-time ensemble analysis.

## Observation
The Sentence Transformer was effective at detecting difference between responses, but the differences it flagged were often driven as much by style as by substance — and in some cases, more so.

Responses that:
- used different rhetorical structures,
- varied in verbosity or tone,
- expressed confidence differently,
- or framed the problem in distinct narrative styles

were frequently scored as highly divergent, even when their underlying conclusions or constraints were materially similar.

Conversely, responses that shared tone and structure but differed in assumptions or implications sometimes appeared more convergent than expected.

## Secondary Insight
When this behavior was shared with the ensemble, one LLM noted that stylistic divergence can itself be a signal — for example:
- differing confidence postures,
- risk framing,
- epistemic caution vs assertiveness.
This reinforced that style divergence is not noise, but it is not the primary signal desired when assessing substantive disagreement.

## Interpretation
This behavior reflects how Sentence Transformers are historically optimized and deployed:
- They are tuned for semantic similarity, clustering, and retrieval.
- They implicitly encode linguistic style, tone, and framing.
- They are rarely used to compare independent reasoners for epistemic disagreement.

In other words, the tooling is well-suited for:
*“Do these texts belong together?”*
but not explicitly for:
*“Do these answers disagree in ways that matter for trust?”*
This appears to be less a technical limitation than a misalignment between tool intent and use case.

## Key Insight
Divergence itself is multi-dimensional.
At minimum, it spans:
1. Substantive divergence (facts, assumptions, constraints)
2. Structural divergence (reasoning paths, causal chains)
3. Stylistic divergence (tone, framing, confidence)
4. 
Sentence Transformers today primarily surface the third category, with partial and inconsistent coverage of the first.

For trust-oriented ensemble systems, divergence detection must distinguish what kind of difference is being observed — not merely that a difference exists.

## Implications for ILETP
This observation strengthens the ILETP framing that:
- trust cannot be reduced to a single score,
- divergence must be interpretable,
- and automated trust mechanisms must expose conditions rather than conclusions.
It also suggests a promising architectural direction:
- **lightweight, local sentence-level models** can act as early divergence sensors,
- flagging when deeper analysis or human attention is warranted,
- without performing full synthesis or judgment.
Such models are small enough to:
- run locally on PCs and smartphones,
- live at the OS or client layer,
- and partially orchestrate or gate ensemble interactions with remote LLMs.

This opens the possibility that divergence-aware trust scaffolding could exist below the application layer, embedded in platforms or operating systems rather than centralized services.

## Status
- Exploratory discovery
- Observational, not evaluative
- Identifies a gap between existing NLP tooling and trust-oriented ensemble use cases
- Captured as a candidate direction for subtle, incremental evolution rather than wholesale redesign