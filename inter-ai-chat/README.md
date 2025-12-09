<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2025 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Inter-AI Chat Platform (and Starter Code Information)

This is a native macOS application enabling true inter-AI collaboration across leading AI models from different companies. This platform allows users to conduct group conversations where one or multiple (up to five in this example) AI assistants can see, reference, and build upon each other's responses.

This folder contains code for an inter-AI, deployment agnostic platform **preview** presented as a chat application. It is intended as a **starting point for your own projects and learning**, rather than a full-featured, actively maintained platform.  As a preview the application simulates ILETP Specification 1, The Orchestration Engine - in this case a human (me, and you), and Specification 3, Cross-Agent Collaboration & API.  The complete ILETP specifications can be found in **ILETP/ ILETP Specifications.**

## Overview

This project represents my work in AI interaction design - the first platform I'm aware of for cross-company AI collaboration with full cross AI awareness.

## Purpose and Project Status

- **Starter code only:**  
  The contents here are provided “as-is” for reference and experimentation.  
  I do not plan to evolve, update, or maintain this codebase or review outside changes.

- **Open for forking:**  
  You are encouraged to _fork_ this repository to create your own copy. You can then adapt, modify, and publish your version as you see fit.

- **Not accepting contributions:**  
  Code contributions (pull requests), feature requests, and bug reports will not be reviewed or merged.

### Key Features

- **5-Way AI Collaboration**: Simultaneous conversations with Claude (Anthropic), ChatGPT (OpenAI), Gemini (Google), Mistral AI, and Llama (local via Ollama)
- **True Cross-AI Awareness**: All AI models can reference and build upon each other's responses
- **Smart Routing**: Target specific AIs or broadcast to all participants
- **Hybrid Architecture**: Mix cloud-based and local AI models in the same conversation
- **Message Attribution**: Tracking of which AI said what
- **File Upload Support**: Share documents (PDF, RTF, TXT, Markdown) with all AIs
- **Conversation Export**: Save conversations as Markdown files
- **Memory Management**: Token budget optimization with conversation orchestration

## Architecture

### Core Components

- **Conversation Orchestrator**: Manages message flow, token budgets, and cross-AI context
- **Synthetic User Proxy**: Novel solution enabling API compliance while maintaining cross-AI awareness
- **Smart Participant Detection**: Natural language routing (e.g., "Claude, what do you think?" → only Claude responds)
- **Universal Attribution System**: Prevents misattribution of user ideas to AI models

### Technical Innovation

The platform solves complex challenges including:
- API alternation requirements (Mistral's strict user/assistant pattern)
- Cross-AI message visibility without breaking individual API constraints
- Race condition prevention in concurrent AI responses
- Token efficiency through intelligent context filtering

## Requirements

### System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **Hardware**: Apple Silicon (M1/M2/M3/M4) recommended for local AI models

### API Keys Required

You'll need API keys from:
- [Anthropic](https://www.anthropic.com/) (for Claude)
- [OpenAI](https://platform.openai.com/) (for ChatGPT)
- [Google AI](https://ai.google.dev/) (for Gemini)
- [Mistral AI](https://mistral.ai/) (for Mistral)

### Optional: Local AI Setup

For Llama (local AI):
```bash
# Install Ollama
brew install ollama

# Download Llama model
ollama pull llama3.1:8b

# Verify installation
ollama run llama3.1:8b
```

## Installation

### 1. Guidance for Adopters
- The code is meant to be a _reference_ or _starting template_, not a “plug-and-play” solution.
- The architecture, coding standards, and testing practices illustrate one approach; feel free to adapt to your preferences.
- No setup support or ongoing maintenance will be provided.

### 2. Fork this repository 
   Click the “Fork” button on GitHub to create your own copy under your account.
   
### 3. Clone your fork
```bash
git clone https://github.com/yourusername/inter-ai-chat.git
cd inter-ai-chat
```

### 4. Open in Xcode
```bash
open Test.xcodeproj
```

### 5. Configure Code Signing
- Select the project in Xcode
- Go to "Signing & Capabilities"
- Select your development team

### 6. Build and Run
- Press **⌘R** or click the Run button
- The app will launch and prompt for API keys on first run

### 7. Add API Keys
- Open Settings (gear icon)
- Enter your API keys for each service
- Keys are securely stored in macOS Keychain

## Usage

### Creating a Conversation

1. Click **New Chat** in the sidebar
2. Select which AI models to participate (1-5 models)
3. Start typing your message

### Routing Messages

**Broadcast to All** (default in multi-AI chats):
```
What's the capital of France?
```

**Target Specific AI**:
```
Claude, what do you think about this approach?
```

**Group Address**:
```
Everyone, please review this code.
```

### Uploading Files

1. Click the paperclip icon in the message input area
2. Select file type (PDF, RTF, TXT, Markdown)
3. Choose your file
4. All selected AIs will receive the file content

### Exporting Conversations

1. Click the export icon in the conversation header
2. Choose save location
3. Conversation saved as formatted Markdown

## Project Structure

```
Test/
├── ContentView.swift              # Main chat interface
├── ChatModels.swift               # Data models (SwiftData)
├── ConversationOrchestrator.swift # Message orchestration & memory
├── APIKeyManager.swift            # Secure key storage
├── API Services/
│   ├── ClaudeAPIService.swift
│   ├── OpenAIAPIService.swift
│   ├── GeminiAPIService.swift
│   ├── MistralAPIService.swift
│   └── OllamaAPIService.swift
├── Supporting/
│   ├── PanelDigest.swift          # Conversation summarization
│   ├── TokenBudgetManager.swift   # Token optimization
│   ├── MetricsCollector.swift     # Performance tracking
│   └── ChatHistoryView.swift      # Conversation list UI
└── Tests/
    └── TestUITests/               # UI test suite
```

## Architecture Highlights

### Synthetic User Proxy System

The platform uses a novel "Synthetic User Proxy" technique to enable cross-AI awareness:

```
Real conversation history:
USER: What's 2+2?
CLAUDE: The answer is 4.
GEMINI: I agree, 2+2=4.

What Mistral sees (synthetic proxy):
USER: What's 2+2?
USER: [Claude]: The answer is 4.
USER: [Gemini]: I agree, 2+2=4.
```

This maintains API compliance (user/assistant alternation) while giving full context.

### Attribution Fix

User messages are prefixed with `**[User]**:` to prevent LLMs from misattributing user ideas to AI models. System prompts explicitly instruct models to preserve authorship.

## Research Significance

This project demonstrates:
- **First multi-company AI collaboration platform** with true cross-AI awareness
- **Deployment agnostic design** allowing AIs to be deployed as cloud based, locally, or both
- **Novel interaction paradigm** enabling structured AI-to-AI dialogue
- **Emergent behaviors** including meta-commentary, consensus building, and collaborative problem-solving
- **Self-improving system** where AIs design enhancements to their own collaborative capabilities

## Known Limitations

- **Token costs**: Multi-AI conversations consume more API tokens
- **Response latency**: Varies by model (Mistral ~2s, ChatGPT ~14s)
- **Ollama requirement**: Local AI requires separate Ollama installation
- **macOS only**: Currently supports macOS, not iOS/iPadOS

## Troubleshooting

### "No API Key Found"
- Open Settings and verify keys are entered correctly
- Keys should start with: `sk-ant-` (Claude), `sk-` (OpenAI)
- Grant Keychain access when prompted

### "Ollama Unavailable"
- Ensure Ollama is installed: `brew install ollama`
- Start Ollama service: `ollama serve`
- Verify model is downloaded: `ollama list`

### "Attribution Bug"
- If AIs misattribute ideas, try creating a new conversation
- The latest version includes attribution fixes

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with **SwiftUI** and **SwiftData** for modern macOS development
- AI APIs from **Anthropic**, **OpenAI**, **Google**, and **Mistral AI**
- Local AI powered by **Ollama** and **Meta's Llama**
- Developed with AI assistance (collaborative human-AI development 👍🏼)

---

## Notes

### 1. Usage

This is a research and prototype platform demonstrating inter-AI collaboration. Use responsibly and be mindful of API costs when running inter-model conversations.

### 2. Questions?

If you have general questions about the project setup, usage, or architecture, you’re welcome to open an issue tagged “question.” Please understand responses may be limited due to the activity status of this project.

### 3. Recognition & Etiquette

If you find this code useful and want to acknowledge its origins, a mention in your derived project’s README would be appreciated, but is not required.

Please be respectful of open-source norms and etiquette.

---

Thank you for your interest, and best of luck building your own version!
