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

// MARK: - Token Budget Manager
class TokenBudgetManager {
    
    // MARK: - Budget Configuration
    private let maxTokensPerModel: [AIModel: Int] = [
        .claude: 4000,    // Conservative limit for context
        .chatgpt: 3500,   // Account for GPT-5 limits
        .gemini: 4000,    // Gemini's context window
        .mistral: 3000    // More conservative due to strict alternation
    ]
    
    private let fallbackTokenLimit = 3000 // Safe default
    private let digestReservedTokens = 600 // Reserve space for digest
    
    // MARK: - Token Estimation
    
    /// Estimate tokens from text using character-based approximation
    func estimateTokens(from text: String) -> Int {
        // Basic estimation: ~4 characters per token for English text
        // This is conservative and will be calibrated against actual API usage
        return max(1, text.count / 4)
    }
    
    /// Get token budget for a specific model
    func getTokenBudget(for model: AIModel) -> Int {
        return maxTokensPerModel[model] ?? fallbackTokenLimit
    }
    
    /// Calculate available tokens after reserving space for digest
    func getAvailableTokens(for model: AIModel) -> Int {
        let totalBudget = getTokenBudget(for: model)
        return max(100, totalBudget - digestReservedTokens) // Minimum 100 tokens
    }
    
    // MARK: - Message Truncation
    
    /// Truncate messages to fit within token budget
    func truncateMessages(_ messages: [ChatMessage], for model: AIModel, digestTokens: Int = 0) -> ([ChatMessage], Bool) {
        let availableTokens = getAvailableTokens(for: model) - digestTokens
        var truncatedMessages: [ChatMessage] = []
        var currentTokenCount = 0
        var wasTruncated = false
        
        print("🔍 TokenBudgetManager: Truncating for \(model.displayName), budget: \(availableTokens) tokens")
        
        // Process messages in reverse (most recent first)
        let reversedMessages = messages.reversed()
        
        for message in reversedMessages {
            let messageTokens = estimateTokens(from: message.content)
            
            if currentTokenCount + messageTokens <= availableTokens {
                truncatedMessages.insert(message, at: 0) // Maintain chronological order
                currentTokenCount += messageTokens
            } else {
                wasTruncated = true
                print("🔍 TokenBudgetManager: Truncated \(messages.count - truncatedMessages.count) messages")
                break
            }
        }
        
        // Ensure we keep at least the last few messages for context
        if truncatedMessages.isEmpty && !messages.isEmpty {
            // Emergency fallback: keep last message even if over budget
            let lastMessage = messages.last!
            truncatedMessages = [lastMessage]
            wasTruncated = true
            print("⚠️ TokenBudgetManager: Emergency fallback - keeping last message only")
        }
        
        return (truncatedMessages, wasTruncated)
    }
    
    // MARK: - Token Drift Tracking
    
    private var tokenEstimateAccuracy: [String: (estimated: Int, actual: Int)] = [:]
    
    /// Record actual token usage for calibration
    func recordActualTokenUsage(requestId: String, estimated: Int, actual: Int) {
        tokenEstimateAccuracy[requestId] = (estimated: estimated, actual: actual)
        
        // Calculate drift percentage
        let driftPercentage = abs(Double(estimated - actual) / Double(actual)) * 100
        
        if driftPercentage > 15.0 {
            print("⚠️ TokenBudgetManager: Token estimate drift >15% - Estimated: \(estimated), Actual: \(actual)")
        }
        
        // Clean up old records (keep last 20)
        if tokenEstimateAccuracy.count > 20 {
            let oldestKeys = Array(tokenEstimateAccuracy.keys.prefix(5))
            oldestKeys.forEach { tokenEstimateAccuracy.removeValue(forKey: $0) }
        }
    }
    
    /// Get current estimation accuracy
    func getEstimationAccuracy() -> Double? {
        guard !tokenEstimateAccuracy.isEmpty else { return nil }
        
        let accuracyRatios = tokenEstimateAccuracy.values.map { record in
            Double(record.estimated) / Double(record.actual)
        }
        
        let averageRatio = accuracyRatios.reduce(0, +) / Double(accuracyRatios.count)
        return averageRatio
    }
    
    // MARK: - Budget Validation
    
    /// Check if a prompt would exceed token budget
    func validatePromptSize(content: String, messages: [ChatMessage], digest: String, for model: AIModel) -> (isValid: Bool, estimatedTokens: Int, budget: Int) {
        let contentTokens = estimateTokens(from: content)
        let messagesTokens = messages.reduce(0) { $0 + estimateTokens(from: $1.content) }
        let digestTokens = estimateTokens(from: digest)
        
        let totalEstimated = contentTokens + messagesTokens + digestTokens
        let budget = getTokenBudget(for: model)
        
        return (totalEstimated <= budget, totalEstimated, budget)
    }
    
    // MARK: - Debug Information
    
    func getDebugInfo(for model: AIModel) -> String {
        let budget = getTokenBudget(for: model)
        let available = getAvailableTokens(for: model)
        let accuracy = getEstimationAccuracy()
        
        var info = "Token Budget for \(model.displayName):\n"
        info += "  Total Budget: \(budget) tokens\n"
        info += "  Available (after digest): \(available) tokens\n"
        info += "  Reserved for Digest: \(digestReservedTokens) tokens\n"
        
        if let accuracy = accuracy {
            info += "  Estimation Accuracy: \(String(format: "%.1f%%", accuracy * 100))\n"
        }
        
        return info
    }
}
