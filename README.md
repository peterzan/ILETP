# Inter-LLM Ensemble Trust Platform (ILETP™)
[![Release](https://img.shields.io/badge/release-v0.1.0-blue)](https://github.com/OWNER/REPO/releases) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)

Inter-LLM trust.  With the _**user**_ in control.

ILETP is an inter-LLM coordination platform concept that treats divergence as a **feature**, enabling models to interact, critique, and synthesize outputs with trust scoring and context continuity. It’s for people and organizations who need AI they can trust, not just hope, is right.

---

![inter-ai-chat screenshot](assets/inter-ai-chat-screenshot.png)
<p align="center">
  <em>Inter-LLM Chat UI: ChatGPT, Claude, Gemini, Llama and Mistral collaborating in real-time. Built in 24 hours via AI-directed development</em>
</p>

---

## The Problem

Current AI tools force users to:
- Trust single-model outputs without verification
- Manually copy/paste between different AI interfaces
- Accept "black box" decisions with no transparency
- Choose between providers with no comparison

**ILETP solves this** by enabling inter-model collaboration with built-in trust scoring and full transparency.

---

## ILETP Core Features
- Ensures multiple independent LLMs collaborate, evaluate each other, and reach trustworthy, auditable conclusions.
- Empowers user agency with real-time trust scores and escalation guidance; you decide when to trust AI vs. seek human expertise.
- Vendor-neutral, open, and model-agnostic design ensures compatibility with all major LLMs and deployment methods.

---

## ILETP Development Provenance

The included proof-of-concept or "preview" application was built entirely through AI-directed development, a collaborative process between a human product manager with no professional coding experience (me) and Claude (Anthropic), embedded in Apple Xcode 26.0.1.  Without Swift coding expertise, I provided requirements and design decisions while Claude proposed implementation strategies, refined the architecture, and wrote code, while we both debugged issues. This resulted in a functional inter-LLM chat application in approximately 24 hours of active development time.

The broader ILETP platform specifications and protocols (detailed in (detailed in **/ILETP Specifications**) were developed through collaborative discussions between myself and multiple AI models including Claude, ChatGPT (OpenAI), Gemini (Google), and Copilot (Microsoft).

---

## Why Open Source
The problems addressed here, validation, trust, divergence, and diagnostics are not proprietary challenges. They are industry-wide challenges.

Open sourcing this work:

- prevents vendor lock-in  
- establishes public prior art  
- encourages experimentation and collaboration  
- supports safety and transparency goals  
- enables extensions and integrations by the broader community  

ILETP is an open platform, not a product.

---

## Quick Start (This is a starter kit — you're encouraged to fork it)

ILETP includes example code for an inter-LLM chat interface and orchestration layer.  **This project is offered as a foundation for others to explore and build on.**  I am *not* actively maintaining feature updates at this time.

### How to begin:

1. **Fork this repo** — recommended for your own exploration and extensions  
2. Clone your fork and open the Xcode project  
3. Add API keys (Anthropic, OpenAI, Google, Mistral, optional local Llama via Ollama)  
4. Run the app and start experimenting with multi-LLM conversations  
5. Modify freely — forks, rewrites, and totally new directions are welcome

This repo is meant to be forked.  Think of it as a foundation, not a finished product — explore, adapt, extend.  If you create something interesting, I'd love to hear about it — but there is no expectation or requirement to contribute back upstream.

---

## Vision & Example Usage

The **why** of ILETP is contained in various documents (detailed in **/supporting-docs**) that assist understanding of the need for such a platform now.
Several example use cases (detailed in **/use-cases**) and an expanded use case (detailed in **/ILETP_UseCase_Test Tool Specs**) concept are included in the repo. These use cases are far from the only solutions that can be built by leveraging ILETP.  

---

## How to Contribute
I welcome help! If you want to contribute:

1. Read CONTRIBUTING.md and CODE_OF_CONDUCT.md.  
2. Look for issues labeled "good first issue" or "help wanted".  
3. Open a new issue to discuss larger changes before starting.

_**NOTE**_: I will not be maintaining the Inter-LLM chat application code or specifications.  Feel free to fork and use the initial work as the basis for your experimentation.

---

## Support & Contact
- Open an issue for bugs and feature requests.
- Essays and long-form writing by the author will be published via GitHub Pages after the initial public release.
- For direct contact: peter@iletp.org.

---

## Licensing
This repository uses two licenses:

- Code (source files): Apache License, Version 2.0 — see `LICENSE` in the repository root.
- Documentation and non-code content (vision, philosophy, business docs, etc.): Creative Commons Attribution 4.0 International (CC BY 4.0) — see `LICENSE-CC-BY-4.0.txt` in the repository root.

Per-file headers:
- Code files include an Apache SPDX header, e.g. `// SPDX-License-Identifier: Apache-2.0`.
- Markdown documentation files include a CC BY SPDX header as an HTML comment at the top,:
  `<!-- SPDX-License-Identifier: CC-BY-4.0 -->`
  `<!-- Copyright 2025 Peter Zan. Licensed under CC BY 4.0. See LICENSE-CC-BY-4.0.txt in the repository root. -->`

Notes:
- If you fork or reuse content, please keep existing copyright notices and license headers and follow the applicable license terms.
- GitHub may not show both licenses in the UI; this section is the canonical explanation for visitors.

---

## Finally...
This repository is a **living experiment** in trustworthy AI coordination. Everything here, code and docs, are intended to be **forked, extended, and improved**. If you build something interesting, evolve the specifications, or even build something on top of ILETP, I'd love to hear about it (open an issue or email peter@iletp.org).

**The goal isn't to create the "perfect" AI platform—it's to start a conversation about how we build AI systems that users can actually trust.**

Go make something great. 🚀



