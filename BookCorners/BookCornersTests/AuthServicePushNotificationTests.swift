//
//  AuthServicePushNotificationTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

extension SerialNetworkTests {
    @MainActor struct AuthServicePushNotificationTests {
        let client: APIClient
        let keychainService: KeychainService

        init() {
            client = APIClient(
                baseURL: URL(string: "https://test.example.com/api/v1/")!,
                session: MockURLProtocol.mockSession,
            )
            keychainService = KeychainService(service: "test.\(UUID())")
        }

        @Test func `login registers remote notifications after authentication`() async {
            let pushService = StubPushNotificationService()
            let authService = AuthService(
                apiClient: client,
                keychainService: keychainService,
                pushNotificationService: pushService,
            )
            mockSuccessfulLogin(userJSON: Fixtures.userJSON)

            await authService.login(username: "test", password: "pass")

            #expect(pushService.registerCallCount == 1)
            #expect(pushService.unregisterCallCount == 0)
        }

        @Test func `session restore registers remote notifications`() async throws {
            let pushService = StubPushNotificationService()
            let authService = AuthService(
                apiClient: client,
                keychainService: keychainService,
                pushNotificationService: pushService,
            )
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

            #expect(pushService.registerCallCount == 1)
            #expect(pushService.unregisterCallCount == 0)
        }

        @Test func `logout unregisters remote notifications before clearing session`() async {
            let pushService = StubPushNotificationService()
            let authService = AuthService(
                apiClient: client,
                keychainService: keychainService,
                pushNotificationService: pushService,
            )
            mockSuccessfulLogin(userJSON: Fixtures.userJSON)

            await authService.login(username: "test", password: "pass")
            await authService.logout()

            #expect(pushService.registerCallCount == 1)
            #expect(pushService.unregisterCallCount == 1)
            #expect(authService.isAuthenticated == false)
        }

        private func mockSuccessfulLogin(userJSON: String) {
            MockURLProtocol.requestHandler = { request in
                let path = request.url!.path
                let json: String

                if path.contains("auth/login") {
                    json = Fixtures.tokenPairJSON
                } else if path.contains("auth/me") {
                    json = userJSON
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
        }
    }
}

@MainActor
private final class StubPushNotificationService: PushNotificationManaging {
    var registerCallCount = 0
    var unregisterCallCount = 0

    func registerForRemoteNotificationsIfNeeded() async {
        registerCallCount += 1
    }

    func unregisterCurrentDevice() async {
        unregisterCallCount += 1
    }
}
