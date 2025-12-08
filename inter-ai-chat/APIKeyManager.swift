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
import Security
import Combine

// MARK: - API Key Management with Keychain Storage
class APIKeyManager: ObservableObject {
    @Published var hasValidAPIKey: Bool = false
    @Published var hasValidOpenAIKey: Bool = false
    @Published var hasValidGeminiKey: Bool = false
    @Published var hasValidMistralKey: Bool = false
    @Published var isCheckingKey: Bool = false
    
    private let service = "ClaudeChatApp"
    private let anthropicAccount = "anthropic_api_key"
    private let openAIAccount = "openai_api_key"
    private let geminiAccount = "gemini_api_key"
    private let mistralAccount = "mistral_api_key"
    
    init() {
        // Don't automatically check for API key to avoid Keychain prompts
        // We'll check only when needed
        hasValidAPIKey = false
        hasValidOpenAIKey = false
        hasValidGeminiKey = false
        hasValidMistralKey = false
    }
    
    func checkForExistingAPIKeys() {
        hasValidAPIKey = getAPIKey() != nil
        hasValidOpenAIKey = getOpenAIAPIKey() != nil
        hasValidGeminiKey = getGeminiAPIKey() != nil
        hasValidMistralKey = getMistralAPIKey() != nil
    }
    
    func saveAPIKey(_ key: String) -> Bool {
        return saveAPIKey(key, forService: anthropicAccount, updateProperty: { self.hasValidAPIKey = $0 })
    }
    
    func saveOpenAIAPIKey(_ key: String) -> Bool {
        return saveAPIKey(key, forService: openAIAccount, updateProperty: { self.hasValidOpenAIKey = $0 })
    }
    
    func saveGeminiAPIKey(_ key: String) -> Bool {
        return saveAPIKey(key, forService: geminiAccount, updateProperty: { self.hasValidGeminiKey = $0 })
    }
    
    func saveMistralAPIKey(_ key: String) -> Bool {
        return saveAPIKey(key, forService: mistralAccount, updateProperty: { self.hasValidMistralKey = $0 })
    }
    
    private func saveAPIKey(_ key: String, forService account: String, updateProperty: (Bool) -> Void) -> Bool {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Delete existing key first
        deleteAPIKey(forService: account)
        
        // Save new key
        let keyData = trimmedKey.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            updateProperty(true)
            return true
        } else {
            print("Failed to save API key to Keychain. Status: \(status)")
            return false
        }
    }
    
    func getAPIKey() -> String? {
        return getAPIKey(forService: anthropicAccount)
    }
    
    func getOpenAIAPIKey() -> String? {
        return getAPIKey(forService: openAIAccount)
    }
    
    func getGeminiAPIKey() -> String? {
        return getAPIKey(forService: geminiAccount)
    }
    
    func getMistralAPIKey() -> String? {
        return getAPIKey(forService: mistralAccount)
    }
    
    private func getAPIKey(forService account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let keyData = item as? Data,
              let key = String(data: keyData, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func deleteAPIKey() {
        deleteAPIKey(forService: anthropicAccount)
        hasValidAPIKey = false
    }
    
    func deleteOpenAIAPIKey() {
        deleteAPIKey(forService: openAIAccount)
        hasValidOpenAIKey = false
    }
    
    func deleteGeminiAPIKey() {
        deleteAPIKey(forService: geminiAccount)
        hasValidGeminiKey = false
    }
    
    func deleteMistralAPIKey() {
        deleteAPIKey(forService: mistralAccount)
        hasValidMistralKey = false
    }
    
    private func deleteAPIKey(forService account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - API Key Validation
    
    func validateAPIKey(_ key: String) async -> Bool {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        // Basic format validation (Anthropic API keys start with 'sk-ant-')
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedKey.hasPrefix("sk-ant-") && trimmedKey.count > 20
    }
    
    func validateOpenAIAPIKey(_ key: String) async -> Bool {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        // Basic format validation (OpenAI API keys start with 'sk-')
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedKey.hasPrefix("sk-") && trimmedKey.count > 20
    }
    
    func validateGeminiAPIKey(_ key: String) async -> Bool {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        // Basic format validation (Gemini API keys are typically 39 characters long)
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedKey.count >= 20 // More flexible validation
    }
    
    func validateMistralAPIKey(_ key: String) async -> Bool {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        // Basic format validation (Mistral API keys start with various prefixes)
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedKey.count >= 20 // More flexible validation for now
    }
}

// MARK: - Keychain Error Handling
extension APIKeyManager {
    private func keychainErrorMessage(for status: OSStatus) -> String {
        switch status {
        case errSecItemNotFound:
            return "API key not found in Keychain"
        case errSecDuplicateItem:
            return "API key already exists in Keychain"
        case errSecAuthFailed:
            return "Authentication failed"
        case errSecUserCanceled:
            return "User canceled Keychain access"
        default:
            return "Keychain error: \(status)"
        }
    }
}