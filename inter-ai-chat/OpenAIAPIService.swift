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

// MARK: - OpenAI API Response Models
struct OpenAIAPIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage
}

struct OpenAIChoice: Codable {
    let index: Int
    let message: OpenAIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - OpenAI API Request Models
struct OpenAIAPIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let maxCompletionTokens: Int
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case model, messages, stream
        case maxCompletionTokens = "max_completion_tokens"
    }
}

// MARK: - Streaming Response Models
struct OpenAIStreamResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [OpenAIStreamChoice]
}

struct OpenAIStreamChoice: Codable {
    let index: Int
    let delta: OpenAIStreamDelta
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, delta
        case finishReason = "finish_reason"
    }
}

struct OpenAIStreamDelta: Codable {
    let role: String?
    let content: String?
}

// MARK: - OpenAI API Service
class OpenAIAPIService {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-5" // GPT-5 model (requires max_completion_tokens, not max_tokens)
    private let maxCompletionTokens = 2048 // GPT-5 uses max_completion_tokens (not max_tokens)
    
    // Note: streaming is disabled to avoid GPT-5 organization verification requirement
    // If organization becomes verified, streaming can be enabled by changing stream: false to stream: true
    
    // Fallback model in case GPT-5 becomes unavailable
    private let fallbackModel = "gpt-4o"
    
    enum APIError: Error, LocalizedError {
        case noAPIKey
        case invalidResponse
        case networkError(String)
        case apiError(String)
        case parameterError(String)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No OpenAI API key found. Please add your OpenAI API key in Settings."
            case .invalidResponse:
                return "Invalid response from OpenAI API"
            case .networkError(let message):
                return "Network error: \(message)"
            case .apiError(let message):
                return "API error: \(message)"
            case .parameterError(let message):
                return "Parameter error: \(message)"
            }
        }
    }
    
    func sendMessage(
        content: String,
        messages: [ChatMessage],
        systemPrompt: String,
        apiKeyManager: APIKeyManager
    ) async throws -> String {
        // Try with retry logic for GPT-5 timeouts
        let maxRetries = 2
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                print("🔄 GPT-5 attempt \(attempt)/\(maxRetries)")
                return try await sendMessageWithRetry(
                    content: content,
                    messages: messages,
                    systemPrompt: systemPrompt,
                    apiKeyManager: apiKeyManager
                )
            } catch let urlError as URLError where urlError.code == .timedOut {
                print("⏱️ GPT-5 timeout on attempt \(attempt), retrying...")
                lastError = urlError
                if attempt < maxRetries {
                    // Brief delay before retry
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                }
                continue
            } catch {
                // Non-timeout error, don't retry
                throw error
            }
        }
        
        // If all retries failed, throw the last timeout error with helpful message
        if let lastError = lastError {
            throw APIError.networkError("GPT-5 timed out after \(maxRetries) attempts. Last error: \(lastError.localizedDescription)")
        } else {
            throw APIError.networkError("GPT-5 timed out after \(maxRetries) attempts. This may be due to high server load or complex processing. Try again in a moment.")
        }
    }
    
    private func sendMessageWithRetry(
        content: String,
        messages: [ChatMessage],
        systemPrompt: String,
        apiKeyManager: APIKeyManager
    ) async throws -> String {
        // Try GPT-5 first, fall back to GPT-4o if needed
        do {
            return try await sendMessageWithModel(
                model: model, // GPT-5
                content: content,
                messages: messages,
                systemPrompt: systemPrompt,
                apiKeyManager: apiKeyManager
            )
        } catch let error as APIError {
            // If GPT-5 fails with specific errors, try GPT-4o fallback
            if case .apiError(let message) = error,
               (message.contains("not found") || message.contains("not supported") || message.contains("model")) {
                print("GPT-5 failed (\(message)), trying GPT-4o fallback...")
                return try await sendMessageWithModel(
                    model: fallbackModel, // GPT-4o
                    content: content,
                    messages: messages,
                    systemPrompt: systemPrompt,
                    apiKeyManager: apiKeyManager
                )
            }
            throw error
        }
    }
    
    private func sendMessageWithModel(
        model: String,
        content: String,
        messages: [ChatMessage],
        systemPrompt: String,
        apiKeyManager: APIKeyManager
    ) async throws -> String {
        // Get API key
        guard let apiKey = apiKeyManager.getOpenAIAPIKey() else {
            throw APIError.noAPIKey
        }
        
        // Prepare the conversation history
        let openAIMessages = prepareMessages(from: messages, newContent: content, systemPrompt: systemPrompt)
        
        // Create the request - use appropriate parameters for model
        let request: OpenAIAPIRequest
        if model == "gpt-5" {
            // GPT-5 requires max_completion_tokens
            request = OpenAIAPIRequest(
                model: model,
                messages: openAIMessages,
                maxCompletionTokens: maxCompletionTokens,
                stream: false // Disabled to avoid org verification requirement
            )
        } else {
            // GPT-4o and other models can use max_completion_tokens too (it's backward compatible)
            request = OpenAIAPIRequest(
                model: model,
                messages: openAIMessages,
                maxCompletionTokens: maxCompletionTokens,
                stream: false
            )
        }
        
        // Create URL request
        guard let url = URL(string: baseURL) else {
            throw APIError.networkError("Invalid API URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 120.0 // Increased to 2 minutes for GPT-5
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Encode request body and send request
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            print("Sending request to OpenAI using model \(model): \(baseURL)")
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("OpenAI HTTP Status: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorData["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        
                        // Check for specific GPT-5 issues mentioned in documentation
                        if message.contains("organization must be verified") {
                            throw APIError.apiError("GPT-5 streaming requires organization verification. Using non-streaming mode, but verification may be needed for future features.")
                        } else if message.contains("max_tokens") && message.contains("not supported") {
                            throw APIError.parameterError("GPT-5 parameter error: \(message). Please contact support - this should be using max_completion_tokens.")
                        } else {
                            throw APIError.apiError(message)
                        }
                    } else {
                        let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                        throw APIError.apiError("HTTP \(httpResponse.statusCode): \(errorString)")
                    }
                }
            }
            
            // Decode response
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("OpenAI Raw response: \(responseString)")
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(OpenAIAPIResponse.self, from: data)
            
            // Extract text content
            guard let firstChoice = apiResponse.choices.first else {
                throw APIError.invalidResponse
            }
            
            return firstChoice.message.content.isEmpty ? "I apologize, but I couldn't generate a response." : firstChoice.message.content
            
        } catch is EncodingError {
            throw APIError.networkError("Failed to encode request data")
        } catch let urlError as URLError {
            print("OpenAI URLError: \(urlError)")
            switch urlError.code {
            case .timedOut:
                throw urlError // Re-throw timeout for retry logic
            case .notConnectedToInternet:
                throw APIError.networkError("No internet connection. Please check your network settings.")
            case .cannotFindHost:
                throw APIError.networkError("Cannot reach OpenAI servers. Please check your internet connection.")
            default:
                throw APIError.networkError("Network error: \(urlError.localizedDescription)")
            }
        } catch let error as APIError {
            throw error
        } catch {
            print("OpenAI Unexpected error: \(error)")
            throw APIError.networkError("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    private func prepareMessages(from chatMessages: [ChatMessage], newContent: String, systemPrompt: String) -> [OpenAIMessage] {
        var openAIMessages: [OpenAIMessage] = []
        
        // Add system prompt first
        if !systemPrompt.isEmpty {
            openAIMessages.append(OpenAIMessage(role: "system", content: systemPrompt))
        }
        
        // Add conversation history - INCLUDING ALL AI RESPONSES for true group chat
        let sortedMessages = chatMessages.sorted(by: { $0.timestamp < $1.timestamp })
        
        for message in sortedMessages {
            // Skip the most recent user message if it matches newContent to avoid duplicates
            if message.isFromUser && message.content == newContent {
                continue
            }
            
            if message.isFromUser {
                // User messages go as "user" role
                openAIMessages.append(OpenAIMessage(role: "user", content: message.content))
            } else {
                // AI messages: Only include OTHER AI models' responses, not our own
                if message.model != .chatgpt {
                    let modelName = message.model?.displayName ?? "Assistant"
                    let prefixedContent = "\(modelName): \(message.content)"
                    openAIMessages.append(OpenAIMessage(role: "assistant", content: prefixedContent))
                }
            }
        }
        
        // Add the new user message
        openAIMessages.append(OpenAIMessage(role: "user", content: newContent))
        
        return openAIMessages
    }
}
