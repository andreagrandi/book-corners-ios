//
//  AuthServiceSessionTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

extension SerialNetworkTests {
    @MainActor struct AuthServiceSessionTests {
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

        @Test func `session restore with valid token`() async throws {
            try keychainService.saveString("saved-access", forKey: KeychainService.accessTokenKey)
            try keychainService.saveString("saved-refresh", forKey: KeychainService.refreshTokenKey)

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
            #expect(authService.canAccessAdmin == false)
        }

        @Test func `session restore with staff token grants admin access`() async throws {
            try keychainService.saveString("saved-access", forKey: KeychainService.accessTokenKey)
            try keychainService.saveString("saved-refresh", forKey: KeychainService.refreshTokenKey)

            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                return (response, Fixtures.staffUserJSON.data(using: .utf8)!)
            }

            await authService.restoreSession()

            #expect(authService.isAuthenticated)
            #expect(authService.currentUser?.username == "moderator")
            #expect(authService.canAccessAdmin == true)
        }

        @Test func `session restore with expired token refreshes`() async throws {
            try keychainService.saveString("expired-access", forKey: KeychainService.accessTokenKey)
            try keychainService.saveString("valid-refresh", forKey: KeychainService.refreshTokenKey)
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
                    }

                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 200,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, Fixtures.userJSON.data(using: .utf8)!)
                } else if path.contains("auth/refresh") {
                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 200,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, Data(#"{"access": "new-access-token"}"#.utf8))
                } else {
                    Issue.record("Unexpected request: \(path)")
                    let response = HTTPURLResponse(
                        url: request.url!, statusCode: 500,
                        httpVersion: nil, headerFields: nil,
                    )!
                    return (response, Data("{}".utf8))
                }
            }

            await authService.restoreSession()

            #expect(authService.isAuthenticated)
            #expect(authService.currentUser?.username == "booklover")
        }

        @Test func `session restore with expired refresh logs out`() async throws {
            try keychainService.saveString("expired-access", forKey: KeychainService.accessTokenKey)
            try keychainService.saveString("expired-refresh", forKey: KeychainService.refreshTokenKey)

            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 401,
                    httpVersion: nil, headerFields: nil,
                )!
                return (response, Fixtures.apiErrorJSON.data(using: .utf8)!)
            }

            await authService.restoreSession()

            #expect(authService.isAuthenticated == false)
            #expect(authService.currentUser == nil)
        }
    }
}
