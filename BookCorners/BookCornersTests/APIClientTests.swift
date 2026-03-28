//
//  APIClientTests.swift
//  BookCornersTests
//
//  Created by Andrea Grandi on 12/03/26.
//

@testable import BookCorners
import Foundation
import Testing

extension SerialNetworkTests {
    @MainActor struct APIClientTests {
        let client: APIClient

        init() {
            client = APIClient(
                baseURL: URL(string: "https://test.example.com/api/v1/")!,
                session: MockURLProtocol.mockSession,
            )
        }

        @Test func `get latest libraries returns decoded response`() async throws {
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil,
                )!
                let data = Fixtures.latestLibrariesJSON.data(using: .utf8)!
                return (response, data)
            }

            let result = try await client.getLatestLibraries()
            #expect(result.items.count == 1)
            #expect(result.items[0].slug == "community-library-berlin")
        }

        @Test func `get library returns decoded response`() async throws {
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil,
                )!
                let data = Fixtures.libraryJSON.data(using: .utf8)!
                return (response, data)
            }

            let result = try await client.getLibrary(slug: "community-library-berlin")
            #expect(result.slug == "community-library-berlin")
            #expect(result.id == 1)
            #expect(result.name == "Community Library Berlin")
        }

        @Test func `get libraries builds query parameters`() async throws {
            MockURLProtocol.requestHandler = { request in
                let url = request.url!
                let query = url.query ?? ""
                #expect(query.contains("page=2"))
                #expect(query.contains("page_size=10"))
                #expect(query.contains("q=berlin"))
                #expect(query.contains("country=DE"))

                let response = HTTPURLResponse(
                    url: url, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.libraryListJSON.data(using: .utf8)!
                return (response, data)
            }

            _ = try await client.getLibraries(
                page: 2, pageSize: 10, query: "berlin", country: "DE",
            )
        }

        // MARK: - Error Handling

        @Test func `unauthorized response throws unauthorized`() async {
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 401,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.apiErrorJSON.data(using: .utf8)!
                return (response, data)
            }

            do {
                _ = try await client.getLibrary(slug: "test")
                Issue.record("Expected unauthorized error")
            } catch {
                guard case APIClientError.unauthorized = error else {
                    Issue.record("Expected .unauthorized, got \(error)")
                    return
                }
            }
        }

        @Test func `rate limited response throws rate limited`() async {
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 429,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.rateLimitErrorJSON.data(using: .utf8)!
                return (response, data)
            }

            do {
                _ = try await client.getLibrary(slug: "test")
                Issue.record("Expected rate limited error")
            } catch {
                guard case let APIClientError.rateLimited(retryAfter) = error else {
                    Issue.record("Expected .rateLimited, got \(error)")
                    return
                }
                #expect(retryAfter == 30)
            }
        }

        @Test func `not found response throws http error`() async {
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 404,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.apiErrorJSON.data(using: .utf8)!
                return (response, data)
            }

            do {
                _ = try await client.getLibrary(slug: "nonexistent")
                Issue.record("Expected HTTP error")
            } catch {
                guard case let APIClientError.httpError(statusCode, _) = error else {
                    Issue.record("Expected .httpError, got \(error)")
                    return
                }
                #expect(statusCode == 404)
            }
        }

        @Test func `invalid JSON response throws decoding error`() async {
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = "not json at all".data(using: .utf8)!
                return (response, data)
            }

            do {
                _ = try await client.getLibrary(slug: "test")
                Issue.record("Expected decoding error")
            } catch {
                guard case APIClientError.decodingError = error else {
                    Issue.record("Expected .decodingError, got \(error)")
                    return
                }
            }
        }

        // MARK: - Auth Header

        @Test func `auth header sent when token set`() async throws {
            client.accessToken = "test-token-123"

            MockURLProtocol.requestHandler = { request in
                let authHeader = request.allHTTPHeaderFields?["Authorization"]
                #expect(authHeader == "Bearer test-token-123")

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.libraryJSON.data(using: .utf8)!
                return (response, data)
            }

            _ = try await client.getLibrary(slug: "test")
        }

        @Test func `no auth header when token nil`() async throws {
            client.accessToken = nil

            MockURLProtocol.requestHandler = { request in
                let authHeader = request.allHTTPHeaderFields?["Authorization"]
                #expect(authHeader == nil)

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.libraryJSON.data(using: .utf8)!
                return (response, data)
            }

            _ = try await client.getLibrary(slug: "test")
        }
    }
}
