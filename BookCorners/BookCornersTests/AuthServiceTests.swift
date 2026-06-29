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
            #expect(authService.canAccessAdmin == false)
            #expect(authService.errorMessage == nil)
        }

        @Test func `staff login grants admin access`() async {
            MockURLProtocol.requestHandler = { request in
                let path = request.url!.path
                let json: String

                if path.contains("auth/login") {
                    json = Fixtures.tokenPairJSON
                } else if path.contains("auth/me") {
                    json = Fixtures.staffUserJSON
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

            await authService.login(username: "moderator", password: "pass")

            #expect(authService.isAuthenticated)
            #expect(authService.currentUser?.username == "moderator")
            #expect(authService.canAccessAdmin == true)
            #expect(authService.errorMessage == nil)
        }

        @Test func `non-staff login hides admin access`() async {
            MockURLProtocol.requestHandler = { request in
                let path = request.url!.path
                let json: String

                if path.contains("auth/login") {
                    json = Fixtures.tokenPairJSON
                } else if path.contains("auth/me") {
                    json = Fixtures.nonStaffUserJSON
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

            await authService.login(username: "reader", password: "pass")

            #expect(authService.isAuthenticated)
            #expect(authService.currentUser?.username == "reader")
            #expect(authService.canAccessAdmin == false)
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
                    json = Fixtures.staffUserJSON
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
            #expect(authService.canAccessAdmin == true)

            await authService.logout()

            #expect(authService.isAuthenticated == false)
            #expect(authService.currentUser == nil)
            #expect(authService.canAccessAdmin == false)
            #expect(authService.errorMessage == nil)
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
                    return (response, Data("{}".utf8))
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
    }
}
