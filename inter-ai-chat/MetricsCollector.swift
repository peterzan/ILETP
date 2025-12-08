//
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

// MARK: - Performance Metrics Data
struct TurnMetrics: Codable {
    let sessionId: UUID
    let turnNumber: Int
    let timestamp: Date
    let model: AIModel
    let latencyMs: Double
    let estimatedTokens: Int
    let actualTokens: Int?
    let wasTokenTruncated: Bool
    let wasDigestFallback: Bool
    let error: String?
    
    var tokenDriftPercentage: Double? {
        guard let actual = actualTokens, actual > 0 else { return nil }
        return abs(Double(estimatedTokens - actual) / Double(actual)) * 100
    }
}

// MARK: - Metrics Collector (Hybrid Storage)
@MainActor
class MetricsCollector: ObservableObject {
    
    // MARK: - In-Memory Storage (Recent Metrics)
    @Published private var recentMetrics: [TurnMetrics] = []
    private let maxRecentMetrics = 100 // Keep last 100 turns in memory
    private let snapshotInterval = 25 // Snapshot every 25 turns
    private var turnsSinceSnapshot = 0
    
    // MARK: - SwiftData Integration
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // MARK: - Metrics Recording
    
    /// Record metrics for a single AI response turn
    func recordTurn(
        sessionId: UUID,
        turnNumber: Int,
        model: AIModel,
        latencyMs: Double,
        estimatedTokens: Int,
        actualTokens: Int? = nil,
        wasTokenTruncated: Bool = false,
        wasDigestFallback: Bool = false,
        error: String? = nil
    ) {
        let metrics = TurnMetrics(
            sessionId: sessionId,
            turnNumber: turnNumber,
            timestamp: Date(),
            model: model,
            latencyMs: latencyMs,
            estimatedTokens: estimatedTokens,
            actualTokens: actualTokens,
            wasTokenTruncated: wasTokenTruncated,
            wasDigestFallback: wasDigestFallback,
            error: error
        )
        
        recentMetrics.append(metrics)
        
        // Maintain memory limit
        if recentMetrics.count > maxRecentMetrics {
            recentMetrics.removeFirst(recentMetrics.count - maxRecentMetrics)
        }
        
        // Check if snapshot needed
        turnsSinceSnapshot += 1
        if turnsSinceSnapshot >= snapshotInterval {
            snapshotToStorage()
        }
        
        // Log significant events
        if let drift = metrics.tokenDriftPercentage, drift > 15 {
            print("⚠️ MetricsCollector: High token drift (\(String(format: "%.1f", drift))%) for \(model.displayName)")
        }
        
        if wasTokenTruncated {
            print("✂️ MetricsCollector: Token truncation occurred for \(model.displayName)")
        }
        
        if wasDigestFallback {
            print("🔄 MetricsCollector: Digest fallback occurred for \(model.displayName)")
        }
        
        print("📊 MetricsCollector: Turn \(turnNumber) recorded for \(model.displayName) - \(String(format: "%.0f", latencyMs))ms")
    }
    
    // MARK: - Analytics & Health
    
    /// Get current system health metrics
    func getHealthSummary() -> HealthSummary {
        let recent50 = Array(recentMetrics.suffix(50))
        
        let timeouts = recent50.filter { $0.error?.contains("timeout") ?? false }.count
        let timeoutRate = recent50.isEmpty ? 0.0 : Double(timeouts) / Double(recent50.count) * 100
        
        let truncations = recent50.filter { $0.wasTokenTruncated }.count
        let truncationRate = recent50.isEmpty ? 0.0 : Double(truncations) / Double(recent50.count) * 100
        
        let avgLatency = recent50.isEmpty ? 0.0 : recent50.reduce(0) { $0 + $1.latencyMs } / Double(recent50.count)
        
        let tokenDrifts = recent50.compactMap { $0.tokenDriftPercentage }
        let avgTokenDrift = tokenDrifts.isEmpty ? 0.0 : tokenDrifts.reduce(0, +) / Double(tokenDrifts.count)
        
        return HealthSummary(
            timeoutRate: timeoutRate,
            truncationRate: truncationRate,
            avgLatencyMs: avgLatency,
            avgTokenDrift: avgTokenDrift,
            samplesCount: recent50.count
        )
    }
    
    /// Get model-specific health
    func getModelHealth(_ model: AIModel) -> ModelHealth {
        let modelMetrics = recentMetrics.filter { $0.model == model }
        let recent20 = Array(modelMetrics.suffix(20))
        
        let errors = recent20.filter { $0.error != nil }.count
        let truncations = recent20.filter { $0.wasTokenTruncated }.count
        let fallbacks = recent20.filter { $0.wasDigestFallback }.count
        
        let avgLatency = recent20.isEmpty ? 0.0 : recent20.reduce(0) { $0 + $1.latencyMs } / Double(recent20.count)
        
        // Determine health status
        let errorRate = recent20.isEmpty ? 0.0 : Double(errors) / Double(recent20.count)
        let health: DigestHealth = {
            if errorRate > 0.2 || avgLatency > 30000 { // >20% errors or >30s avg latency
                return .corrupted
            } else if truncations > 0 || fallbacks > 0 || avgLatency > 15000 {
                return .stale
            } else {
                return .healthy
            }
        }()
        
        return ModelHealth(
            health: health,
            avgLatencyMs: avgLatency,
            errorCount: errors,
            truncationCount: truncations,
            fallbackCount: fallbacks,
            samplesCount: recent20.count
        )
    }
    
    /// Get metrics for specific session
    func getSessionMetrics(_ sessionId: UUID) -> [TurnMetrics] {
        return recentMetrics.filter { $0.sessionId == sessionId }
    }
    
    // MARK: - Storage Management
    
    private func snapshotToStorage() {
        // TODO: Implement SwiftData persistence when modelContext is available
        // For now, just log the snapshot
        print("📊 MetricsCollector: Snapshot triggered - \(recentMetrics.count) metrics in memory")
        turnsSinceSnapshot = 0
        
        // Here we would save a subset to SwiftData for long-term analysis
        // But for Phase 1, in-memory is sufficient per AI collective specs
    }
    
    /// Force snapshot (app backgrounding, manual save, etc.)
    func forceSnapshot() {
        if !recentMetrics.isEmpty {
            snapshotToStorage()
        }
    }
    
    // MARK: - Debug & Export
    
    func getDebugSummary() -> String {
        let health = getHealthSummary()
        
        var summary = "=== Metrics Summary ===\n"
        summary += "Recent Samples: \(health.samplesCount)\n"
        summary += "Timeout Rate: \(String(format: "%.1f%%", health.timeoutRate))\n"
        summary += "Truncation Rate: \(String(format: "%.1f%%", health.truncationRate))\n"
        summary += "Avg Latency: \(String(format: "%.0f", health.avgLatencyMs))ms\n"
        summary += "Avg Token Drift: \(String(format: "%.1f%%", health.avgTokenDrift))\n"
        
        summary += "\n=== Model Health ===\n"
        for model in AIModel.allCases {
            let modelHealth = getModelHealth(model)
            summary += "\(model.displayName): \(modelHealth.health.description) (\(modelHealth.samplesCount) samples)\n"
        }
        
        return summary
    }
}

// MARK: - Health Summary Types
struct HealthSummary {
    let timeoutRate: Double
    let truncationRate: Double
    let avgLatencyMs: Double
    let avgTokenDrift: Double
    let samplesCount: Int
}

struct ModelHealth {
    let health: DigestHealth
    let avgLatencyMs: Double
    let errorCount: Int
    let truncationCount: Int
    let fallbackCount: Int
    let samplesCount: Int
}