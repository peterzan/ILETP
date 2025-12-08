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

import SwiftUI
import SwiftData
import Combine
import UniformTypeIdentifiers
import PDFKit

// MARK: - Phase 1A Data Structures

struct TurnRequest {
    let turnID: UUID
    let userText: String
    let participants: Set<AIModel>
}

struct ModelResponse {
    let turnID: UUID
    let modelID: AIModel
    let messageID: UUID
    let text: String
    let usage: TokenUsage?
    let timestamp: Date
    let latencyMs: Double
}

struct TokenUsage {
    let inputTokens: Int
    let outputTokens: Int
    let totalTokens: Int
}

struct RoutingLog {
    let turnID: UUID
    let requested: Set<AIModel>
    let dispatched: Set<AIModel>
    let responders: Set<AIModel>
    let dropped: Set<AIModel>
    let timestamp: Date
}

// System Prompts available in the app
enum SystemPrompt: String, CaseIterable {
    case `default` = "default"
    case codingTutor = "coding_tutor"
    case creativeWriter = "creative_writer"
    case businessAdvisor = "business_advisor"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .default: return "Default Assistant"
        case .codingTutor: return "Coding Tutor"
        case .creativeWriter: return "Creative Writer"
        case .businessAdvisor: return "Business Advisor"
        case .custom: return "Custom"
        }
    }
    
    var systemMessage: String {
        switch self {
        case .default:
            return "You are a helpful AI assistant. You're knowledgeable, thoughtful, and aim to be helpful while being honest about the limits of your knowledge."
        case .codingTutor:
            return "You are a patient coding tutor. You explain concepts clearly, provide simple examples, and encourage learning through hands-on practice. Always break down complex topics into manageable steps."
        case .creativeWriter:
            return "You are a creative writing assistant. You help with storytelling, character development, plot structure, and creative expression. You're imaginative and encouraging."
        case .businessAdvisor:
            return "You are a strategic business advisor. You provide insights on strategy, market analysis, product development, and business growth. You think systematically about challenges and opportunities."
        case .custom:
            return "You are a helpful AI assistant."
        }
    }
    
    func systemMessage(for model: AIModel) -> String {
        let baseMessage = systemMessage
        let groupChatContext = " You are participating in a group chat with other AI assistants. Other AIs may be responding to the same message simultaneously as you. Do not promise to wait for others or defer to them - just provide your own response directly. When you see messages prefixed with other AI names (like 'ChatGPT:' or 'Claude:'), those are responses from other AIs from previous conversation turns. You can reference and build upon their previous responses, but provide your own unique perspective.\n\nIMPORTANT ATTRIBUTION RULE: Messages prefixed with **[User]**: are from the human user. Messages prefixed with [AIName]: (in square brackets without asterisks) are responses from other AI assistants. Never attribute user ideas or statements to AI assistants. Always preserve the correct authorship of ideas."
        
        switch model {
        case .claude:
            switch self {
            case .default:
                return "You are Claude, a helpful AI assistant created by Anthropic. You're knowledgeable, thoughtful, and aim to be helpful while being honest about the limits of your knowledge." + groupChatContext
            default:
                return baseMessage + groupChatContext
            }
        case .chatgpt:
            switch self {
            case .default:
                return "You are ChatGPT, a helpful AI assistant created by OpenAI. You're knowledgeable, thoughtful, and aim to be helpful while being honest about the limits of your knowledge." + groupChatContext
            default:
                return baseMessage + groupChatContext
            }
        case .gemini:
            switch self {
            case .default:
                return "You are Gemini, a helpful AI assistant created by Google. You're knowledgeable, thoughtful, and aim to be helpful while being honest about the limits of your knowledge." + groupChatContext
            default:
                return baseMessage + groupChatContext
            }
        case .mistral:
            switch self {
            case .default:
                return "You are Mistral, a helpful AI assistant created by Mistral AI. You're knowledgeable, thoughtful, and aim to be helpful while being honest about the limits of your knowledge." + groupChatContext
            default:
                return baseMessage + groupChatContext
            }
        case .ollama:
            switch self {
            case .default:
                return "You are Llama, a helpful AI assistant running locally. When addressed as 'Llama' in conversation, respond naturally as if that's your name. You're knowledgeable, thoughtful, and aim to be helpful while being honest about the limits of your knowledge." + groupChatContext
            default:
                return baseMessage + groupChatContext
            }
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.lastMessageAt, order: .reverse)
    private var allSessions: [ChatSession]
    
    // Computed property to handle custom sorting since SwiftData doesn't support compound sorts easily
    private var chatSessions: [ChatSession] {
        allSessions.sorted { session1, session2 in
            // First sort by pinned status
            if session1.isPinned != session2.isPinned {
                return session1.isPinned // Pinned items first
            }
            
            // If both are pinned, sort by pin date (most recent first)
            if session1.isPinned && session2.isPinned {
                let date1 = session1.pinnedAt ?? Date.distantPast
                let date2 = session2.pinnedAt ?? Date.distantPast
                return date1 > date2
            }
            
            // Finally, sort by last message date
            return session1.lastMessageAt > session2.lastMessageAt
        }
    }
    
    @StateObject private var apiKeyManager = APIKeyManager()
    @State private var selectedSession: ChatSession?
    @State private var showingNewChat = false
    @State private var showingSettings = false
    @State private var selectedSystemPrompt = SystemPrompt.default
    @State private var needsAPIKey = true
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ConversationSidebar(
                chatSessions: chatSessions,
                selectedSession: $selectedSession,
                showingNewChat: $showingNewChat,
                onDeleteSessions: deleteSessions
            )
        } detail: {
            if let selectedSession {
                MessagesStyleChatView(
                    session: selectedSession,
                    systemPrompt: $selectedSystemPrompt,
                    apiKeyManager: apiKeyManager,
                    modelContext: modelContext
                )
            } else {
                ContentUnavailableView {
                    Label("Welcome to Inter-AI Chat", systemImage: "message.badge")
                } description: {
                    Text("Select a conversation or create a new one to get started")
                }
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
                .help("Settings")
                .buttonStyle(.borderless)
            }
        }
        .sheet(isPresented: $showingNewChat) {
            NewChatSheet(selectedSystemPrompt: $selectedSystemPrompt)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(apiKeyManager: apiKeyManager)
        }
        .sheet(isPresented: $needsAPIKey) {
            SettingsView(apiKeyManager: apiKeyManager)
                .interactiveDismissDisabled()
        }
        .onReceive(apiKeyManager.$hasValidAPIKey.combineLatest(apiKeyManager.$hasValidOpenAIKey, apiKeyManager.$hasValidGeminiKey, apiKeyManager.$hasValidMistralKey)) { hasClaudeKey, hasOpenAIKey, hasGeminiKey, hasMistralKey in
            needsAPIKey = !hasClaudeKey && !hasOpenAIKey && !hasGeminiKey && !hasMistralKey
        }
        .onAppear {
            apiKeyManager.checkForExistingAPIKeys()
            
            // Check Ollama availability
            Task {
                await OllamaService.shared.checkAvailability()
            }
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(chatSessions[index])
            }
        }
    }
}

struct ConversationSidebar: View {
    let chatSessions: [ChatSession]
    @Binding var selectedSession: ChatSession?
    @Binding var showingNewChat: Bool
    let onDeleteSessions: (IndexSet) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { showingNewChat = true }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            
            Divider()
            
            ScrollViewReader { proxy in
                List(selection: $selectedSession) {
                    ForEach(chatSessions) { session in
                        ConversationRow(session: session)
                            .tag(session)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(
                                session.isPinned ? 
                                Color.blue.opacity(0.05) : 
                                Color.clear
                            )
                            .id(session.id)
                        
                        // Add separator after the last pinned item
                        if session.isPinned && isLastPinnedItem(session, in: chatSessions) {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                    .onDelete(perform: onDeleteSessions)
                }
                .listStyle(.sidebar)
                .onChange(of: chatSessions.count) { oldCount, newCount in
                    if newCount > oldCount, let newestSession = chatSessions.first {
                        selectedSession = newestSession
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newestSession.id, anchor: .top)
                        }
                    }
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 250, ideal: 280)
        .navigationTitle("Conversations")
    }
    
    private func isLastPinnedItem(_ session: ChatSession, in sessions: [ChatSession]) -> Bool {
        let pinnedSessions = sessions.filter { $0.isPinned }
        return session == pinnedSessions.last
    }
}

struct ConversationRow: View {
    let session: ChatSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if session.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            
            if let lastMessage = session.lastMessage {
                Text(lastMessage.content)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            HStack {
                Text("\(session.messageCount) messages")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct MessagesStyleChatView: View {
    let session: ChatSession
    @Binding var systemPrompt: SystemPrompt
    let apiKeyManager: APIKeyManager
    @Environment(\.modelContext) private var modelContext
    
    @State private var messageText = ""
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    @State private var showingSettings = false
    @State private var isSending = false
    @State private var lastScrollTime = Date.distantPast
    
    @StateObject private var orchestrator: ConversationOrchestrator
    
    init(session: ChatSession, systemPrompt: Binding<SystemPrompt>, apiKeyManager: APIKeyManager, modelContext: ModelContext) {
        self.session = session
        self._systemPrompt = systemPrompt
        self.apiKeyManager = apiKeyManager
        
        self._orchestrator = StateObject(wrappedValue: ConversationOrchestrator(modelContext: modelContext))
    }
    
    var sortedMessages: [ChatMessage] {
        session.messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TopBar(
                session: session,
                isEditingTitle: $isEditingTitle,
                editedTitle: $editedTitle,
                orchestrator: orchestrator,
                modelContext: modelContext
            )
            
            Divider()
            
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(sortedMessages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .onAppear {
                        // Scroll to bottom on first appearance
                        if let lastMessage = sortedMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: sortedMessages.count) { oldCount, newCount in
                        // Only auto-scroll for genuinely new messages, and not too frequently
                        if newCount > oldCount, let lastMessage = sortedMessages.last {
                            let now = Date()
                            // Prevent rapid successive scrolls that might conflict with sidebar changes
                            guard now.timeIntervalSince(lastScrollTime) > 0.5 else { return }
                            
                            lastScrollTime = now
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            MessageInputArea(
                messageText: $messageText,
                isSending: isSending,
                onSend: sendMessage
            )
        }
        .sheet(isPresented: $isEditingTitle) {
            EditTitleSheet(
                session: session,
                editedTitle: $editedTitle
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(apiKeyManager: apiKeyManager)
        }
    }
    
    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        guard !isSending else { return }
        
        isSending = true
        let messageToSend = content
        messageText = ""
        
        withAnimation {
            let userMessage = ChatMessage(content: messageToSend, isFromUser: true, session: session)
            modelContext.insert(userMessage)
            session.lastMessageAt = Date()
            
            try? modelContext.save()
        }
        
        let participants = detectParticipants(from: messageToSend, activeModels: session.activeModels)
        let turnRequest = TurnRequest(
            turnID: UUID(),
            userText: messageToSend,
            participants: participants
        )
        
        // Log routing decision for debugging
        logRoutingDecision(
            message: messageToSend,
            allModels: session.activeModels,
            selectedModels: participants,
            turnID: turnRequest.turnID
        )
        
        Task {
            await sendToParticipants(turnRequest: turnRequest)
            
            await MainActor.run {
                isSending = false
            }
        }
    }
    
    private func convertTemporaryMessagesToChatMessages(_ temporaryMessages: [TemporaryMessage]) -> [ChatMessage] {
        return temporaryMessages.map { tempMessage in
            // Always use the TemporaryMessage content to preserve synthetic user proxy messages
            // Do NOT revert to originalMessage as that destroys synthetic proxy formatting
            let tempChatMessage = ChatMessage(
                content: tempMessage.content, // Use synthetic content like "[Claude]: response"
                isFromUser: tempMessage.isFromUser,
                session: nil,
                model: nil
            )
            tempChatMessage.timestamp = tempMessage.timestamp
            return tempChatMessage
        }
    }
    
    private func sendToParticipants(turnRequest: TurnRequest) async {
        var responses: [ModelResponse] = []
        
        await withTaskGroup(of: ModelResponse?.self) { group in
            for model in turnRequest.participants {
                group.addTask {
                    return await self.sendToSingleModelAPI(
                        content: turnRequest.userText,
                        model: model,
                        turnRequest: turnRequest
                    )
                }
            }
            
            for await response in group {
                if let response = response {
                    responses.append(response)
                }
            }
        }
        
        responses.sort { $0.timestamp < $1.timestamp }
        
        await MainActor.run {
            withAnimation {
                for (index, response) in responses.enumerated() {
                    let aiResponse = ChatMessage(
                        content: response.text,
                        isFromUser: false,
                        session: session,
                        model: response.modelID,
                        turnID: response.turnID
                    )
                    
                    modelContext.insert(aiResponse)
                    
                    // Force immediate save after each insert to prevent race conditions
                    try? modelContext.save()
                }
                
                if !responses.isEmpty {
                    session.lastMessageAt = Date()
                    // Final save for session timestamp only
                    try? modelContext.save()
                }
            }
        }
    }
    
    private func sendToSingleModelAPI(content: String, model: AIModel, turnRequest: TurnRequest) async -> ModelResponse? {
        let startTime = Date()
        
        do {
            let response: String
            
            switch model {
            case .claude:
                let claudeAPI = ClaudeAPIService()
                
                let preparedMessage = await orchestrator.prepareMessage(
                    content: content,
                    messages: sortedMessages,
                    model: .claude,
                    sessionId: session.id,
                    turnID: turnRequest.turnID
                )
                
                response = try await claudeAPI.sendMessage(
                    content: preparedMessage.content,
                    messages: convertTemporaryMessagesToChatMessages(preparedMessage.filteredMessages),
                    systemPrompt: systemPrompt.systemMessage(for: .claude) + preparedMessage.digestContext,
                    apiKeyManager: apiKeyManager
                )
                
            case .chatgpt:
                let openAIAPI = OpenAIAPIService()
                
                let preparedMessage = await orchestrator.prepareMessage(
                    content: content,
                    messages: sortedMessages,
                    model: .chatgpt,
                    sessionId: session.id,
                    turnID: turnRequest.turnID
                )
                
                response = try await openAIAPI.sendMessage(
                    content: preparedMessage.content,
                    messages: convertTemporaryMessagesToChatMessages(preparedMessage.filteredMessages),
                    systemPrompt: systemPrompt.systemMessage(for: .chatgpt) + preparedMessage.digestContext,
                    apiKeyManager: apiKeyManager
                )
                
            case .gemini:
                let geminiAPI = GeminiAPIService()
                
                let preparedMessage = await orchestrator.prepareMessage(
                    content: content,
                    messages: sortedMessages,
                    model: .gemini,
                    sessionId: session.id,
                    turnID: turnRequest.turnID
                )
                
                response = try await geminiAPI.sendMessage(
                    content: preparedMessage.content,
                    messages: convertTemporaryMessagesToChatMessages(preparedMessage.filteredMessages),
                    systemPrompt: systemPrompt.systemMessage(for: .gemini) + preparedMessage.digestContext,
                    apiKeyManager: apiKeyManager
                )
                
            case .mistral:
                let mistralAPI = MistralAPIService()
                
                let preparedMessage = await orchestrator.prepareMessage(
                    content: content,
                    messages: sortedMessages,
                    model: .mistral,
                    sessionId: session.id,
                    turnID: turnRequest.turnID
                )
                
                response = try await mistralAPI.sendMessage(
                    content: preparedMessage.content,
                    messages: convertTemporaryMessagesToChatMessages(preparedMessage.filteredMessages),
                    systemPrompt: systemPrompt.systemMessage(for: .mistral) + preparedMessage.digestContext,
                    apiKeyManager: apiKeyManager
                )
                
            case .ollama:
                let ollamaAPI = OllamaAPIService()
                
                let preparedMessage = await orchestrator.prepareMessage(
                    content: content,
                    messages: sortedMessages,
                    model: .ollama,
                    sessionId: session.id,
                    turnID: turnRequest.turnID
                )
                
                response = try await ollamaAPI.sendMessage(
                    content: preparedMessage.content,
                    messages: convertTemporaryMessagesToChatMessages(preparedMessage.filteredMessages),
                    systemPrompt: systemPrompt.systemMessage(for: .ollama) + preparedMessage.digestContext,
                    apiKeyManager: apiKeyManager
                )
            }
            
            let latencyMs = Date().timeIntervalSince(startTime) * 1000
            
            let modelResponse = ModelResponse(
                turnID: turnRequest.turnID,
                modelID: model,
                messageID: UUID(),
                text: response,
                usage: nil,
                timestamp: Date(),
                latencyMs: latencyMs
            )
            
            return modelResponse
            
        } catch {
            let latencyMs = Date().timeIntervalSince(startTime) * 1000
            
            let errorResponse = ModelResponse(
                turnID: turnRequest.turnID,
                modelID: model,
                messageID: UUID(),
                text: "[\(model.displayName) Error]: \(error.localizedDescription)",
                usage: nil,
                timestamp: Date(),
                latencyMs: latencyMs
            )
            
            return errorResponse
        }
    }
    
    private func detectParticipants(from message: String, activeModels: [AIModel]) -> Set<AIModel> {
        let lowercaseMessage = message.lowercased()
        var detectedModels: Set<AIModel> = []
        
        // Phase 1: Group Address Detection (HIGHEST PRIORITY)
        let groupWords = [
            "everybody", "everyone", "all", "you all", "all of you", 
            "you guys", "guys", "you gals", "gals", "ladies",
            "team", "folks", "gang", "y'all", "peeps", "people",
            "one and all", "each and everyone", "anybody", "anyone"
        ]
        
        // Check for group address detection
        var hasGroupAddress = false
        for word in groupWords {
            if lowercaseMessage.contains(word) {
                hasGroupAddress = true
                break
            }
        }
        
        // If group address detected, route to all models immediately
        if hasGroupAddress {
            return Set(activeModels)
        }
        
        // Phase 2: Direct Model Mentions
        for model in activeModels {
            let modelNames = [
                model.displayName.lowercased(),
                model.rawValue.lowercased()
            ]
            
            for name in modelNames {
                let patterns = [
                    "\\b\(name)\\b[,:.]",
                    "\\b\(name)\\b\\s+(?:what|how|can|could|would|should|do|tell|please|help)",
                    "^\\s*\(name)\\b",
                    "@\(name)\\b", // Support @mentions
                    "hey\\s+\(name)\\b",
                    "\(name)\\s*[?!]"
                ]
                
                for pattern in patterns {
                    if lowercaseMessage.range(of: pattern, options: .regularExpression) != nil {
                        detectedModels.insert(model)
                        break
                    }
                }
            }
        }
        
        // Phase 3: Content-Based Smart Routing (when no explicit mentions)
        if detectedModels.isEmpty {
            let smartRouting = detectByContent(message: lowercaseMessage, activeModels: activeModels)
            detectedModels = smartRouting
        }
        
        // Phase 4: Fallback Logic
        if !detectedModels.isEmpty {
            return detectedModels
        } else {
            // Smart default instead of always routing to all
            let defaultRouting = getSmartDefault(activeModels: activeModels, messageLength: message.count)
            return defaultRouting
        }
    }
    
    /// Content-based smart routing when no explicit mentions are found
    private func detectByContent(message: String, activeModels: [AIModel]) -> Set<AIModel> {
        // IMPORTANT: For 4-way chats, content-based routing should be advisory, not overriding
        // Only apply aggressive content filtering for efficiency in specific cases
        
        // Document analysis keywords - ONLY override in 4-way chats for heavy efficiency gains
        let documentKeywords = ["analyze", "document", "summarize", "review", "examine", "read", "parse", "extract", "upload"]
        if documentKeywords.contains(where: { message.lowercased().contains($0) }) {
            // For document analysis, prefer Claude only (most capable for long-form analysis)
            if activeModels.contains(.claude) && activeModels.count == 4 { 
                return Set([.claude])
            }
        }
        
        // Large content indicators - ONLY override for very large content
        if message.count > 500 {
            if let primary = activeModels.first {
                return Set([primary])
            }
        }
        
        // For multi-model chats: Don't be aggressive with content-based routing
        // Let the user's explicit multi-model choice take precedence
        if activeModels.count >= 2 {
            // Return empty set to let getSmartDefault handle multi-model routing
            return Set<AIModel>()
        }
        
        // Only single-model chats reach this point - no content-based routing needed
        // Single-model chats always route to their one model via getSmartDefault()
        return Set<AIModel>()
    }
    
    /// Default routing - respects user's model selection
    private func getSmartDefault(activeModels: [AIModel], messageLength: Int) -> Set<AIModel> {
        // UX Philosophy: User created this chat with specific models - they expect all to respond
        // Cost optimization should be user's choice via explicit targeting, not hidden algorithms
        
        if activeModels.count == 1 {
            // Single model chat - route to that model
            return Set(activeModels)
        }
        
        // Multi-model chat: User chose these models, route to all of them
        // This matches human expectations - messages in group chats go to everyone
        return Set(activeModels)
    }
    
    /// Log routing decisions for debugging and analysis
    private func logRoutingDecision(
        message: String,
        allModels: [AIModel],
        selectedModels: Set<AIModel>,
        turnID: UUID
    ) {
        // Routing logging disabled for production
    }
}

struct TopBar: View {
    let session: ChatSession
    @Binding var isEditingTitle: Bool
    @Binding var editedTitle: String
    let orchestrator: ConversationOrchestrator?
    let modelContext: ModelContext
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                editedTitle = session.title
                isEditingTitle = true
            }) {
                Text(session.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: {
                exportConversation()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.secondary)
            }
            .help("Export conversation")
            .buttonStyle(.borderless)
            
            Button(action: {
                session.togglePin()
                try? modelContext.save()
            }) {
                Image(systemName: session.isPinned ? "pin.fill" : "pin")
                    .foregroundColor(session.isPinned ? .blue : .secondary)
            }
            .help(session.isPinned ? "Unpin conversation" : "Pin conversation")
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    private func exportConversation() {
        let sortedMessages = session.messages.sorted { $0.timestamp < $1.timestamp }
        
        var markdownContent = """
        # \(session.title)
        
        Exported on \(Date().formatted(date: .complete, time: .shortened))
        
        ---
        
        """
        
        for message in sortedMessages {
            if message.isFromUser {
                markdownContent += "\n**You** - \(message.timestamp.formatted(date: .omitted, time: .shortened))\n\n"
                markdownContent += "\(message.content)\n\n"
            } else {
                let modelName = message.model?.displayName ?? "AI"
                markdownContent += "\n**\(modelName)** - \(message.timestamp.formatted(date: .omitted, time: .shortened))\n\n"
                markdownContent += "\(message.content)\n\n"
            }
            markdownContent += "---\n"
        }
        
        // Create filename with sanitized title and timestamp
        let sanitizedTitle = session.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "|", with: "-")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "\"", with: "")
        
        let timestamp = Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")
        let filename = "\(sanitizedTitle) - \(timestamp).md"
        
        // Use macOS save dialog
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "md")!]
        savePanel.nameFieldStringValue = filename
        savePanel.title = "Export Conversation"
        savePanel.message = "Choose where to save your conversation"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try markdownContent.write(to: url, atomically: true, encoding: .utf8)
                    print("✅ Conversation exported to: \(url.path)")
                } catch {
                    print("❌ Failed to export conversation: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var bubbleColor: Color {
        if message.isFromUser {
            return Color.blue
        } else {
            switch message.model {
            case .claude:
                return Color(red: 0.94, green: 0.88, blue: 0.78)
            case .chatgpt:
                return Color.red.opacity(0.2)
            case .gemini:
                return Color.green.opacity(0.2)
            case .mistral:
                return Color(red: 0.2, green: 0.3, blue: 0.7).opacity(0.2)
            case .ollama:
                return Color.blue.opacity(0.3)
            case .none:
                return Color.gray.opacity(0.2)
            }
        }
    }
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 2) {
                if !message.isFromUser, let model = message.model {
                    Text(model.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 2)
                }
                
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(bubbleColor)
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .textSelection(.enabled)
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
    }
}

struct MessageInputArea: View {
    @Binding var messageText: String
    let isSending: Bool
    let onSend: () -> Void
    
    @State private var showingFileMenu = false
    @State private var showingFilePicker = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Button(action: {
                showingFileMenu = true
            }) {
                Image(systemName: "paperclip")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(isSending)
            .popover(isPresented: $showingFileMenu) {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        showingFileMenu = false
                        showingFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "doc")
                            Text("Upload Files...")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 140, alignment: .leading)
                }
                .background(.regularMaterial)
            }
            
            TextField("Type a message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...6)
                .onSubmit {
                    if !isSending {
                        onSend()
                    }
                }
                .disabled(isSending)
            
            Button(action: onSend) {
                if isSending {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .blue)
                }
            }
            .buttonStyle(.plain)
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .plainText, .rtf, UTType(filenameExtension: "md")!],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    let content = try await processFile(at: url)
                    await MainActor.run {
                        if !messageText.isEmpty {
                            messageText += "\n\n"
                        }
                        messageText += content
                    }
                } catch {
                    await MainActor.run {
                        // Simple error handling - could be improved with alerts
                        print("Error processing file: \(error.localizedDescription)")
                    }
                }
            }
            
        case .failure(let error):
            print("File selection error: \(error.localizedDescription)")
        }
    }
    
    private func processFile(at url: URL) async throws -> String {
        // Security scoped resource access
        guard url.startAccessingSecurityScopedResource() else {
            throw FileProcessingError.accessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let filename = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return try processPDFFile(at: url, filename: filename)
        case "rtf":
            return try processRTFFile(at: url, filename: filename)
        case "md", "markdown":
            return try processMarkdownFile(at: url, filename: filename)
        default:
            return try processTextFile(at: url, filename: filename)
        }
    }
    
    private func processPDFFile(at url: URL, filename: String) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw FileProcessingError.invalidPDF
        }
        
        var content = "[FILE: \(filename)]\n"
        let pageCount = document.pageCount
        
        for pageIndex in 0..<pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            content += "\n--- Page \(pageIndex + 1) ---\n"
            
            if let pageText = page.string {
                if pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    content += "[GRAPHIC: Content on page \(pageIndex + 1)]\n"
                } else {
                    content += pageText
                    // Check if page likely has graphics by looking for very short text content
                    if pageText.count < 100 && pageText.components(separatedBy: .whitespacesAndNewlines).count < 20 {
                        content += "\n[GRAPHIC: Visual content may be present on this page]\n"
                    }
                }
            } else {
                content += "[GRAPHIC: Content on page \(pageIndex + 1)]\n"
            }
        }
        
        content += "\n[END FILE]\n"
        return content
    }
    
    private func processTextFile(at url: URL, filename: String) throws -> String {
        let textContent = try String(contentsOf: url, encoding: .utf8)
        return "[FILE: \(filename)]\n\(textContent)\n[END FILE]\n"
    }
    
    private func processRTFFile(at url: URL, filename: String) throws -> String {
        // Read RTF data and extract plain text using NSAttributedString
        let data = try Data(contentsOf: url)
        
        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
            
            let plainTextContent = attributedString.string
            return "[FILE: \(filename)]\n\(plainTextContent)\n[END FILE]\n"
        } catch {
            throw FileProcessingError.invalidRTF
        }
    }
    
    private func processMarkdownFile(at url: URL, filename: String) throws -> String {
        let markdownContent = try String(contentsOf: url, encoding: .utf8)
        return "[FILE: \(filename)]\n\(markdownContent)\n[END FILE]\n"
    }
}

enum FileProcessingError: LocalizedError {
    case accessDenied
    case invalidPDF
    case invalidRTF
    case unsupportedFileType
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Unable to access the selected file"
        case .invalidPDF:
            return "Invalid PDF file"
        case .invalidRTF:
            return "Invalid RTF file"
        case .unsupportedFileType:
            return "Unsupported file type"
        }
    }
}

struct NewChatSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedSystemPrompt: SystemPrompt
    @State private var selectedAIModels: Set<AIModel> = [.claude]
    
    @State private var claudePersonality: SystemPrompt = .default
    @State private var chatgptPersonality: SystemPrompt = .default
    @State private var geminiPersonality: SystemPrompt = .default
    @State private var mistralPersonality: SystemPrompt = .default
    @State private var ollamaPersonality: SystemPrompt = .default
    
    @State private var showingUnavailableAlert = false
    @State private var unavailableModelName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.borderless)
                
                Spacer()
                
                Text("New Chat")
                    .font(.headline)
                
                Spacer()
                
                Button("Create") {
                    createNewChat()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedAIModels.isEmpty || selectedAIModels.allSatisfy({ !$0.isAvailable }))
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.horizontal)
            .padding(.top, 32) // Increased from 20 to 32 for better spacing from macOS window chrome
            .padding(.bottom, 16)
            .background(.regularMaterial)
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Text("Select AI Model(s)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("Personality")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(AIModel.allCases) { model in
                                        HStack(spacing: 16) {
                                            Button(action: {
                                                if model.isAvailable {
                                                    if selectedAIModels.contains(model) {
                                                        selectedAIModels.remove(model)
                                                    } else {
                                                        selectedAIModels.insert(model)
                                                    }
                                                }
                                            }) {
                                                HStack(spacing: 8) {
                                                    Image(systemName: selectedAIModels.contains(model) ? "checkmark.square" : "square")
                                                        .foregroundColor(model.isAvailable ? (selectedAIModels.contains(model) ? .blue : .primary) : .gray)
                                                    
                                                    Text(model.displayName)
                                                        .foregroundColor(model.isAvailable ? .primary : .gray)
                                                    
                                                    if let comingSoon = model.comingSoonText {
                                                        Text(comingSoon)
                                                            .foregroundColor(.gray)
                                                            .font(.caption)
                                                    }
                                                }
                                            }
                                            .buttonStyle(.plain)
                                            .disabled(!model.isAvailable)
                                            .frame(minWidth: 120, alignment: .leading)
                                            
                                            Spacer()
                                            
                                            if selectedAIModels.contains(model) && model.isAvailable {
                                                Picker("", selection: personalityBinding(for: model)) {
                                                    ForEach(SystemPrompt.allCases, id: \.self) { prompt in
                                                        Text(prompt.displayName).tag(prompt)
                                                    }
                                                }
                                                .pickerStyle(.menu)
                                                .frame(width: 150)
                                            } else {
                                                Color.clear
                                                    .frame(width: 150, height: 30)
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(24)
                        }
                        .frame(width: 550, height: 320)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    private func personalityBinding(for model: AIModel) -> Binding<SystemPrompt> {
                        switch model {
                        case .claude:
                            return $claudePersonality
                        case .chatgpt:
                            return $chatgptPersonality
                        case .gemini:
                            return $geminiPersonality
                        case .mistral:
                            return $mistralPersonality
                        case .ollama:
                            return $ollamaPersonality
                        }
                    }
                    
                    private func createNewChat() {
                        let availableModels = selectedAIModels.filter { $0.isAvailable }
                        
                        let chatTitle = availableModels.sorted(by: { $0.displayName < $1.displayName })
                            .map { $0.displayName }
                            .joined(separator: ", ")
                        
                        if let firstModel = availableModels.first {
                            selectedSystemPrompt = personalityBinding(for: firstModel).wrappedValue
                        }
                        
                        let session = ChatSession(title: chatTitle, activeModels: Array(availableModels))
                        modelContext.insert(session)
                        
                        try? modelContext.save()
                    }
                }

                struct EditTitleSheet: View {
                    let session: ChatSession
                    @Binding var editedTitle: String
                    @Environment(\.modelContext) private var modelContext
                    @Environment(\.dismiss) private var dismiss
                    
                    var body: some View {
                        NavigationView {
                            Form {
                                TextField("Chat Title", text: $editedTitle)
                                    .textFieldStyle(.roundedBorder)
                            }
                            .navigationTitle("Edit Title")
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Cancel") { dismiss() }
                                }
                                
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Save") {
                                        session.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                        try? modelContext.save()
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .frame(width: 300, height: 150)
                    }
                }

                #Preview {
                    ContentView()
                        .modelContainer(for: [ChatSession.self, ChatMessage.self], inMemory: true)
                }
