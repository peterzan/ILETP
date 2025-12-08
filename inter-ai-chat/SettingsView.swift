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

// MARK: - Settings/API Key Management View
struct SettingsView: View {
    @ObservedObject var apiKeyManager: APIKeyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var claudeKeyInput = ""
    @State private var openAIKeyInput = ""
    @State private var geminiKeyInput = ""
    @State private var mistralKeyInput = ""
    @State private var showingClaudeKey = false
    @State private var showingOpenAIKey = false
    @State private var showingGeminiKey = false
    @State private var showingMistralKey = false
    @State private var isValidatingClaude = false
    @State private var isValidatingOpenAI = false
    @State private var isValidatingGemini = false
    @State private var isValidatingMistral = false
    @State private var claudeValidationMessage = ""
    @State private var openAIValidationMessage = ""
    @State private var geminiValidationMessage = ""
    @State private var mistralValidationMessage = ""
    @State private var showingClaudeDeleteConfirmation = false
    @State private var showingOpenAIDeleteConfirmation = false
    @State private var showingGeminiDeleteConfirmation = false
    @State private var showingMistralDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title Bar
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.borderless)
                
                Spacer()
                
                Text("Settings")
                    .font(.headline)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.regularMaterial)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Claude API Key Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Claude API Key")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if apiKeyManager.hasValidAPIKey {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Connected")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Text("Enter your Anthropic API key to enable Claude conversations. Your key is stored securely in the macOS Keychain.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Claude API Key Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                if showingClaudeKey {
                                    TextField("sk-ant-...", text: $claudeKeyInput)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        .onSubmit {
                                            Task {
                                                await saveClaudeAPIKey()
                                            }
                                        }
                                } else {
                                    SecureField("sk-ant-...", text: $claudeKeyInput)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        .onSubmit {
                                            Task {
                                                await saveClaudeAPIKey()
                                            }
                                        }
                                }
                                
                                Button(action: { showingClaudeKey.toggle() }) {
                                    Image(systemName: showingClaudeKey ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.borderless)
                                
                                Button("Save") {
                                    Task {
                                        await saveClaudeAPIKey()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(claudeKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isValidatingClaude)
                            }
                            
                            if !claudeValidationMessage.isEmpty {
                                Text(claudeValidationMessage)
                                    .font(.caption)
                                    .foregroundColor(claudeValidationMessage.contains("Valid") || claudeValidationMessage.contains("✓") ? .green : .red)
                            }
                        }
                        
                        if apiKeyManager.hasValidAPIKey {
                            Button("Delete Claude API Key") {
                                showingClaudeDeleteConfirmation = true
                            }
                            .foregroundColor(.red)
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Divider()
                    
                    // OpenAI API Key Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("OpenAI API Key")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if apiKeyManager.hasValidOpenAIKey {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Connected")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Text("Enter your OpenAI API key to enable ChatGPT conversations. Your key is stored securely in the macOS Keychain.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // OpenAI API Key Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                if showingOpenAIKey {
                                    TextField("sk-...", text: $openAIKeyInput)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        .onSubmit {
                                            Task {
                                                await saveOpenAIAPIKey()
                                            }
                                        }
                                } else {
                                    SecureField("sk-...", text: $openAIKeyInput)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        .onSubmit {
                                            Task {
                                                await saveOpenAIAPIKey()
                                            }
                                        }
                                }
                                
                                Button(action: { showingOpenAIKey.toggle() }) {
                                    Image(systemName: showingOpenAIKey ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.borderless)
                                
                                Button("Save") {
                                    Task {
                                        await saveOpenAIAPIKey()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(openAIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isValidatingOpenAI)
                            }
                            
                            if !openAIValidationMessage.isEmpty {
                                Text(openAIValidationMessage)
                                    .font(.caption)
                                    .foregroundColor(openAIValidationMessage.contains("Valid") || openAIValidationMessage.contains("✓") ? .green : .red)
                            }
                        }
                        
                        if apiKeyManager.hasValidOpenAIKey {
                            Button("Delete OpenAI API Key") {
                                showingOpenAIDeleteConfirmation = true
                            }
                            .foregroundColor(.red)
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Divider()
                    
                    // Gemini API Key Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Gemini API Key")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if apiKeyManager.hasValidGeminiKey {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Connected")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Text("Enter your Google Gemini API key to enable Gemini conversations. Your key is stored securely in the macOS Keychain.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Gemini API Key Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                if showingGeminiKey {
                                    TextField("AIza...", text: $geminiKeyInput)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        .onSubmit {
                                            Task {
                                                await saveGeminiAPIKey()
                                            }
                                        }
                                } else {
                                    SecureField("AIza...", text: $geminiKeyInput)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        .onSubmit {
                                            Task {
                                                await saveGeminiAPIKey()
                                            }
                                        }
                                }
                                
                                Button(action: { showingGeminiKey.toggle() }) {
                                    Image(systemName: showingGeminiKey ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.borderless)
                                
                                Button("Save") {
                                    Task {
                                        await saveGeminiAPIKey()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(geminiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isValidatingGemini)
                            }
                            
                            if !geminiValidationMessage.isEmpty {
                                Text(geminiValidationMessage)
                                    .font(.caption)
                                    .foregroundColor(geminiValidationMessage.contains("Valid") || geminiValidationMessage.contains("✓") ? .green : .red)
                            }
                        }
                        
                        if apiKeyManager.hasValidGeminiKey {
                            Button("Delete Gemini API Key") {
                                showingGeminiDeleteConfirmation = true
                            }
                            .foregroundColor(.red)
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Divider()
                    
                    // Mistral API Key Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Mistral API Key")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if apiKeyManager.hasValidMistralKey {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Connected")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Text("Enter your Mistral AI API key to enable Mistral conversations. Your key is stored securely in the macOS Keychain.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Mistral API Key Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                if showingMistralKey {
                                    TextField("Enter Mistral API key...", text: $mistralKeyInput)
                                        .textFieldStyle(.roundedBorder)
                                        .textContentType(.password)
                                        .onSubmit {
                                            Task {
                                                await saveMistralAPIKey()
                                            }
                                        }
                                } else {
                                    SecureField("Enter Mistral API key...", text: $mistralKeyInput)
                                        .textFieldStyle(.roundedBorder)
                                        .textContentType(.password)
                                        .onSubmit {
                                            Task {
                                                await saveMistralAPIKey()
                                            }
                                        }
                                }
                                
                                Button(action: { showingMistralKey.toggle() }) {
                                    Image(systemName: showingMistralKey ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                
                                if isValidatingMistral {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Button("Save") {
                                        Task {
                                            await saveMistralAPIKey()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(mistralKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }
                            }
                            
                            if !mistralValidationMessage.isEmpty {
                                Text(mistralValidationMessage)
                                    .font(.caption)
                                    .foregroundColor(mistralValidationMessage.contains("Valid") || mistralValidationMessage.contains("✓") ? .green : .red)
                            }
                        }
                        
                        if apiKeyManager.hasValidMistralKey {
                            Button("Delete Mistral API Key") {
                                showingMistralDeleteConfirmation = true
                            }
                            .foregroundColor(.red)
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(24)
            }
        }
        .frame(width: 600, height: 700) // Increased height to accommodate Mistral section
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadExistingAPIKeys()
        }
        .confirmationDialog(
            "Delete Claude API Key",
            isPresented: $showingClaudeDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                apiKeyManager.deleteAPIKey()
                claudeKeyInput = ""
                claudeValidationMessage = ""
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove your Claude API key from the Keychain. You'll need to enter it again to use Claude.")
        }
        .confirmationDialog(
            "Delete OpenAI API Key",
            isPresented: $showingOpenAIDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                apiKeyManager.deleteOpenAIAPIKey()
                openAIKeyInput = ""
                openAIValidationMessage = ""
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove your OpenAI API key from the Keychain. You'll need to enter it again to use ChatGPT.")
        }
        .confirmationDialog(
            "Delete Gemini API Key",
            isPresented: $showingGeminiDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                apiKeyManager.deleteGeminiAPIKey()
                geminiKeyInput = ""
                geminiValidationMessage = ""
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove your Gemini API key from the Keychain. You'll need to enter it again to use Gemini.")
        }
        .confirmationDialog(
            "Delete Mistral API Key",
            isPresented: $showingMistralDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                apiKeyManager.deleteMistralAPIKey()
                mistralKeyInput = ""
                mistralValidationMessage = ""
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove your Mistral API key from the Keychain. You'll need to enter it again to use Mistral.")
        }
    }
    
    private func loadExistingAPIKeys() {
        // Load existing Claude key
        if let existingClaudeKey = apiKeyManager.getAPIKey() {
            // Show partial key for security (first 8 and last 4 characters)
            if existingClaudeKey.count > 12 {
                let start = String(existingClaudeKey.prefix(8))
                let end = String(existingClaudeKey.suffix(4))
                claudeKeyInput = "\(start)...\(end)"
            } else {
                claudeKeyInput = String(existingClaudeKey.prefix(8)) + "..."
            }
        }
        
        // Load existing OpenAI key
        if let existingOpenAIKey = apiKeyManager.getOpenAIAPIKey() {
            // Show partial key for security (first 8 and last 4 characters)
            if existingOpenAIKey.count > 12 {
                let start = String(existingOpenAIKey.prefix(8))
                let end = String(existingOpenAIKey.suffix(4))
                openAIKeyInput = "\(start)...\(end)"
            } else {
                openAIKeyInput = String(existingOpenAIKey.prefix(8)) + "..."
            }
        }
        
        // Load existing Gemini key
        if let existingGeminiKey = apiKeyManager.getGeminiAPIKey() {
            // Show partial key for security (first 8 and last 4 characters)
            if existingGeminiKey.count > 12 {
                let start = String(existingGeminiKey.prefix(8))
                let end = String(existingGeminiKey.suffix(4))
                geminiKeyInput = "\(start)...\(end)"
            } else {
                geminiKeyInput = String(existingGeminiKey.prefix(8)) + "..."
            }
        }
        
        // Load existing Mistral key
        if let existingMistralKey = apiKeyManager.getMistralAPIKey() {
            // Show partial key for security (first 8 and last 4 characters)
            if existingMistralKey.count > 12 {
                let start = String(existingMistralKey.prefix(8))
                let end = String(existingMistralKey.suffix(4))
                mistralKeyInput = "\(start)...\(end)"
            } else {
                mistralKeyInput = String(existingMistralKey.prefix(8)) + "..."
            }
        }
    }
    
    private func saveClaudeAPIKey() async {
        isValidatingClaude = true
        claudeValidationMessage = "Validating..."
        
        let isValid = await apiKeyManager.validateAPIKey(claudeKeyInput)
        
        if isValid {
            if apiKeyManager.saveAPIKey(claudeKeyInput) {
                claudeValidationMessage = "✓ Valid API key saved securely"
            } else {
                claudeValidationMessage = "Failed to save API key to Keychain"
            }
        } else {
            claudeValidationMessage = "Invalid API key format. Should start with 'sk-ant-'"
        }
        
        isValidatingClaude = false
    }
    
    private func saveOpenAIAPIKey() async {
        isValidatingOpenAI = true
        openAIValidationMessage = "Validating..."
        
        let isValid = await apiKeyManager.validateOpenAIAPIKey(openAIKeyInput)
        
        if isValid {
            if apiKeyManager.saveOpenAIAPIKey(openAIKeyInput) {
                openAIValidationMessage = "✓ Valid API key saved securely"
            } else {
                openAIValidationMessage = "Failed to save API key to Keychain"
            }
        } else {
            openAIValidationMessage = "Invalid API key format. Should start with 'sk-'"
        }
        
        isValidatingOpenAI = false
    }
    
    private func saveGeminiAPIKey() async {
        isValidatingGemini = true
        geminiValidationMessage = "Validating..."
        
        let isValid = await apiKeyManager.validateGeminiAPIKey(geminiKeyInput)
        
        if isValid {
            if apiKeyManager.saveGeminiAPIKey(geminiKeyInput) {
                geminiValidationMessage = "✓ Valid API key saved securely"
            } else {
                geminiValidationMessage = "Failed to save API key to Keychain"
            }
        } else {
            geminiValidationMessage = "Invalid API key format. Should be at least 20 characters"
        }
        
        isValidatingGemini = false
    }
    
    private func saveMistralAPIKey() async {
        isValidatingMistral = true
        mistralValidationMessage = "Validating..."
        
        let isValid = await apiKeyManager.validateMistralAPIKey(mistralKeyInput)
        
        if isValid {
            if apiKeyManager.saveMistralAPIKey(mistralKeyInput) {
                mistralValidationMessage = "✓ Valid API key saved securely"
            } else {
                mistralValidationMessage = "Failed to save API key to Keychain"
            }
        } else {
            mistralValidationMessage = "Invalid API key format. Should be at least 20 characters"
        }
        
        isValidatingMistral = false
    }
}

#Preview {
    SettingsView(apiKeyManager: APIKeyManager())
}
