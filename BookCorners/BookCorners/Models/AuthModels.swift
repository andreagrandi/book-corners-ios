//
//  AuthModels.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

struct TokenPair: Codable {
    let access: String
    let refresh: String
}

struct AccessToken: Codable {
    let access: String
}

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
}

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct RegisterRequest: Encodable {
    let username: String
    let password: String
    let email: String
}

struct RefreshRequest: Encodable {
    let refresh: String
}
