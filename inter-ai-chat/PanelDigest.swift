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

// MARK: - Panel Digest Data Model
struct DigestData: Codable {
    let goal: String
    let keyDecisions: [String]
    let factsAndConstraints: [String]
    let openQuestions: [String]
    let version: Int
    let lastUpdatedTurn: Int
    let timestamp: Date
    
    var tokenCount: Int {
        // Rough token estimation: ~4 characters per token
        let allText = goal + keyDecisions.joined() + factsAndConstraints.joined() + openQuestions.joined()
        return allText.count / 4
    }
    
    static let empty = DigestData(
        goal: "",
        keyDecisions: [],
        factsAndConstraints: [],
        openQuestions: [],
        version: 0,
        lastUpdatedTurn: 0,
        timestamp: Date()
    )
}

// MARK: - Panel Digest Actor (Thread-Safe)
actor PanelDigest {
    private var currentDigest: DigestData = .empty
    private let maxTokens: Int = 500
    private let refreshInterval: Int = 5 // Auto-refresh every 5 turns initially
    
    // MARK: - Public Interface
    
    /// Get immutable snapshot of current digest
    func getSnapshot() -> DigestData {
        return currentDigest
    }
    
    /// Update digest with new information from a message turn
    func updateDigest(with summary: String, turnNumber: Int, isRefreshNeeded: Bool = false) {
        print("🔄 PanelDigest: Updating digest at turn \(turnNumber)")
        
        let newVersion = currentDigest.version + 1
        var updatedDigest = DigestData(
            goal: currentDigest.goal,
            keyDecisions: currentDigest.keyDecisions + [summary],
            factsAndConstraints: currentDigest.factsAndConstraints,
            openQuestions: currentDigest.openQuestions,
            version: newVersion,
            lastUpdatedTurn: turnNumber,
            timestamp: Date()
        )
        
        // Check if we need to prune for token limit
        if updatedDigest.tokenCount > maxTokens || isRefreshNeeded {
            updatedDigest = pruneDigest(updatedDigest)
        }
        
        currentDigest = updatedDigest
        print("🔄 PanelDigest: Updated to version \(newVersion), ~\(updatedDigest.tokenCount) tokens")
    }
    
    /// Force refresh/prune the digest
    func refreshDigest(turnNumber: Int) {
        print("🔄 PanelDigest: Force refresh at turn \(turnNumber)")
        currentDigest = pruneDigest(currentDigest, forceRefresh: true)
    }
    
    /// Check if digest needs refresh based on turn count
    func needsRefresh(currentTurn: Int) -> Bool {
        let turnsSinceLastUpdate = currentTurn - currentDigest.lastUpdatedTurn
        return turnsSinceLastUpdate >= refreshInterval
    }
    
    /// Get formatted digest for system prompt injection
    func getFormattedDigest() -> String {
        let digest = currentDigest
        
        guard !digest.goal.isEmpty || !digest.keyDecisions.isEmpty else {
            return "" // No digest to inject
        }
        
        var formatted = "\n--- Panel Digest (v\(digest.version)) ---\n"
        
        if !digest.goal.isEmpty {
            formatted += "Goal: \(digest.goal)\n"
        }
        
        if !digest.keyDecisions.isEmpty {
            formatted += "Key Decisions: \(digest.keyDecisions.joined(separator: "; "))\n"
        }
        
        if !digest.factsAndConstraints.isEmpty {
            formatted += "Constraints: \(digest.factsAndConstraints.joined(separator: "; "))\n"
        }
        
        if !digest.openQuestions.isEmpty {
            formatted += "Open Questions: \(digest.openQuestions.joined(separator: "; "))\n"
        }
        
        formatted += "--- End Digest ---\n"
        
        return formatted
    }
    
    /// Reset digest (for testing or corruption fallback)
    func reset() {
        print("🔄 PanelDigest: Reset to empty state")
        currentDigest = .empty
    }
    
    // MARK: - Private Methods
    
    private func pruneDigest(_ digest: DigestData, forceRefresh: Bool = false) -> DigestData {
        print("🔄 PanelDigest: Pruning digest (current: ~\(digest.tokenCount) tokens)")
        
        var prunedDecisions = digest.keyDecisions
        var prunedConstraints = digest.factsAndConstraints
        
        // Strategy: Remove oldest entries first until under token limit
        while (estimateTokens(decisions: prunedDecisions, constraints: prunedConstraints, 
                             goal: digest.goal, questions: digest.openQuestions) > maxTokens && 
               (!prunedDecisions.isEmpty || !prunedConstraints.isEmpty)) {
            
            // Prioritize keeping recent decisions over old constraints
            if prunedConstraints.count > prunedDecisions.count {
                prunedConstraints.removeFirst()
            } else {
                prunedDecisions.removeFirst()
            }
        }
        
        let prunedDigest = DigestData(
            goal: digest.goal,
            keyDecisions: prunedDecisions,
            factsAndConstraints: prunedConstraints,
            openQuestions: digest.openQuestions,
            version: digest.version,
            lastUpdatedTurn: digest.lastUpdatedTurn,
            timestamp: Date()
        )
        
        print("🔄 PanelDigest: Pruned to ~\(prunedDigest.tokenCount) tokens")
        return prunedDigest
    }
    
    private func estimateTokens(decisions: [String], constraints: [String], 
                               goal: String, questions: [String]) -> Int {
        let allText = goal + decisions.joined() + constraints.joined() + questions.joined()
        return allText.count / 4 // Rough estimation
    }
}

// MARK: - Digest Health Status
enum DigestHealth {
    case healthy    // Under token limit, recent update
    case stale      // Needs refresh
    case corrupted  // Fallback needed
    
    var color: String {
        switch self {
        case .healthy: return "green"
        case .stale: return "yellow" 
        case .corrupted: return "red"
        }
    }
    
    var description: String {
        switch self {
        case .healthy: return "Digest healthy"
        case .stale: return "Digest needs refresh"
        case .corrupted: return "Digest corrupted - using fallback"
        }
    }
}
