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

// MARK: - Gemini API Request/Response Models
struct GeminiAPIRequest: Codable {
    let contents: [GeminiContent]
    let systemInstruction: GeminiContent?
    let generationConfig: GeminiGenerationConfig?
    
    enum CodingKeys: String, CodingKey {
        case contents
        case systemInstruction = "system_instruction"
        case generationConfig = "generation_config"
    }
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
    let role: String?
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double?
    let maxOutputTokens: Int?
    let topP: Double?
    let topK: Int?
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case maxOutputTokens = "max_output_tokens"
        case topP = "top_p"
        case topK = "top_k"
    }
}

struct GeminiAPIResponse: Codable {
    let candidates: [GeminiCandidate]
    let usageMetadata: GeminiUsageMetadata?
    
    enum CodingKeys: String, CodingKey {
        case candidates
        case usageMetadata = "usage_metadata"
    }
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    let index: Int?
    
    enum CodingKeys: String, CodingKey {
        case content
        case finishReason = "finish_reason"
        case index
    }
}

struct GeminiUsageMetadata: Codable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokenCount = "prompt_token_count"
        case candidatesTokenCount = "candidates_token_count"
        case totalTokenCount = "total_token_count"
    }
}

// MARK: - Gemini API Service
class GeminiAPIService {
    // Try the exact current Google recommendation
    private let models = ["gemini-1.5-flash-latest", "gemini-1.5-pro-latest", "gemini-pro"] 
    private var currentModelIndex = 0
    
    private var currentModel: String {
        models[currentModelIndex]
    }
    private let maxOutputTokens = 2048
    
    enum APIError: Error, LocalizedError {
        case noAPIKey
        case invalidResponse
        case networkError(String)
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No Gemini API key found. Please add your Gemini API key in Settings."
            case .invalidResponse:
                return "Invalid response from Gemini API"
            case .networkError(let message):
                return "Network error: \(message)"
            case .apiError(let message):
                return "API error: \(message)"
            }
        }
    }
    
    func sendMessage(
        content: String,
        messages: [ChatMessage],
        systemPrompt: String,
        apiKeyManager: APIKeyManager
    ) async throws -> String {
        // First, let's get the list of available models
        print("🔍 Discovering available Gemini models...")
        
        do {
            let availableModels = try await getAvailableModels(apiKeyManager: apiKeyManager)
            print("✅ Available Gemini models: \(availableModels)")
            
            guard !availableModels.isEmpty else {
                throw APIError.apiError("No Gemini models available. Please check if Gemini API is enabled in Google Cloud Console.")
            }
            
            // Try to use the first available model that supports generateContent
            for modelName in availableModels {
                print("🧪 Trying model: \(modelName)")
                do {
                    let response = try await sendMessageWithModel(
                        model: modelName,
                        content: content,
                        messages: messages,
                        systemPrompt: systemPrompt,
                        apiKeyManager: apiKeyManager
                    )
                    print("✅ Success with model: \(modelName)")
                    return response
                } catch let error as APIError {
                    if case .apiError(let message) = error,
                       message.contains("not found") {
                        // Try the next model
                        print("❌ Model \(modelName) failed: \(message)")
                        continue
                    } else {
                        // Non-model error, throw it
                        print("💥 Non-model error with \(modelName): \(error)")
                        throw error
                    }
                }
            }
            
            // If no models worked, throw an error
            throw APIError.apiError("No working Gemini models found. Available models: \(availableModels.joined(separator: ", "))")
            
        } catch {
            // If we can't get model list, this is probably a more fundamental issue
            print("💥 Could not discover models: \(error)")
            throw error
        }
    }
    
    // Helper function to get available models
    private func getAvailableModels(apiKeyManager: APIKeyManager) async throws -> [String] {
        guard let apiKey = apiKeyManager.getGeminiAPIKey() else {
            throw APIError.noAPIKey
        }
        
        let listURL = "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
        guard let url = URL(string: listURL) else {
            throw APIError.networkError("Invalid API URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 30.0
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Check HTTP response
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw APIError.apiError("Failed to list models: HTTP \(httpResponse.statusCode)")
            }
        }
        
        // Debug: Print the raw response first
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        print("🔍 Raw ListModels response: \(responseString)")
        
        // Try to parse with flexible approach
        do {
            if let responseJson = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔍 Parsed JSON keys: \(Array(responseJson.keys))")
                
                // Try different possible response formats
                var modelNames: [String] = []
                
                // Format 1: {"models": [...]}
                if let models = responseJson["models"] as? [[String: Any]] {
                    print("🔍 Found models array with \(models.count) items")
                    
                    for model in models {
                        if let name = model["name"] as? String,
                           let supportedMethods = model["supported_generation_methods"] as? [String] ?? model["supportedGenerationMethods"] as? [String] {
                            
                            print("🔍 Model: \(name), Methods: \(supportedMethods)")
                            
                            if supportedMethods.contains("generateContent") {
                                // Extract just the model name from the full path
                                let modelName = name.contains("/") ? String(name.split(separator: "/").last ?? "") : name
                                modelNames.append(modelName)
                            }
                        } else if let name = model["name"] as? String {
                            // Fallback: assume all models support generateContent if methods aren't specified
                            let modelName = name.contains("/") ? String(name.split(separator: "/").last ?? "") : name
                            modelNames.append(modelName)
                        }
                    }
                }
                
                print("🔍 Extracted model names: \(modelNames)")
                return modelNames.isEmpty ? ["gemini-pro"] : modelNames // Fallback to gemini-pro if nothing found
                
            } else {
                print("🔍 Response is not a JSON object")
                throw APIError.apiError("Invalid JSON response format")
            }
            
        } catch {
            print("🔍 JSON parsing error: \(error)")
            print("🔍 Falling back to default models")
            // If parsing fails completely, return some reasonable defaults
            return ["gemini-pro", "gemini-1.5-flash", "gemini-1.5-pro"]
        }
    }
    
    // Fallback function with our hardcoded models
    private func tryFallbackModels(
        content: String,
        messages: [ChatMessage],
        systemPrompt: String,
        apiKeyManager: APIKeyManager
    ) async throws -> String {
        // Try multiple models until one works
        for (index, modelName) in models.enumerated() {
            do {
                return try await sendMessageWithModel(
                    model: modelName,
                    content: content,
                    messages: messages,
                    systemPrompt: systemPrompt,
                    apiKeyManager: apiKeyManager
                )
            } catch let error as APIError {
                if case .apiError(let message) = error,
                   message.contains("not found") && index < models.count - 1 {
                    // Try the next model
                    print("Model \(modelName) not found, trying next model...")
                    continue
                } else {
                    // Last model or non-model error, throw the error
                    throw error
                }
            }
        }
        
        // If we get here, all models failed
        throw APIError.apiError("All Gemini models failed. Please check if Gemini API is enabled in your Google Cloud project.")
    }
    
    private func sendMessageWithModel(
        model: String,
        content: String,
        messages: [ChatMessage],
        systemPrompt: String,
        apiKeyManager: APIKeyManager
    ) async throws -> String {
        // Get API key
        guard let apiKey = apiKeyManager.getGeminiAPIKey() else {
            throw APIError.noAPIKey
        }
        
        // Build conversation history from filtered messages (orchestrator-prepared)
        let conversationContents = buildConversationHistory(from: messages, newContent: content)
        
        // Create request with full conversation history
        var requestDict: [String: Any] = [
            "contents": conversationContents
        ]
        
        // Add system instruction if provided
        if !systemPrompt.isEmpty {
            requestDict["system_instruction"] = [
                "parts": [
                    ["text": systemPrompt]
                ]
            ]
        }
        
        // Create URL request
        let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw APIError.networkError("Invalid API URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60.0
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use updated request with system prompt
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestDict)
            
            print("Sending minimal request to Gemini using model \(model): \(baseURL)")
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("Gemini HTTP Status: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("Gemini Error Response: \(errorString)")
                    
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorData["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        
                        // Check for specific Gemini issues
                        if message.contains("API key") {
                            throw APIError.apiError("Gemini API key error: \(message)")
                        } else if message.contains("not found") || message.contains("does not exist") {
                            throw APIError.apiError("Gemini model \(model) not found. Error: \(message)")
                        } else if message.contains("quota") || message.contains("billing") {
                            // More detailed quota error handling
                            if message.contains("free_tier") {
                                throw APIError.apiError("Gemini free tier quota exceeded. Since billing is now linked, this should resolve shortly. If it persists, the free tier may be exhausted. Error: \(message)")
                            } else {
                                throw APIError.apiError("Gemini API quota/billing issue: \(message). Note: Billing was recently linked and may need a few minutes to activate.")
                            }
                        } else if message.contains("disabled") {
                            throw APIError.apiError("Gemini API not enabled. Please enable it in Google Cloud Console: \(message)")
                        } else {
                            throw APIError.apiError("Gemini API error: \(message)")
                        }
                    } else {
                        throw APIError.apiError("HTTP \(httpResponse.statusCode): \(errorString)")
                    }
                }
            }
            
            // Decode response
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("Gemini Raw response: \(responseString)")
            
            // Parse minimal response
            if let responseJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = responseJson["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let firstPart = parts.first,
               let text = firstPart["text"] as? String {
                
                let responseText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                return responseText.isEmpty ? "I apologize, but I couldn't generate a response." : responseText
            } else {
                throw APIError.invalidResponse
            }
            
        } catch let error as APIError {
            throw error
        } catch is EncodingError {
            throw APIError.networkError("Failed to encode request data")
        } catch let urlError as URLError {
            print("Gemini URLError: \(urlError)")
            switch urlError.code {
            case .notConnectedToInternet:
                throw APIError.networkError("No internet connection. Please check your network settings.")
            case .cannotFindHost:
                throw APIError.networkError("Cannot reach Gemini servers. Please check your internet connection.")
            case .timedOut:
                throw APIError.networkError("Request timed out. Please try again.")
            default:
                throw APIError.networkError("Network error: \(urlError.localizedDescription)")
            }
        } catch {
            print("Gemini Unexpected error: \(error)")
            throw APIError.networkError("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    private func prepareContents(from chatMessages: [ChatMessage], newContent: String) -> [GeminiContent] {
        var contents: [GeminiContent] = []
        
        // Add conversation history - INCLUDING ALL AI RESPONSES for true group chat
        let sortedMessages = chatMessages.sorted(by: { $0.timestamp < $1.timestamp })
        
        for message in sortedMessages {
            // Skip the most recent user message if it matches newContent to avoid duplicates
            if message.isFromUser && message.content == newContent {
                continue
            }
            
            if message.isFromUser {
                // User messages go as "user" role
                contents.append(GeminiContent(
                    parts: [GeminiPart(text: message.content)],
                    role: "user"
                ))
            } else {
                // AI messages: Only include OTHER AI models' responses, not our own
                if message.model != .gemini {
                    let modelName = message.model?.displayName ?? "Assistant"
                    let prefixedContent = "\(modelName): \(message.content)"
                    contents.append(GeminiContent(
                        parts: [GeminiPart(text: prefixedContent)],
                        role: "model"
                    ))
                }
            }
        }
        
        // Add the new user message
        contents.append(GeminiContent(
            parts: [GeminiPart(text: newContent)],
            role: "user"
        ))
        
        return contents
    }
    
    // New method for orchestrator-prepared messages (converts to API format)
    private func buildConversationHistory(from messages: [ChatMessage], newContent: String) -> [[String: Any]] {
        var conversationContents: [[String: Any]] = []
        
        // Process orchestrator-filtered messages
        let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
        
        for message in sortedMessages {
            // Skip the most recent user message if it matches newContent to avoid duplicates
            if message.isFromUser && message.content == newContent {
                continue
            }
            
            if message.isFromUser {
                // User messages (including synthetic user proxy messages for cross-AI awareness)
                conversationContents.append([
                    "parts": [["text": message.content]],
                    "role": "user"
                ])
            } else {
                // AI assistant messages - convert 'assistant' to 'model' for Gemini API
                conversationContents.append([
                    "parts": [["text": message.content]],
                    "role": "model"
                ])
            }
        }
        
        // Add the new user message
        conversationContents.append([
            "parts": [["text": newContent]],
            "role": "user"
        ])
        
        return conversationContents
    }
}