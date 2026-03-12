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
