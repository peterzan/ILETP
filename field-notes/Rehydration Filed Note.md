<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Field Note
## Inter-LLM Ensemble: Context Rehydration vs Live Continuity
Date: 12/21/25
System: Headless multi-LLM server (browser UI), no persistent memory
Models: Claude, ChatGPT, Gemini
Purpose: Observe how inter-LLM reasoning changes when prior context is reintroduced as an artifact rather than carried as live session state

## Context
While experimenting with a multi-LLM ensemble system that does not retain session memory, I conducted two related chats across consecutive days.
- Session 1: A live, exploratory conversation involving multiple LLMs discussing AI trust, divergence, collaboration, and ensemble behavior.
- Session 2: A new session started from a blank state, where the full transcript from Session 1 was reintroduced as context for all models.
The system design required this reset; persistence was intentionally not yet implemented.

## Observation
The two sessions exhibited distinct conversational dynamics, despite covering similar subject matter.

Session 1 (Live Continuity)
- Exploratory and open-ended
- Natural divergence and clarification between models
- Ideas developed incrementally through interaction
- Models responded as participants within a shared moment
Session 2 (Context Rehydration)
Interpretive and reflective
- Reduced divergence and faster convergence
- Models treated prior discussion as an external artifact
- Reasoning focused on summarization, synthesis, and narrative coherence
Rather than “continuing” the conversation, the models reasoned about it.

## Key Differences Observed
- Exploration vs Interpretation:
Live continuity encouraged exploration; transcript replay encouraged explanation.
- Divergence vs Stabilization:
Disagreement was more visible in the live session and diminished once context became text.
- Human as Continuity Layer:
The human participant (me) was the only true source of continuity across sessions; the models had no experiential memory.
- Memory as Artifact vs Memory as State:
Reintroduced transcripts functioned as evidence, not lived experience.

## Interpretation
This experiment highlighted a useful distinction:
- Context continuity supports sensemaking and divergence.
- Context rehydration supports synthesis and convergence.
From a trust perspective, this suggests that:
- How context is carried matters as much as what context is carried.
- Replaying history can unintentionally compress ambiguity.
- Forgetting and restarting may sometimes preserve epistemic openness.
This was not evidence of emergent intelligence, but it was a concrete example of how system design choices shape reasoning behavior.

## Why This Matters (Personal)
This observation reinforced my interest in AI trust systems that:
- make context transitions explicit,
- preserve visibility into uncertainty,
- and avoid collapsing disagreement too early.
It also validated the idea that trust is influenced by process and framing, not just output quality.

## Status
- Exploratory
- Observational, not conclusive
- Retained as a reference artifact alongside raw transcripts
