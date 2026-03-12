//
//  KeychainService.swift
//  BookCorners
//

import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case duplicateItem
    case itemNotFound
    case unexpectedStatus(OSStatus)
    case dataConversionError

    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            "Keychain item already exists"
        case .itemNotFound:
            "Keychain item not found"
        case let .unexpectedStatus(status):
            "Keychain error: \(status)"
        case .dataConversionError:
            "Failed to convert keychain data"
        }
    }
}

nonisolated class KeychainService {
    static let accessTokenKey = "access_token"
    static let refreshTokenKey = "refresh_token"

    private let service: String

    init(service: String = "it.andreagrandi.BookCorners") {
        self.service = service
    }

    // MARK: - Core operations

    func save(data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Item exists — update it instead
            let searchQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]
            let updates: [String: Any] = [
                kSecValueData as String: data,
            ]
            let updateStatus = SecItemUpdate(searchQuery as CFDictionary, updates as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func load(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        return result as? Data
    }

    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        // Silently ignore "not found" — deleting something already gone is fine
        if status != errSecSuccess, status != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - String convenience

    func saveString(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }
        try save(data: data, forKey: key)
    }

    func loadString(forKey key: String) throws -> String? {
        guard let data = try load(forKey: key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionError
        }
        return string
    }
}
