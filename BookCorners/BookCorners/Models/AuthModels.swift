//
//  AuthModels.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

nonisolated struct TokenPair: Codable {
    let access: String
    let refresh: String
}

nonisolated struct AccessToken: Codable {
    let access: String
}

nonisolated struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let isSocialOnly: Bool?
    let isStaff: Bool

    init(
        id: Int,
        username: String,
        email: String,
        isSocialOnly: Bool?,
        isStaff: Bool = false,
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.isSocialOnly = isSocialOnly
        self.isStaff = isStaff
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        isSocialOnly = try container.decodeIfPresent(Bool.self, forKey: .isSocialOnly)
        isStaff = try container.decodeIfPresent(Bool.self, forKey: .isStaff) ?? false
    }
}

nonisolated struct DeleteAccountRequest: Encodable {
    let password: String?
    let confirm: Bool?
}

nonisolated struct MessageResponse: Codable {
    let message: String
}

nonisolated struct LoginRequest: Encodable {
    let username: String
    let password: String
}

nonisolated struct RegisterRequest: Encodable {
    let username: String
    let password: String
    let email: String
}

nonisolated struct RefreshRequest: Encodable {
    let refresh: String
}

nonisolated struct SocialLoginRequest: Encodable {
    let provider: String
    let idToken: String
    let firstName: String?
    let lastName: String?
}
