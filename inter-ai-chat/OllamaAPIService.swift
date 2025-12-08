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

// MARK: - Ollama Service Manager
class OllamaService {
    static let shared = OllamaService()
    private init() {}
    
    private let baseURL = "http://localhost:11434"
    private(set) var isAvailable = false
    
    func checkAvailability() async {
        do {
            guard let url = URL(string: "\(baseURL)/api/tags") else {
                isAvailable = false
                return
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 5.0 // Quick check
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]],
               models.contains(where: { ($0["name"] as? String)?.contains("llama3.1:8b") == true }) {
                isAvailable = true
                print("✅ Ollama service available with llama3.1:8b")
            } else {
                isAvailable = false
                print("❌ Ollama service running but llama3.1:8b not found")
            }
        } catch {
            isAvailable = false
            print("❌ Ollama service not available: \(error.localizedDescription)")
        }
    }
    
    func getUnavailableMessage() -> String {
        return "Start Llama service"
    }
}

// MARK: - Ollama API Response Models (OpenAI-compatible)
struct OllamaAPIResponse: Codable {
    let model: String
    let createdAt: String
    let message: OllamaMessage
    let done: Bool
    
    enum CodingKeys: String, CodingKey {
        case model, message, done
        case createdAt = "created_at"
    }
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Ollama API Request Models
struct OllamaAPIRequest: Codable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool = false
}

// MARK: - Ollama API Service
class OllamaAPIService {
    private let baseURL = "http://localhost:11434/api/chat"
    private let modelName = "llama3.1:8b"
    private let timeout: TimeInterval = 60.0 // Local models can be slow on first response
    
    enum APIError: Error, LocalizedError {
        case serviceUnavailable
        case invalidResponse
        case networkError(String)
        case modelError(String)
        
        var errorDescription: String? {
            switch self {
            case .serviceUnavailable:
                return "Llama service is not running. Start Ollama service and try again."
            case .invalidResponse:
                return "Invalid response from Llama"
            case .networkError(let message):
                return "Network error: \(message)"
            case .modelError(let message):
                return "Model error: \(message)"
            }
        }
    }
    
    func sendMessage(
        content: String,
        messages: [ChatMessage],
        systemPrompt: String,
        apiKeyManager: APIKeyManager
    ) async throws -> String {
        // Check if service is available
        guard OllamaService.shared.isAvailable else {
            throw APIError.serviceUnavailable
        }
        
        // Prepare messages
        let ollamaMessages = prepareMessages(from: messages, newContent: content, systemPrompt: systemPrompt)
        
        // Create request
        let request = OllamaAPIRequest(
            model: modelName,
            messages: ollamaMessages
        )
        
        // Create URL request
        guard let url = URL(string: baseURL) else {
            throw APIError.networkError("Invalid API URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = timeout
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            print("Sending request to Ollama: \(baseURL)")
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("Ollama HTTP Status: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorData["error"] as? String {
                        throw APIError.modelError(error)
                    } else {
                        let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                        throw APIError.modelError("HTTP \(httpResponse.statusCode): \(errorString)")
                    }
                }
            }
            
            // Decode response
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("Ollama Raw response: \(responseString)")
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(OllamaAPIResponse.self, from: data)
            
            let responseContent = apiResponse.message.content
            return responseContent.isEmpty ? "I apologize, but I couldn't generate a response." : responseContent
            
        } catch is EncodingError {
            throw APIError.networkError("Failed to encode request data")
        } catch let urlError as URLError {
            print("Ollama URLError: \(urlError)")
            switch urlError.code {
            case .timedOut:
                throw APIError.networkError("Llama took too long to respond. This can happen on first use - try again.")
            case .cannotConnectToHost:
                throw APIError.serviceUnavailable
            default:
                throw APIError.networkError("Network error: \(urlError.localizedDescription)")
            }
        } catch let error as APIError {
            throw error
        } catch {
            print("Ollama Unexpected error: \(error)")
            throw APIError.networkError("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    private func prepareMessages(from chatMessages: [ChatMessage], newContent: String, systemPrompt: String) -> [OllamaMessage] {
        var ollamaMessages: [OllamaMessage] = []
        
        // Add system prompt first
        if !systemPrompt.isEmpty {
            ollamaMessages.append(OllamaMessage(role: "system", content: systemPrompt))
        }
        
        // Add conversation history with cross-AI awareness
        let sortedMessages = chatMessages.sorted(by: { $0.timestamp < $1.timestamp })
        
        for message in sortedMessages {
            // Skip duplicate user message
            if message.isFromUser && message.content == newContent {
                continue
            }
            
            if message.isFromUser {
                ollamaMessages.append(OllamaMessage(role: "user", content: message.content))
            } else {
                // AI messages: Include other AI responses for cross-AI awareness
                if message.model != .ollama {
                    let modelName = message.model?.displayName ?? "Assistant"
                    let prefixedContent = "[\(modelName)]: \(message.content)"
                    ollamaMessages.append(OllamaMessage(role: "user", content: prefixedContent))
                } else {
                    // Include our own previous responses as assistant messages
                    ollamaMessages.append(OllamaMessage(role: "assistant", content: message.content))
                }
            }
        }
        
        // Add the new user message
        ollamaMessages.append(OllamaMessage(role: "user", content: newContent))
        
        return ollamaMessages
    }
}
