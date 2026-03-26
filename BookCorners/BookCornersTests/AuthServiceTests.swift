//
//  AuthServiceTests.swift
//  BookCornersTests
//
//  Created by Andrea Grandi on 13/03/26.
//

@testable import BookCorners
import Foundation
import Testing

extension SerialNetworkTests {
    @MainActor struct AuthServiceTests {
        let client: APIClient
        let keychainService: KeychainService
        let authService: AuthService

        init() {
            client = APIClient(
                baseURL: URL(string: "https://test.example.com/api/v1/")!,
                session: MockURLProtocol.mockSession,
            )
            keychainService = KeychainService(service: "test.\(UUID())")
            authService = AuthService(apiClient: client, keychainService: keychainService)
        }

        @Test func `login success sets authenticated and user`() async {
            // Mock handler returns different JSON based on the URL path
            MockURLProtocol.requestHandler = { request in
                let path = request.url!.path
                let json: String

                if path.contains("auth/login") {
                    json = Fixtures.tokenPairJSON
                } else if path.contains("auth/me") {
                    json = Fixtures.userJSON
                } else {
                    Issue.record("Unexpected request: \(path)")
                    json = "{}"
                }

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                return (response, json.data(using: .utf8)!)
            }

            await authService.login(username: "test", password: "pass")

            #expect(authService.isAuthenticated)
            #expect(authService.currentUser?.username == "booklover")
            #expect(authService.errorMessage == nil)
        }

        @Test func `login failure`() async {
            // Mock handler returns different JSON based on the URL path
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 401,
                    httpVersion: nil, headerFields: nil,
                )!
                return (response, Fixtures.apiErrorJSON.data(using: .utf8)!)
            }

            await authService.login(username: "test", password: "pass")

            #expect(authService.isAuthenticated == false)
            #expect(authService.currentUser == nil)
            #expect(authService.errorMessage == "Authentication failed.")
        }

        @Test func logout() async {
            // Mock handler returns different JSON based on the URL path
            MockURLProtocol.requestHandler = { request in
                let path = request.url!.path
                let json: String

                if path.contains("auth/login") {
                    json = Fixtures.tokenPairJSON
                } else if path.contains("auth/me") {
                    json = Fixtures.userJSON
                } else {
                    Issue.record("Unexpected request: \(path)")
                    json = "{}"
                }

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                return (response, json.data(using: .utf8)!)
            }

            await authService.login(username: "test", password: "pass")
            authService.logout()

            #expect(authService.isAuthenticated == false)
            #expect(authService.currentUser == nil)
            #expect(authService.errorMessage == nil)
        }

        @Test func `session restore with valid token`() async throws {
            // Pre-save tokens to keychain
            try keychainService.saveString("saved-access", forKey: KeychainService.accessTokenKey)
            try keychainService.saveString("saved-refresh", forKey: KeychainService.refreshTokenKey)

            // Mock getMe to succeed
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                return (response, Fixtures.userJSON.data(using: .utf8)!)
            }

            await authService.restoreSession()

            #expect(authService.isAuthenticated)
            #expect(authService.currentUser?.username == "booklover")
        }

        @Test func `session restore with expired token refreshes`() async throws {
            // Pre-save tokens to keychain
            try keychainService.saveString("expired-access", forKey: KeychainService.accessTokenKey)
            try keychainService.saveString("valid-refresh", forKey: KeychainService.refreshTokenKey)

            // The flow: restoreSession calls getMe → 401 → APIClient's tokenRefresher
            // calls refreshAccessToken → auth/refresh → 200 → APIClient retries getMe → 200
            // So we need: getMe #1 = 401, auth/refresh = 200, getMe #2 = 200
            var getMeCallCount = 0

            MockURLProtocol.requestHandler = { request in
                let path = request.url!.path

                if path.contains("auth/me") {
                    getMeCallCount += 1
                    if getMeCallCount == 1 {
                        let response = HTTPURLResponse(
                            url: request.url!, statusCode: 401,
                            httpVersion: nil, headerFields: nil,
                        )!
                        return (response, Fixtures.apiErrorJSON.data(using: .utf8)!)
                    } else {
                        let response = HTTPURLResponse(
                            url: request.url!, statusCode: 200,
                            httpVersion: nil, headerFields: nil,
                        )!
                        return (response, Fixtures.userJSON.data(using: .utf8)!)
                    }
                } else if path.contains("auth/refresh") {
                    let json = """
                    {"access": "new-access-token"}
                    """
                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 200,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, json.data(using: .utf8)!)
                } else {
                    Issue.record("Unexpected request: \(path)")
                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 500,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, "{}".data(using: .utf8)!)
                }
            }

            await authService.restoreSession()

            #expect(authService.isAuthenticated)
            #expect(authService.currentUser?.username == "booklover")
        }

        @Test func `delete account success clears session`() async {
            // First log in
            MockURLProtocol.requestHandler = { request in
                let path = request.url!.path
                let json: String

                if path.contains("auth/login") {
                    json = Fixtures.tokenPairJSON
                } else if path.contains("auth/me"), request.httpMethod == "GET" {
                    json = Fixtures.userJSON
                } else if path.contains("auth/me"), request.httpMethod == "DELETE" {
                    json = Fixtures.deleteAccountSuccessJSON
                } else {
                    Issue.record("Unexpected request: \(request.httpMethod ?? "?") \(path)")
                    json = "{}"
                }

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                return (response, json.data(using: .utf8)!)
            }

            await authService.login(username: "test", password: "pass")
            #expect(authService.isAuthenticated)

            await authService.deleteAccount(password: "pass")

            #expect(authService.isAuthenticated == false)
            #expect(authService.currentUser == nil)
            #expect(authService.errorMessage == nil)
        }

        @Test func `delete account wrong password shows error`() async {
            // First log in
            MockURLProtocol.requestHandler = { request in
                let path = request.url!.path

                if path.contains("auth/login") {
                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 200,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, Fixtures.tokenPairJSON.data(using: .utf8)!)
                } else if path.contains("auth/me"), request.httpMethod == "GET" {
                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 200,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, Fixtures.userJSON.data(using: .utf8)!)
                } else if path.contains("auth/me"), request.httpMethod == "DELETE" {
                    let json = """
                    {"message": "Incorrect password."}
                    """
                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 400,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, json.data(using: .utf8)!)
                } else {
                    Issue.record("Unexpected request: \(path)")
                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 500,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, "{}".data(using: .utf8)!)
                }
            }

            await authService.login(username: "test", password: "pass")
            #expect(authService.isAuthenticated)

            await authService.deleteAccount(password: "wrongpass")

            #expect(authService.isAuthenticated == true)
            #expect(authService.currentUser != nil)
            #expect(authService.errorMessage == "Incorrect password.")
        }

        @Test func `delete social account success clears session`() async {
            // Log in, then mock getMe to return social user, then delete
            MockURLProtocol.requestHandler = { request in
                let path = request.url!.path
                let json: String

                if path.contains("auth/login") {
                    json = Fixtures.tokenPairJSON
                } else if path.contains("auth/me"), request.httpMethod == "GET" {
                    json = Fixtures.socialUserJSON
                } else if path.contains("auth/me"), request.httpMethod == "DELETE" {
                    json = Fixtures.deleteAccountSuccessJSON
                } else {
                    Issue.record("Unexpected request: \(request.httpMethod ?? "?") \(path)")
                    json = "{}"
                }

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                return (response, json.data(using: .utf8)!)
            }

            await authService.login(username: "test", password: "pass")
            #expect(authService.isAuthenticated)
            #expect(authService.currentUser?.isSocialOnly == true)

            await authService.deleteAccountSocial()

            #expect(authService.isAuthenticated == false)
            #expect(authService.currentUser == nil)
            #expect(authService.errorMessage == nil)
        }

        @Test func `session restore with expired refresh logs out`() async throws {
            // Pre-save tokens to keychain
            try keychainService.saveString("expired-access", forKey: KeychainService.accessTokenKey)
            try keychainService.saveString("expired-refresh", forKey: KeychainService.refreshTokenKey)

            // getMe returns 401 → APIClient calls tokenRefresher → refreshAccessToken
            // calls auth/refresh which also returns 401 → refresher throws → APIClient
            // throws → restoreSession's outer catch also tries refresh → fails → logout
            MockURLProtocol.requestHandler = { request in
                let path = request.url!.path

                if path.contains("auth/refresh") {
                    // Refresh token is also expired
                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 401,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, Fixtures.apiErrorJSON.data(using: .utf8)!)
                } else {
                    // getMe and anything else returns 401
                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 401,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, Fixtures.apiErrorJSON.data(using: .utf8)!)
                }
            }

            await authService.restoreSession()

            #expect(authService.isAuthenticated == false)
            #expect(authService.currentUser == nil)
        }
    }
}
