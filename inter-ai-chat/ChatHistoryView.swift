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

struct ChatHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatSession.lastMessageAt, order: .reverse) 
    private var chatSessions: [ChatSession]
    
    @State private var selectedSession: ChatSession?
    @State private var showingNewChat = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSession) {
                Section("Chat History") {
                    ForEach(chatSessions) { session in
                        ChatSessionRow(session: session)
                            .tag(session)
                    }
                    .onDelete(perform: deleteSessions)
                }
            }
            .navigationTitle("Chat History")
            .navigationSplitViewColumnWidth(min: 250, ideal: 300)
            .toolbar {
                ToolbarItem {
                    Button(action: { showingNewChat = true }) {
                        Label("New Chat", systemImage: "plus.message")
                    }
                }
            }
        } detail: {
            if let selectedSession {
                ChatDetailView(session: selectedSession)
            } else {
                ContentUnavailableView {
                    Label("Select a Chat", systemImage: "message")
                } description: {
                    Text("Choose a chat session to view the conversation")
                }
            }
        }
        .sheet(isPresented: $showingNewChat) {
            NewChatView()
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

struct ChatSessionRow: View {
    let session: ChatSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title)
                .font(.headline)
                .lineLimit(1)
            
            if let lastMessage = session.lastMessage {
                Text(lastMessage.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text("\(session.messageCount) messages")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Spacer()
                
                Text(session.lastMessageAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ChatDetailView: View {
    let session: ChatSession
    @Environment(\.modelContext) private var modelContext
    
    @State private var newMessageText = ""
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    
    var sortedMessages: [ChatMessage] {
        session.messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    var body: some View {
        VStack {
            // Chat messages
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(sortedMessages) { message in
                        ChatMessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Message input
            HStack {
                TextField("Type a message...", text: $newMessageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle(session.title)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Edit Title") {
                    editedTitle = session.title
                    isEditingTitle = true
                }
            }
        }
        .sheet(isPresented: $isEditingTitle) {
            NavigationView {
                Form {
                    TextField("Chat Title", text: $editedTitle)
                        .textFieldStyle(.roundedBorder)
                }
                .navigationTitle("Edit Title")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isEditingTitle = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            session.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            try? modelContext.save()
                            isEditingTitle = false
                        }
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        let content = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        withAnimation {
            let userMessage = ChatMessage(content: content, isFromUser: true, session: session)
            modelContext.insert(userMessage)
            
            // Simulate AI response (you'd replace this with actual AI integration)
            let aiResponse = ChatMessage(
                content: "This is a simulated response to: \"\(content)\"",
                isFromUser: false,
                session: session
            )
            modelContext.insert(aiResponse)
            
            session.lastMessageAt = Date()
            newMessageText = ""
            
            try? modelContext.save()
        }
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 2) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !message.isFromUser {
                Spacer(minLength: 50)
            }
        }
    }
}

struct NewChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var chatTitle = ""
    @State private var initialMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Chat Details") {
                    TextField("Chat Title (optional)", text: $chatTitle)
                    TextField("First Message (optional)", text: $initialMessage, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Chat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createNewChat()
                    }
                }
            }
        }
    }
    
    private func createNewChat() {
        let title = chatTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let session = ChatSession(title: title.isEmpty ? "New Chat" : title)
        modelContext.insert(session)
        
        if !initialMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let message = ChatMessage(content: initialMessage, isFromUser: true, session: session)
            modelContext.insert(message)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ChatHistoryView()
        .modelContainer(for: [ChatSession.self, ChatMessage.self], inMemory: true)
}