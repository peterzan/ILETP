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

// MARK: - Multi-AI Service Manager
class MultiAIService {
    private let claudeAPI = ClaudeAPIService()
    private let openAIAPI = OpenAIAPIService()
    
    struct AIResponse {
        let model: AIModel
        let content: String
        let error: Error?
        
        var isError: Bool { error != nil }
    }
    
    func sendMessageToAllModels(
        content: String,
        messages: [ChatMessage],
        systemPrompt: String,
        activeModels: [AIModel],
        apiKeyManager: APIKeyManager
    ) async -> [AIResponse] {
        
        print("🔥 MultiAIService: sending message to \(activeModels.count) models")
        
        // Send to all models in parallel and collect responses
        let responses = await withTaskGroup(of: AIResponse.self, returning: [AIResponse].self) { group in
            for model in activeModels {
                group.addTask {
                    await self.sendToSingleModel(
                        content: content,
                        messages: messages,
                        systemPrompt: systemPrompt,
                        model: model,
                        apiKeyManager: apiKeyManager
                    )
                }
            }
            
            var results: [AIResponse] = []
            for await response in group {
                results.append(response)
            }
            return results
        }
        
        print("🔥 MultiAIService: received \(responses.count) responses")
        return responses
    }
    
    private func sendToSingleModel(
        content: String,
        messages: [ChatMessage],
        systemPrompt: String,
        model: AIModel,
        apiKeyManager: APIKeyManager
    ) async -> AIResponse {
        
        print("🔥 MultiAIService: sending to \(model.displayName)")
        
        do {
            let responseContent: String
            
            switch model {
            case .claude:
                responseContent = try await claudeAPI.sendMessage(
                    content: content,
                    messages: messages,
                    systemPrompt: systemPrompt,
                    apiKeyManager: apiKeyManager
                )
                
            case .chatgpt:
                responseContent = try await openAIAPI.sendMessage(
                    content: content,
                    messages: messages,
                    systemPrompt: systemPrompt,
                    apiKeyManager: apiKeyManager
                )
                
            case .gemini:
                let geminiAPI = GeminiAPIService()
                responseContent = try await geminiAPI.sendMessage(
                    content: content,
                    messages: messages,
                    systemPrompt: systemPrompt,
                    apiKeyManager: apiKeyManager
                )
                
            case .mistral:
                let mistralAPI = MistralAPIService()
                responseContent = try await mistralAPI.sendMessage(
                    content: content,
                    messages: messages,
                    systemPrompt: systemPrompt,
                    apiKeyManager: apiKeyManager
                )
                
            case .ollama:
                let ollamaAPI = OllamaAPIService()
                responseContent = try await ollamaAPI.sendMessage(
                    content: content,
                    messages: messages,
                    systemPrompt: systemPrompt,
                    apiKeyManager: apiKeyManager
                )
            }
            
            print("🔥 MultiAIService: \(model.displayName) succeeded")
            return AIResponse(model: model, content: responseContent, error: nil)
            
        } catch {
            print("🔥 MultiAIService: \(model.displayName) failed with error: \(error)")
            let errorContent = "[\(model.displayName) Error]: \(error.localizedDescription)"
            return AIResponse(model: model, content: errorContent, error: error)
        }
    }
}