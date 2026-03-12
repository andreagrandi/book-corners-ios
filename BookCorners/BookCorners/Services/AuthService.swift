//
//  AuthService.swift
//  BookCorners
//
//  Created by Andrea Grandi on 12/03/26.
//

import Foundation
import Observation

@Observable
class AuthService {
    var currentUser: User?
    var isLoading: Bool = false
    var errorMessage: String?

    private(set) var accessToken: String?
    private var refreshToken: String?
    private let apiClient: APIClient
    private let keychainService: KeychainService
    private var refreshTask: Task<String, Error>?

    var isAuthenticated: Bool {
        accessToken != nil
    }

    init(apiClient: APIClient, keychainService: KeychainService) {
        self.apiClient = apiClient
        self.keychainService = keychainService
    }

    private func setTokens(access: String?, refresh: String?) {
        accessToken = access
        refreshToken = refresh
        apiClient.accessToken = access
    }

    private func mapError(_ error: Error) -> String {
        guard let apiError = error as? APIClientError else {
            return "Something went wrong. Please try again."
        }
        switch apiError {
        case .unauthorized:
            return "Invalid username or password"
        case .rateLimited:
            return "Too many attempts. Please try again later."
        case .networkError:
            return "Unable to connect. Check your internet connection."
        case let .httpError(statusCode, message) where statusCode == 400:
            return message
        default:
            return "Something went wrong. Please try again."
        }
    }

    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let tokenPair = try await apiClient.login(username: username, password: password)
            setTokens(access: tokenPair.access, refresh: tokenPair.refresh)

            try keychainService.saveString(tokenPair.access, forKey: KeychainService.accessTokenKey)
            try keychainService.saveString(tokenPair.refresh, forKey: KeychainService.refreshTokenKey)

            currentUser = try await apiClient.getMe()
        } catch {
            errorMessage = mapError(error)
        }
    }

    func register(username: String, password: String, email: String) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let tokenPair = try await apiClient.register(username: username, password: password, email: email)
            setTokens(access: tokenPair.access, refresh: tokenPair.refresh)

            try keychainService.saveString(tokenPair.access, forKey: KeychainService.accessTokenKey)
            try keychainService.saveString(tokenPair.refresh, forKey: KeychainService.refreshTokenKey)

            currentUser = try await apiClient.getMe()
        } catch {
            errorMessage = mapError(error)
        }
    }

    func refreshAccessToken() async throws -> String {
        if refreshTask != nil {
            return try await refreshTask!.value
        }

        refreshTask = Task {
            guard let currentRefreshToken = refreshToken else {
                throw APIClientError.unauthorized
            }

            let response = try await apiClient.refreshToken(refreshToken: currentRefreshToken)
            setTokens(access: response.access, refresh: currentRefreshToken)
            try keychainService.saveString(response.access, forKey: KeychainService.accessTokenKey)

            return response.access
        }

        defer { refreshTask = nil }
        return try await refreshTask!.value
    }
}
