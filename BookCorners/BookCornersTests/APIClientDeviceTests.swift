//
//  APIClientDeviceTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

extension SerialNetworkTests {
    @MainActor struct APIClientDeviceTests {
        let client: APIClient

        init() {
            client = APIClient(
                baseURL: URL(string: "https://test.example.com/api/v1/")!,
                session: MockURLProtocol.mockSession,
            )
        }

        @Test func `register device token sends POST request`() async throws {
            client.accessToken = "test-token"

            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "POST")
                #expect(request.url?.path == "/api/v1/auth/devices")
                #expect(request.allHTTPHeaderFields?["Authorization"] == "Bearer test-token")

                let payload = try Self.jsonPayload(from: request)
                #expect(payload["token"] as? String == "000fabff")
                #expect(payload["environment"] as? String == "sandbox")

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 201,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Data("""
                {"token":"000fabff","environment":"sandbox","is_active":true}
                """.utf8)
                return (response, data)
            }

            let result = try await client.registerDeviceToken(token: "000fabff", environment: .sandbox)
            #expect(result.token == "000fabff")
            #expect(result.environment == .sandbox)
            #expect(result.isActive == true)
        }

        @Test func `unregister device token sends DELETE request`() async throws {
            client.accessToken = "test-token"

            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "DELETE")
                #expect(request.url?.path == "/api/v1/auth/devices/000fabff")
                #expect(request.allHTTPHeaderFields?["Authorization"] == "Bearer test-token")

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 204,
                    httpVersion: nil, headerFields: nil,
                )!
                return (response, Data())
            }

            try await client.unregisterDeviceToken(token: "000fabff")
        }

        private static func jsonPayload(from request: URLRequest) throws -> [String: Any] {
            let body = try bodyData(from: request)
            let payload = try JSONSerialization.jsonObject(with: body) as? [String: Any]
            return try #require(payload)
        }

        private static func bodyData(from request: URLRequest) throws -> Data {
            if let body = request.httpBody {
                return body
            }

            let stream = try #require(request.httpBodyStream)
            stream.open()
            defer { stream.close() }

            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count < 0 {
                    throw stream.streamError ?? URLError(.cannotDecodeContentData)
                }
                if count == 0 {
                    break
                }
                data.append(buffer, count: count)
            }
            return data
        }
    }
}
