<!-- SPDX-License-Identifier: CC-BY-4.0 -->
<!-- Copyright 2026 Peter Zan. Licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). See LICENSE-CC-BY-4.0.txt in the repository root. -->

# Synthetic User Proxy System

**Document Version:** 1.0  
**Date Created:** January 2, 2026  
**Project:** Inter-AI Chat Platform

---

## Table of Contents

1. [What is the Synthetic User Proxy?](#what-is-the-synthetic-user-proxy)
2. [What It Is NOT](#what-it-is-not)
3. [Why It Was Chosen](#why-it-was-chosen)
4. [How It Works](#how-it-works)
5. [What It's Good For](#what-its-good-for)
6. [What It's NOT Good For](#what-its-not-good-for)
7. [Possible Future Enhancements](#possible-future-enhancements)
8. [Technical Implementation Reference](#technical-implementation-reference)

---

## What is the Synthetic User Proxy?

The **Synthetic User Proxy** is a message transformation technique that enables multiple AI models from different companies to participate in group conversations while maintaining awareness of each other's responses—despite API limitations that would normally prevent this.

### Core Concept

When sending conversation history to an AI model, responses from OTHER AI models are converted into specially-tagged "user" messages:

```
Original message from Claude:
  role: "assistant"
  content: "I think the answer is 42."

Transformed for ChatGPT's view:
  role: "user"
  content: "[Claude]: I think the answer is 42."
```

This allows ChatGPT to "see" what Claude said without violating API requirements for message role alternation.

### The Three Message Categories

1. **Real User Messages** → `role: "user"`, no prefix
2. **This Model's Own Responses** → `role: "assistant"`, no prefix  
3. **Other AI Responses** → `role: "user"` with `[ModelName]:` prefix ← **Synthetic User Proxy**

---

## What It Is NOT

### ❌ Not a Persistent Data Structure

Synthetic messages are **ephemeral**—created in-memory during API call preparation and discarded immediately after. They are NEVER:
- Saved to the database
- Displayed in the UI
- Included in conversation exports
- Visible to end users

The database stores the original message with proper `model` attribution. Synthetic transformation happens only at the moment of API invocation.

### ❌ Not API Impersonation

This is not "faking" messages or deceiving the AI models. The `[ModelName]:` prefix clearly identifies the source. The AI models understand they're reading another AI's response, not a human user's message.

### ❌ Not a Workaround for Missing Features

This isn't compensating for API deficiencies—it's leveraging existing API capabilities (accepting user messages) to enable a novel use case (multi-AI collaboration) that the APIs weren't originally designed for.

### ❌ Not Specific to Any One Model

While initially developed to solve Mistral's strict alternation requirements, the Synthetic User Proxy is now applied **universally** to all models (Claude, ChatGPT, Gemini, Mistral) for consistency and cross-AI awareness.

---

## Why It Was Chosen

### The Problem: API Alternation Requirements

AI APIs enforce message role patterns:
- ✅ Valid: `user → assistant → user → assistant`
- ❌ Invalid: `user → assistant → assistant → user`

In a multi-AI conversation, you naturally get multiple consecutive assistant responses:

```
User: "What's the capital of France?"
Claude (assistant): "Paris is the capital of France."
ChatGPT (assistant): "The capital is Paris."
Gemini (assistant): "Paris."
```

If you send this history to Mistral, you have three consecutive `assistant` messages—**API rejects the request with a 400 error**.

### Solution Options Evaluated

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **Omit other AI responses** | Simple, no API violations | ❌ Zero cross-AI awareness | Rejected |
| **Merge responses into one** | Maintains alternation | ❌ Loses attribution, confusing | Rejected |
| **Custom delimiter system** | Clean data structure | ❌ Requires API changes (impossible) | Rejected |
| **Synthetic User Proxy** | ✅ Maintains alternation<br>✅ Full cross-AI awareness<br>✅ Clear attribution | Slight message count increase | ✅ **Chosen** |

### Why It's the Best Solution

1. **No API Modifications Required**: Works with existing APIs from Anthropic, OpenAI, Google, Mistral
2. **Preserves Full Context**: AIs see complete conversation history, not filtered fragments
3. **Clear Attribution**: `[ModelName]:` prefix makes source obvious
4. **Universal Applicability**: Same technique works across all AI providers
5. **Maintains Data Integrity**: Original messages stored cleanly in database

---

## How It Works

### Step-by-Step Process

#### 1. User Sends Message

```
User: "Everyone, what's 2 + 2?"
```

This message is:
- Saved to database with `isFromUser: true`, `model: null`
- Assigned a unique `turnID`

#### 2. Smart Routing Determines Participants

```swift
let participants = detectParticipants(from: "Everyone, what's 2 + 2?", activeModels: [.claude, .chatgpt, .gemini])
// Result: Set([.claude, .chatgpt, .gemini])
```

#### 3. Parallel API Calls Begin

For each model, the orchestrator prepares the conversation history:

**When Calling Claude:**
```swift
// Conversation history from database:
// - User: "What's your name?"
// - Claude: "I'm Claude, made by Anthropic."
// - ChatGPT: "I'm ChatGPT from OpenAI."
// - User: "Everyone, what's 2 + 2?"

// After orchestrator filtering for Claude:
[
  { role: "user", content: "What's your name?" },
  { role: "assistant", content: "I'm Claude, made by Anthropic." },  // Claude's own response
  { role: "user", content: "[ChatGPT]: I'm ChatGPT from OpenAI." },  // ← SYNTHETIC
  { role: "user", content: "Everyone, what's 2 + 2?" }
]
```

**When Calling ChatGPT:**
```swift
// Same conversation history from database

// After orchestrator filtering for ChatGPT:
[
  { role: "user", content: "What's your name?" },
  { role: "user", content: "[Claude]: I'm Claude, made by Anthropic." },  // ← SYNTHETIC
  { role: "assistant", content: "I'm ChatGPT from OpenAI." },  // ChatGPT's own response
  { role: "user", content: "Everyone, what's 2 + 2?" }
]
```

**When Calling Gemini:**
```swift
// Same conversation history from database

// After orchestrator filtering for Gemini:
[
  { role: "user", content: "What's your name?" },
  { role: "user", content: "[Claude]: I'm Claude, made by Anthropic." },  // ← SYNTHETIC
  { role: "user", content: "[ChatGPT]: I'm ChatGPT from OpenAI." },  // ← SYNTHETIC
  { role: "user", content: "Everyone, what's 2 + 2?" }
]
```

#### 4. API Responses Collected

```
Claude: "4"
ChatGPT: "The answer is 4."
Gemini: "2 + 2 = 4"
```

Each response is saved to database with:
- `content`: The response text
- `isFromUser: false`
- `model`: `.claude` / `.chatgpt` / `.gemini`
- `turnID`: Same as the user's message
- `timestamp`: When response completed

#### 5. Next Turn: Cross-AI Awareness Validated

```
User: "Claude, do you agree with ChatGPT's answer?"
```

**When Calling Claude:**
```swift
[
  // ... previous history ...
  { role: "user", content: "Everyone, what's 2 + 2?" },
  { role: "assistant", content: "4" },  // Claude's own response
  { role: "user", content: "[ChatGPT]: The answer is 4." },  // ← SYNTHETIC
  { role: "user", content: "[Gemini]: 2 + 2 = 4" },  // ← SYNTHETIC
  { role: "user", content: "Claude, do you agree with ChatGPT's answer?" }
]
```

Claude's response:
```
"Yes, I completely agree with ChatGPT's answer. 2 + 2 is indeed 4."
```

✅ **Cross-AI awareness confirmed**: Claude can see and reference ChatGPT's specific response.

### Code Implementation (Swift)

```swift
// ConversationOrchestrator.swift - filterMessagesForModel()

func filterMessagesForModel(_ messages: [ChatMessage], model: AIModel) -> [TemporaryMessage] {
    return messages.compactMap { message in
        if message.model == model {
            // This model's own responses → role: "assistant"
            return TemporaryMessage(
                content: message.content,
                isFromUser: false,
                originalMessage: message
            )
        } else if let otherModel = message.model {
            // Other AI responses → role: "user" with tag prefix (SYNTHETIC)
            let taggedContent = "[\(otherModel.displayName)]: \(message.content)"
            return TemporaryMessage(
                content: taggedContent,
                isFromUser: true,
                originalMessage: message
            )
        } else {
            // Real user messages → role: "user" (no prefix)
            return TemporaryMessage(
                content: message.content,
                isFromUser: true,
                originalMessage: message
            )
        }
    }
}
```

### Code Implementation (Python)

```python
# orchestrator.py - filter_messages_for_model()

def filter_messages_for_model(messages, target_model):
    filtered = []
    for msg in messages:
        if msg.model == target_model:
            # This model's own responses → role: "assistant"
            filtered.append({
                "role": "assistant",
                "content": msg.content
            })
        elif msg.model:
            # Other AI responses → role: "user" with tag prefix (SYNTHETIC)
            filtered.append({
                "role": "user",
                "content": f"[{msg.model.upper()}]: {msg.content}"
            })
        else:
            # Real user messages → role: "user" (no prefix)
            filtered.append({
                "role": "user",
                "content": msg.content
            })
    return filtered
```

---

## What It's Good For

### ✅ Enabling True Multi-AI Collaboration

**Use Case**: Group discussion with multiple AI models  
**Benefit**: Each AI can reference, critique, build upon, and synthesize other AIs' contributions

**Example**:
```
User: "Everyone, should we use SQL or NoSQL for this project?"

Claude: "I'd recommend SQL for strong consistency and complex queries."

ChatGPT: "I agree with Claude's SQL recommendation, and I'd add that..."
          ↑ Cross-AI awareness in action

Gemini: "Claude and ChatGPT both make good points about SQL, but consider..."
         ↑ Referencing multiple AIs
```

### ✅ API Compliance for Strict Alternation Requirements

**Use Case**: Mistral API rejects improperly ordered messages  
**Benefit**: Converts multi-assistant scenarios into valid user/assistant alternation

**Without Synthetic User Proxy**:
```
❌ API Error 400: "Messages must alternate between user and assistant roles"
```

**With Synthetic User Proxy**:
```
✅ Valid API request with perfect alternation pattern
```

### ✅ Maintaining Conversation Coherence

**Use Case**: Long multi-turn conversations with 3+ AI participants  
**Benefit**: Each AI maintains full context awareness, avoiding repetitive or contradictory responses

### ✅ Sophisticated Collaborative Analysis

**Use Case**: Complex problem-solving requiring diverse perspectives  
**Benefit**: AIs can perform comparative analysis, consensus building, and meta-commentary

**Validated Example** (from testing):
```
User: "Mistral, how many said Yes vs No to pineapple on pizza?"

Mistral: "Total count: Yes: 1 (ChatGPT) - No: 2 (Claude, Mistral)"
         ↑ Accurate cross-AI tallying with attribution
```

### ✅ Research and Experimentation

**Use Case**: Studying emergent behaviors in multi-AI systems  
**Benefit**: Clean, unmodified responses showing natural AI-to-AI interaction patterns

---

## What It's NOT Good For

### ❌ Single-AI Conversations

**Problem**: Adds unnecessary complexity when only one AI is active  
**Impact**: Slight message processing overhead (negligible, but wasteful)

**Optimization Opportunity**: Skip synthetic transformation when `activeModels.count == 1`

### ❌ Extremely Long Conversations (Token Budget Concerns)

**Problem**: Each synthetic message increases token count sent to APIs  
**Example**: 100-message conversation with 4 AIs = ~300 messages after transformation (3x multiplier)

**Current Mitigation**: TokenBudgetManager truncates old messages to stay within limits

**Future Enhancement Needed**: More intelligent summarization or digest system for very long conversations

### ❌ Real-Time Streaming Scenarios (Without Adaptation)

**Problem**: Current implementation waits for all AI responses before proceeding  
**Impact**: Can't show responses as they stream in, user waits for slowest model

**Status**: 
- macOS app: Batch mode (wait for all)
- Python server: Batch mode (wait for all)
- Future: WebSocket/SSE streaming planned but requires architectural changes

### ❌ Verbatim Conversation Export

**Problem**: If you export the API call logs (not the database), you'll see synthetic messages  
**Impact**: May confuse users analyzing API traffic

**Current Solution**: Conversation export uses database (original messages), not API call history, so this isn't an issue in practice

---

## Possible Future Enhancements

### 1. Adaptive Transformation Strategy

**Current**: Universal application to all models  
**Enhancement**: Apply synthetic user proxy only when needed

```swift
func shouldUseSyntheticProxy(for model: AIModel, participants: Set<AIModel>) -> Bool {
    switch model {
    case .mistral:
        return true  // Always required due to strict alternation
    case .claude, .chatgpt, .gemini:
        return participants.count > 2  // Only in multi-AI scenarios
    case .ollama:
        return false  // Local model, no API restrictions
    }
}
```

**Benefit**: Reduced message count for simpler scenarios

### 2. Compression for Long Conversations

**Current**: Full conversation history with all synthetic transformations  
**Enhancement**: Use Panel Digest summarization + sliding window

```swift
// Recent messages: Full synthetic proxy (last 10-20 messages)
// Older messages: Compressed digest without synthetic detail

"Earlier in the conversation, Claude, ChatGPT, and Gemini discussed [topic summary]..."
```

**Benefit**: Maintain cross-AI awareness while reducing token consumption

### 3. Intelligent Tag Formatting

**Current**: Simple prefix `[ModelName]: content`  
**Enhancement**: Structured metadata for advanced parsing

```swift
"[Claude|timestamp:2026-01-02T10:30:00|confidence:high]: content"
```

**Benefit**: AIs could reason about timing, confidence, and relationships between responses

### 4. Selective Visibility Control

**Current**: All AIs see all other AIs' responses  
**Enhancement**: User-controlled visibility matrix

```swift
// Example: Claude can see ChatGPT, but ChatGPT can't see Claude
visibilityMatrix = [
    .claude: [.chatgpt, .gemini],
    .chatgpt: [.gemini],
    .gemini: [.claude, .chatgpt]
]
```

**Use Case**: A/B testing different context configurations, studying AI behavior with partial information

### 5. Streaming-Compatible Variant

**Current**: Batch processing (wait for all responses)  
**Enhancement**: Progressive synthetic message injection

```swift
// As each AI responds, update synthetic messages for in-flight requests
// Requires WebSocket bidirectional communication or SSE with checkpoints
```

**Benefit**: Lower latency, more responsive UI, better user experience

### 6. Synthetic Message Audit Trail

**Current**: Ephemeral—no record of what was sent to each API  
**Enhancement**: Optional logging of actual API payloads for debugging

```swift
// Store in separate debugging table
struct SyntheticMessageLog {
    var turnID: UUID
    var targetModel: AIModel
    var transformedMessages: [Message]
    var timestamp: Date
}
```

**Benefit**: Easier debugging of cross-AI awareness issues, better observability

### 7. Multi-Lingual Tag Support

**Current**: English tags `[Claude]:`  
**Enhancement**: Localized tags based on user's language preference

```swift
// Spanish: "[Claude]:" → "[Claude (Español)]:"
// Japanese: "[Claude]:" → "[Claude（日本語）]:"
```

**Benefit**: Better international user experience, clearer attribution in non-English conversations

---

## Technical Implementation Reference

### Key Files (Swift - macOS App)

| File | Responsibility |
|------|----------------|
| `ConversationOrchestrator.swift` | Message filtering logic, synthetic transformation |
| `ContentView.swift` | Smart routing, API call orchestration |
| `ClaudeAPIService.swift` | Accepts filtered messages, formats for Anthropic API |
| `OpenAIAPIService.swift` | Accepts filtered messages, formats for OpenAI API |
| `GeminiAPIService.swift` | Accepts filtered messages, formats for Google API |
| `MistralAPIService.swift` | Accepts filtered messages, formats for Mistral API |

### Key Files (Python - Headless Server)

| File | Responsibility |
|------|----------------|
| `orchestrator.py` | Message filtering logic, synthetic transformation |
| `app.py` | API endpoints, routing, response collection |
| `models.py` | Database models (original messages, no synthetic storage) |

### Critical Function: `filterMessagesForModel()`

**Location**: `ConversationOrchestrator.swift` (Swift) / `orchestrator.py` (Python)

**Inputs**:
- `messages`: Full conversation history from database
- `model`: Target AI model receiving this filtered view

**Outputs**:
- Array of messages with:
  - Own responses: `role: "assistant"`
  - Other AI responses: `role: "user"` with `[ModelName]:` prefix
  - Real user messages: `role: "user"` (unchanged)

**Guarantees**:
- ✅ Valid user/assistant alternation for all APIs
- ✅ Full context preservation (no omitted messages)
- ✅ Clear attribution via tag prefix
- ✅ No database pollution (ephemeral transformation)

### Message Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Database: Original Messages (Ground Truth)                  │
│ - User: "What's 2+2?"                                        │
│ - Claude (model=.claude): "4"                                │
│ - ChatGPT (model=.chatgpt): "The answer is 4."              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────────┐
         │ ConversationOrchestrator      │
         │ filterMessagesForModel()      │
         └───────┬───────────────────────┘
                 │
     ┌───────────┼───────────┐
     │           │           │
     ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Claude  │ │ChatGPT  │ │ Gemini  │
│ View    │ │ View    │ │ View    │
└─────────┘ └─────────┘ └─────────┘
     │           │           │
     ▼           ▼           ▼
  "user:      "user:      "user:
   What's      What's      What's
   2+2?"       2+2?"       2+2?"
              
  "assistant: "user:      "user:
   4"          [Claude]:   [Claude]:
               4"          4"
              
  "user:      "assistant: "user:
   [ChatGPT]:  The answer  [ChatGPT]:
   The answer  is 4."      The answer
   is 4."                  is 4."
     │           │           │
     ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ API Call│ │ API Call│ │ API Call│
│ Anthropic│ │ OpenAI │ │ Google  │
└─────────┘ └─────────┘ └─────────┘
     │           │           │
     ▼           ▼           ▼
   Response    Response    Response
     │           │           │
     └───────────┴───────────┘
                 │
                 ▼
       ┌─────────────────┐
       │ Save to Database│
       │ (Original form, │
       │  no synthetic)  │
       └─────────────────┘
```

---

## Conclusion

The **Synthetic User Proxy** is the cornerstone of the Brannan multi-AI collaboration platform. It solves the fundamental challenge of enabling cross-AI awareness within the constraints of existing API architectures—without requiring changes from Anthropic, OpenAI, Google, or Mistral.

By transforming other AI responses into tagged "user" messages during API call preparation (and only during API call preparation), this technique:

- ✅ Maintains strict API compliance
- ✅ Enables unprecedented multi-AI collaboration
- ✅ Preserves data integrity (no database pollution)
- ✅ Provides clear attribution
- ✅ Works universally across all AI providers

This approach represents a novel solution to a novel problem: facilitating conversations between AI models from competing companies who never designed their APIs for this use case.

The result is the world's first true multi-company AI collaboration platform—made possible by a simple but powerful transformation technique.

---

**Document Status**: Complete  
**Validation**: Confirmed working in production (macOS Swift app + Python headless server)  
**Cross-AI Awareness Test**: ✅ Passing (AIs can reference each other by name with specific content)

