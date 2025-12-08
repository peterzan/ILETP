// Copyright 2025 Peter Zan
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import SwiftData
import Combine

// MARK: - Conversation Orchestrator (Phase 1 Implementation)
@MainActor
class ConversationOrchestrator: ObservableObject {
    
    // MARK: - Core Components
    private let panelDigest = PanelDigest()
    private let tokenBudgetManager = TokenBudgetManager()
    @Published private var metricsCollector: MetricsCollector
    
    // MARK: - Configuration
    private let featureFlags = FeatureFlags()
    private var currentTurnNumber = 0
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext? = nil) {
        self.metricsCollector = MetricsCollector(modelContext: modelContext)
        print("🎯 ConversationOrchestrator: Initialized with Phase 1 memory management")
    }
    
    // MARK: - Main Orchestration Method
    
    /// Prepare and validate a message for API call with memory management
    func prepareMessage(
        content: String,
        messages: [ChatMessage],
        model: AIModel,
        sessionId: UUID,
        turnID: UUID
    ) async -> PreparedMessage {
        
        currentTurnNumber += 1
        let startTime = Date()
        
        print("🎯 ConversationOrchestrator: Preparing turn \(currentTurnNumber) for \(model.displayName)")
        print("🎯 ConversationOrchestrator: Processing all messages for cross-AI awareness")
        
        // Allow cross-AI awareness: Don't filter current turn messages yet
        // Let filterMessagesForModel() handle cross-AI synthetic proxy creation
        let filteredMessages = messages
        
        // Feature flag check
        guard featureFlags.isMemoryManagementEnabled else {
            print("🚫 ConversationOrchestrator: Memory management disabled - using legacy flow")
            // Convert ChatMessage to TemporaryMessage for consistency
            let temporaryMessages = filteredMessages.map { message in
                TemporaryMessage(
                    content: message.content,
                    isFromUser: message.isFromUser,
                    timestamp: message.timestamp,
                    originalMessage: message
                )
            }
            return PreparedMessage(
                content: content,
                filteredMessages: temporaryMessages,
                digestContext: "",
                metadata: MessageMetadata(
                    turnNumber: currentTurnNumber,
                    wasTruncated: false,
                    usedDigest: false,
                    estimatedTokens: 0
                )
            )
        }
        
        // Step 1: Get current digest
        let _ = await panelDigest.getSnapshot() // Not used in Phase 1, but ready for expansion
        let digestContext = await panelDigest.getFormattedDigest()
        let digestTokens = tokenBudgetManager.estimateTokens(from: digestContext)
        
        // Step 2: Filter messages for model-specific requirements (using filtered messages)
        let modelFilteredMessages = filterMessagesForModel(filteredMessages, model: model)
        
        // Step 3: Apply token budget truncation
        // Create temporary ChatMessage objects from TemporaryMessages to preserve synthetic content
        let chatMessagesForTruncation = modelFilteredMessages.map { tempMessage in
            let tempChatMessage = ChatMessage(
                content: tempMessage.content, // Preserve synthetic user proxy content
                isFromUser: tempMessage.isFromUser,
                session: nil,
                model: nil
            )
            tempChatMessage.timestamp = tempMessage.timestamp
            return tempChatMessage
        }
        let (truncatedChatMessages, wasTruncated) = tokenBudgetManager.truncateMessages(
            chatMessagesForTruncation,
            for: model,
            digestTokens: digestTokens
        )
        
        // Convert truncated ChatMessages back to TemporaryMessages
        let truncatedMessages = truncatedChatMessages.map { message in
            TemporaryMessage(
                content: message.content,
                isFromUser: message.isFromUser,
                timestamp: message.timestamp,
                originalMessage: message
            )
        }
        
        // Step 4: Validate final prompt size
        let validation = tokenBudgetManager.validatePromptSize(
            content: content,
            messages: truncatedChatMessages, // Use the ChatMessage version for validation
            digest: digestContext,
            for: model
        )
        
        // Step 5: Create prepared message
        let metadata = MessageMetadata(
            turnNumber: currentTurnNumber,
            wasTruncated: wasTruncated,
            usedDigest: !digestContext.isEmpty,
            estimatedTokens: validation.estimatedTokens
        )
        
        let preparedMessage = PreparedMessage(
            content: content,
            filteredMessages: truncatedMessages,
            digestContext: digestContext,
            metadata: metadata
        )
        
        let preparationTime = Date().timeIntervalSince(startTime) * 1000
        print("🎯 ConversationOrchestrator: Prepared in \(String(format: "%.1f", preparationTime))ms - \(validation.estimatedTokens)/\(validation.budget) tokens")
        
        return preparedMessage
    }
    
    /// Process successful AI response and update digest
    func processResponse(
        response: String,
        model: AIModel,
        sessionId: UUID,
        latencyMs: Double,
        metadata: MessageMetadata
    ) async {
        
        // Record metrics
        metricsCollector.recordTurn(
            sessionId: sessionId,
            turnNumber: metadata.turnNumber,
            model: model,
            latencyMs: latencyMs,
            estimatedTokens: metadata.estimatedTokens,
            actualTokens: nil, // TODO: Extract from API response if available
            wasTokenTruncated: metadata.wasTruncated,
            wasDigestFallback: false,
            error: nil
        )
        
        // Update digest if this was the last responder in the turn
        // For Phase 1: simplified approach - update digest from any substantial response
        if response.count > 100 { // Only update for substantial responses
            let summary = extractSummaryFromResponse(response, model: model)
            await panelDigest.updateDigest(
                with: summary,
                turnNumber: metadata.turnNumber,
                isRefreshNeeded: await panelDigest.needsRefresh(currentTurn: metadata.turnNumber)
            )
        }
        
        print("✅ ConversationOrchestrator: Processed response from \(model.displayName)")
    }
    
    /// Process API error and record metrics
    func processError(
        error: Error,
        model: AIModel,
        sessionId: UUID,
        latencyMs: Double,
        metadata: MessageMetadata
    ) async {
        
        metricsCollector.recordTurn(
            sessionId: sessionId,
            turnNumber: metadata.turnNumber,
            model: model,
            latencyMs: latencyMs,
            estimatedTokens: metadata.estimatedTokens,
            actualTokens: nil,
            wasTokenTruncated: metadata.wasTruncated,
            wasDigestFallback: false,
            error: error.localizedDescription
        )
        
        print("❌ ConversationOrchestrator: Recorded error for \(model.displayName) - \(error.localizedDescription)")
    }
    
    // MARK: - Health & Diagnostics
    
    /// Get overall system health
    func getSystemHealth() -> HealthSummary {
        return metricsCollector.getHealthSummary()
    }
    
    /// Get model-specific health for UI badges
    func getModelHealth(_ model: AIModel) -> ModelHealth {
        return metricsCollector.getModelHealth(model)
    }
    
    /// Get digest health status
    func getDigestHealth() async -> DigestHealth {
        let digest = await panelDigest.getSnapshot()
        
        if digest.version == 0 {
            return .healthy // Fresh start
        }
        
        let age = Date().timeIntervalSince(digest.timestamp)
        if age > 300 { // 5 minutes old
            return .stale
        }
        
        if digest.tokenCount > 450 { // Close to limit
            return .stale
        }
        
        return .healthy
    }
    
    // MARK: - Private Methods
    
    /// Apply model-specific message filtering - RETURNS TEMPORARY MESSAGES ONLY
    private func filterMessagesForModel(_ messages: [ChatMessage], model: AIModel) -> [TemporaryMessage] {
        // Apply synthetic user proxy for all models to enable cross-AI awareness
        // This converts other AI responses to tagged "user" messages for API compliance
        return messages.compactMap { message in
            if message.isFromUser {
                // Prefix real user messages to distinguish from synthetic AI messages
                // This prevents LLMs from misattributing user ideas to AI models
                let userPrefix = "**[User]**: "
                return TemporaryMessage(
                    content: userPrefix + message.content,
                    isFromUser: true,
                    timestamp: message.timestamp,
                    originalMessage: message
                )
            } else if message.model == model {
                // Keep this model's own responses as assistant messages
                return TemporaryMessage(
                    content: message.content,
                    isFromUser: false,
                    timestamp: message.timestamp,
                    originalMessage: message
                )
            } else if let otherModel = message.model {
                // Convert other AI responses to tagged "user" messages for ALL models
                // This maintains API alternation while giving full cross-AI context
                let taggedContent = "[\(otherModel.displayName)]: \(message.content)"
                
                // Create TEMPORARY synthetic message (NEVER persisted)
                return TemporaryMessage(
                    content: taggedContent,
                    isFromUser: true, // Synthetic user message for API compliance
                    timestamp: message.timestamp,
                    originalMessage: message
                )
            } else {
                // Skip messages without model attribution
                return nil
            }
        }
    }
    
    /// Extract key summary from AI response for digest
    private func extractSummaryFromResponse(_ response: String, model: AIModel) -> String {
        // Phase 1: Simple extraction - first sentence or key phrase
        let sentences = response.components(separatedBy: ". ")
        let firstSentence = sentences.first ?? response
        
        // Truncate to reasonable length for digest
        let maxLength = 100
        if firstSentence.count > maxLength {
            let index = firstSentence.index(firstSentence.startIndex, offsetBy: maxLength)
            return String(firstSentence[..<index]) + "..."
        }
        
        return firstSentence
    }
}

// MARK: - Data Types

struct PreparedMessage {
    let content: String
    let filteredMessages: [TemporaryMessage] // CRITICAL: Use TemporaryMessage, never ChatMessage
    let digestContext: String
    let metadata: MessageMetadata
}

struct MessageMetadata {
    let turnNumber: Int
    let wasTruncated: Bool
    let usedDigest: Bool
    let estimatedTokens: Int
}

// MARK: - Temporary Message Structure (API-Only, Never Persisted)
struct TemporaryMessage {
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let originalMessage: ChatMessage? // Reference to original for tracking
}

// MARK: - Feature Flags
struct FeatureFlags {
    let isMemoryManagementEnabled: Bool = true
    let isDryRunModeEnabled: Bool = false
    let isDigestLoggingEnabled: Bool = true
    
    // Future flags for Phase 2 & 3
    let isSelectiveParticipationEnabled: Bool = false
    let isAdvancedRetryEnabled: Bool = false
}
