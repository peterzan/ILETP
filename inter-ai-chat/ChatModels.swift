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

// MARK: - AI Model Enumeration
enum AIModel: String, CaseIterable, Identifiable, Codable {
    case claude = "claude"
    case chatgpt = "chatgpt"
    case gemini = "gemini"
    case mistral = "mistral"
    case ollama = "ollama"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .chatgpt: return "ChatGPT"
        case .gemini: return "Gemini"
        case .mistral: return "Mistral"
        case .ollama: return "Llama"
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .ollama:
            return OllamaService.shared.isAvailable
        default:
            return true // All cloud models are available
        }
    }
    
    var comingSoonText: String? {
        return isAvailable ? nil : " (coming soon)"
    }
}

@Model
final class ChatSession {
    var id: UUID
    var title: String
    var createdAt: Date
    var lastMessageAt: Date
    var isPinned: Bool = false
    var pinnedAt: Date?
    
    // NEW: Store active AI models for this session
    var activeModelsRaw: [String] = ["claude"] // Default to Claude only
    
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage] = []
    
    // Computed property for type-safe access to active models
    var activeModels: [AIModel] {
        get {
            activeModelsRaw.compactMap { AIModel(rawValue: $0) }
        }
        set {
            activeModelsRaw = newValue.map { $0.rawValue }
        }
    }
    
    init(title: String = "New Chat", activeModels: [AIModel] = [.claude]) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.lastMessageAt = Date()
        self.activeModels = activeModels
    }
    
    var messageCount: Int {
        messages.count
    }
    
    var lastMessage: ChatMessage? {
        messages.sorted { $0.timestamp > $1.timestamp }.first
    }
    
    func togglePin() {
        isPinned.toggle()
        pinnedAt = isPinned ? Date() : nil
    }
}

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var timestamp: Date
    var isFromUser: Bool
    
    // NEW: Track which AI model sent this message (nil for user messages)
    var aiModel: String?
    
    // NEW: Track which turn this message belongs to (for context filtering)
    var turnIDString: String?
    
    @Relationship
    var session: ChatSession?
    
    // Computed property for type-safe access to AI model
    var model: AIModel? {
        get {
            guard let aiModel = aiModel else { return nil }
            return AIModel(rawValue: aiModel)
        }
        set {
            aiModel = newValue?.rawValue
        }
    }
    
    // Computed property for type-safe access to turn ID
    var turnID: UUID? {
        get {
            guard let turnIDString = turnIDString else { return nil }
            return UUID(uuidString: turnIDString)
        }
        set {
            turnIDString = newValue?.uuidString
        }
    }
    
    init(content: String, isFromUser: Bool, session: ChatSession? = nil, model: AIModel? = nil, turnID: UUID? = nil) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.isFromUser = isFromUser
        self.session = session
        self.model = model
        self.turnID = turnID
    }
}