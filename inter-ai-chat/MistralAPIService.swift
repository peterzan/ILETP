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

// MARK: - Mistral API Response Models
struct MistralAPIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [MistralChoice]
    let usage: MistralUsage
}

struct MistralChoice: Codable {
    let index: Int
    let message: MistralMessage
    let finishReason: String
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct MistralMessage: Codable {
    let role: String
    let content: String
}

struct MistralUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Mistral API Request Models
struct MistralAPIRequest: Codable {
    let model: String
    let messages: [MistralMessage]
    let maxTokens: Int?
    let temperature: Double?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

// MARK: - Mistral API Service
class MistralAPIService {
    private let baseURL = "https://api.mistral.ai/v1/chat/completions"
    private let model = "mistral-large-latest"
    private let maxTokens = 4096
    private let temperature = 0.7
    
    enum APIError: Error, LocalizedError {
        case noAPIKey
        case invalidResponse
        case networkError(String)
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No Mistral API key found. Please add your Mistral API key in Settings."
            case .invalidResponse:
                return "Invalid response from Mistral API"
            case .networkError(let message):
                return "Network error: \(message)"
            case .apiError(let message):
                return "Mistral API error: \(message)"
            }
        }
    }
    
    func sendMessage(
        content: String,
        messages: [ChatMessage],
        systemPrompt: String,
        apiKeyManager: APIKeyManager
    ) async throws -> String {
        // Get API key
        guard let apiKey = apiKeyManager.getMistralAPIKey() else {
            throw APIError.noAPIKey
        }
        
        // Use orchestrator's pre-processed messages (includes synthetic user proxy for cross-AI awareness)
        let mistralMessages = buildConversationHistory(from: messages, newContent: content, systemPrompt: systemPrompt)
        
        // Create the request
        let request = MistralAPIRequest(
            model: model,
            messages: mistralMessages,
            maxTokens: maxTokens,
            temperature: temperature
        )
        
        // Create URL request
        guard let url = URL(string: baseURL) else {
            throw APIError.networkError("Invalid Mistral API URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60.0
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Encode request body
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw APIError.networkError("Failed to encode request: \(error.localizedDescription)")
        }
        
        // Send request
        do {
            print("🔥 Sending Mistral request to: \(baseURL)")
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("🔥 Mistral HTTP Status: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorData["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        throw APIError.apiError(message)
                    } else {
                        let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                        throw APIError.apiError("HTTP \(httpResponse.statusCode): \(errorString)")
                    }
                }
            }
            
            // Decode response
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("🔥 Mistral raw response: \(responseString)")
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(MistralAPIResponse.self, from: data)
            
            // Extract message content
            guard let firstChoice = apiResponse.choices.first else {
                throw APIError.invalidResponse
            }
            
            let responseText = firstChoice.message.content
            return responseText.isEmpty ? "I apologize, but I couldn't generate a response." : responseText
            
        } catch let urlError as URLError {
            print("🔥 Mistral URLError: \(urlError)")
            switch urlError.code {
            case .notConnectedToInternet:
                throw APIError.networkError("No internet connection. Please check your network settings.")
            case .cannotFindHost:
                throw APIError.networkError("Cannot reach Mistral servers. Please check your internet connection.")
            case .timedOut:
                throw APIError.networkError("Request timed out. Please try again.")
            default:
                throw APIError.networkError("Network error: \(urlError.localizedDescription)")
            }
        } catch let error as APIError {
            throw error
        } catch {
            print("🔥 Mistral unexpected error: \(error)")
            throw APIError.networkError("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    /// Build conversation history from orchestrator's pre-processed messages
    /// The orchestrator already handles cross-AI awareness via synthetic user proxy messages
    /// This function simply converts ChatMessage objects to Mistral's API format
    private func buildConversationHistory(from chatMessages: [ChatMessage], newContent: String, systemPrompt: String) -> [MistralMessage] {
        var mistralMessages: [MistralMessage] = []
        
        // Add system message if provided
        if !systemPrompt.isEmpty {
            mistralMessages.append(MistralMessage(role: "system", content: systemPrompt))
        }
        
        // Convert orchestrator's pre-processed messages to Mistral API format
        let sortedMessages = chatMessages.sorted(by: { $0.timestamp < $1.timestamp })
        
        for message in sortedMessages {
            // Skip the most recent user message if it matches newContent to avoid duplicates
            if message.isFromUser && message.content == newContent {
                continue
            }
            
            if message.isFromUser {
                // Include all user messages (including synthetic user proxy messages from orchestrator)
                mistralMessages.append(MistralMessage(role: "user", content: message.content))
            } else if message.model == .mistral {
                // Include Mistral's own previous responses
                mistralMessages.append(MistralMessage(role: "assistant", content: message.content))
            }
            // Note: Other AIs' responses are already converted to synthetic user messages by the orchestrator
        }
        
        // Add the new user message
        mistralMessages.append(MistralMessage(role: "user", content: newContent))
        
        print("🎯 Mistral message count: \(mistralMessages.count)")
        print("🎯 Mistral message roles: \(mistralMessages.map { $0.role }.joined(separator: " -> "))")
        
        // DEBUG: Show exact content of messages to verify synthetic user proxy
        print("🎯 Mistral message contents:")
        for (index, message) in mistralMessages.enumerated() {
            print("🎯   [\(index)] \(message.role): \(message.content.prefix(100))...")
        }
        
        return mistralMessages
    }
}
