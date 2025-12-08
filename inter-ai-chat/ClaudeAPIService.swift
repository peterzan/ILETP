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

// MARK: - Claude API Response Models
struct ClaudeAPIResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: ClaudeUsage
    
    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model, usage
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Claude API Request Models
struct ClaudeAPIRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let system: String?
    
    enum CodingKeys: String, CodingKey {
        case model, messages, system
        case maxTokens = "max_tokens"
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Claude API Service
class ClaudeAPIService {
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-5-20250929" // Correct Claude 4.5 Sonnet model
    private let maxTokens = 4096
    
    enum APIError: Error, LocalizedError {
        case noAPIKey
        case invalidResponse
        case networkError(String)
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No API key found. Please add your Anthropic API key in Settings."
            case .invalidResponse:
                return "Invalid response from Claude API"
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
        let startTime = Date()
        
        // Get API key
        guard let apiKey = apiKeyManager.getAPIKey() else {
            throw APIError.noAPIKey
        }
        
        // Test basic connectivity first
        print("Testing connectivity to api.anthropic.com...")
        do {
            let testURL = URL(string: "https://api.anthropic.com")!
            var testRequest = URLRequest(url: testURL)
            testRequest.timeoutInterval = 10.0
            let (_, _) = try await URLSession.shared.data(for: testRequest)
            print("Basic connectivity test successful")
        } catch let testError {
            print("Basic connectivity test failed: \(testError)")
        }
        
        // Prepare the conversation history using orchestrator-prepared messages
        let claudeMessages = prepareMessages(from: messages, newContent: content)
        
        // Use the enhanced system prompt (already includes digest context from orchestrator)
        let enhancedSystemPrompt = systemPrompt
        
        // Create the request
        let request = ClaudeAPIRequest(
            model: model,
            maxTokens: maxTokens,
            messages: claudeMessages,
            system: enhancedSystemPrompt.isEmpty ? nil : enhancedSystemPrompt
        )
        
        // Create URL request
        guard let url = URL(string: baseURL) else {
            throw APIError.networkError("Invalid API URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60.0 // Add timeout
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        // Encode request body
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw APIError.networkError("Failed to encode request: \(error.localizedDescription)")
        }
        
        // Send request
        do {
            print("Sending request to: \(baseURL)")
            print("Request headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
            print("Request body size: \(urlRequest.httpBody?.count ?? 0) bytes")
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
                print("Response headers: \(httpResponse.allHeaderFields)")
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
            print("Raw response: \(responseString)")
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(ClaudeAPIResponse.self, from: data)
            
            // Extract text content
            let textContent = apiResponse.content
                .compactMap { $0.type == "text" ? $0.text : nil }
                .joined(separator: "\n")
            
            let finalResponse = textContent.isEmpty ? "I apologize, but I couldn't generate a response." : textContent
            
            return finalResponse
            
        } catch let urlError as URLError {
            print("URLError: \(urlError)")
            print("URLError code: \(urlError.code)")
            print("URLError localizedDescription: \(urlError.localizedDescription)")
            switch urlError.code {
            case .notConnectedToInternet:
                throw APIError.networkError("No internet connection. Please check your network settings.")
            case .cannotFindHost:
                throw APIError.networkError("Cannot reach Anthropic servers. Please check your internet connection.")
            case .timedOut:
                throw APIError.networkError("Request timed out. Please try again.")
            default:
                throw APIError.networkError("Network error: \(urlError.localizedDescription)")
            }
        } catch let error as APIError {
            throw error
        } catch {
            print("Unexpected error: \(error)")
            throw APIError.networkError("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    private func prepareMessages(from chatMessages: [ChatMessage], newContent: String) -> [ClaudeMessage] {
        // Convert chat messages to Claude format - INCLUDING ALL AI RESPONSES for true group chat
        var claudeMessages: [ClaudeMessage] = []
        
        // Add conversation history (excluding the message we just added)
        // Filter out the most recent user message since we're about to add it as newContent
        let sortedMessages = chatMessages.sorted(by: { $0.timestamp < $1.timestamp })
        
        for message in sortedMessages {
            // Skip the most recent user message if it matches newContent to avoid duplicates
            if message.isFromUser && message.content == newContent {
                continue
            }
            
            if message.isFromUser {
                // User messages go as "user" role
                claudeMessages.append(ClaudeMessage(role: "user", content: message.content))
            } else {
                // AI messages: Only include OTHER AI models' responses, not our own
                if message.model != .claude {
                    let modelName = message.model?.displayName ?? "Assistant"
                    let prefixedContent = "\(modelName): \(message.content)"
                    claudeMessages.append(ClaudeMessage(role: "assistant", content: prefixedContent))
                }
            }
        }
        
        // Add the new user message
        claudeMessages.append(ClaudeMessage(role: "user", content: newContent))
        
        return claudeMessages
    }
}
