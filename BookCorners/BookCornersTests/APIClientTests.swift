//
//  APIClientTests.swift
//  BookCornersTests
//
//  Created by Andrea Grandi on 12/03/26.
//

@testable import BookCorners
import Foundation
import Testing

private nonisolated enum APIClientTestError: Error {
    case missingRequestBody
    case invalidRequestBody
    case requestBodyStreamFailed
}

private nonisolated func requestBodyData(from request: URLRequest) throws -> Data {
    if let body = request.httpBody {
        return body
    }
    guard let stream = request.httpBodyStream else {
        throw APIClientTestError.missingRequestBody
    }

    stream.open()
    defer { stream.close() }

    var body = Data()
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
    defer { buffer.deallocate() }

    while stream.hasBytesAvailable {
        let count = stream.read(buffer, maxLength: 4096)
        if count < 0 {
            throw APIClientTestError.requestBodyStreamFailed
        }
        if count == 0 {
            break
        }
        body.append(buffer, count: count)
    }
    return body
}

private nonisolated func requestJSONBody(from request: URLRequest) throws -> [String: Any] {
    let data = try requestBodyData(from: request)
    guard let body = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw APIClientTestError.invalidRequestBody
    }
    return body
}

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
                request: LibrarySearchRequest(
                    page: 2,
                    pageSize: 10,
                    query: "berlin",
                    country: "DE",
                ),
            )
        }

        // MARK: - Registration Agreement

        @Test func `registration encodes current accepted agreement and decodes old server response`() async throws {
            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "POST")
                #expect(request.url?.path.hasSuffix("/auth/register") == true)
                let body = try requestJSONBody(from: request)
                #expect(body["contributor_agreement_version"] as? String == "1.0")
                #expect(body["contributor_agreement_accepted"] as? Bool == true)

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: nil,
                )!
                return (response, Fixtures.tokenPairJSON.data(using: .utf8)!)
            }

            let response = try await client.register(
                username: "new-reader",
                password: "StrongPass123!",
                email: "reader@example.com",
                contributorAgreement: ContributorAgreement.currentAcceptance,
            )

            #expect(response.access.contains("access"))
        }

        @Test func `registration compatibility request omits missing agreement fields`() async throws {
            MockURLProtocol.requestHandler = { request in
                let body = try requestJSONBody(from: request)
                #expect(body["contributor_agreement_version"] == nil)
                #expect(body["contributor_agreement_accepted"] == nil)

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: nil,
                )!
                return (response, Fixtures.tokenPairJSON.data(using: .utf8)!)
            }

            _ = try await client.register(
                username: "legacy-reader",
                password: "StrongPass123!",
                email: "legacy@example.com",
                contributorAgreement: nil,
            )
        }

        @Test func `registration encodes accepted stale agreement for server validation`() async throws {
            MockURLProtocol.requestHandler = { request in
                let body = try requestJSONBody(from: request)
                #expect(body["contributor_agreement_version"] as? String == "0.9")
                #expect(body["contributor_agreement_accepted"] as? Bool == true)

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: nil,
                )!
                return (response, Fixtures.tokenPairJSON.data(using: .utf8)!)
            }

            _ = try await client.register(
                username: "stale-reader",
                password: "StrongPass123!",
                email: "stale@example.com",
                contributorAgreement: ContributorAgreement.Acceptance(
                    version: "0.9",
                    accepted: true,
                ),
            )
        }

        @Test func `registration encodes false current agreement for server validation`() async throws {
            MockURLProtocol.requestHandler = { request in
                let body = try requestJSONBody(from: request)
                #expect(body["contributor_agreement_version"] as? String == "1.0")
                #expect(body["contributor_agreement_accepted"] as? Bool == false)

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: nil,
                )!
                return (response, Fixtures.tokenPairJSON.data(using: .utf8)!)
            }

            _ = try await client.register(
                username: "declined-reader",
                password: "StrongPass123!",
                email: "declined@example.com",
                contributorAgreement: ContributorAgreement.Acceptance(
                    version: ContributorAgreement.currentVersion,
                    accepted: false,
                ),
            )
        }

        @Test func `social registration encodes acceptance and decodes new server response`() async throws {
            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "POST")
                #expect(request.url?.path.hasSuffix("/auth/social") == true)
                let body = try requestJSONBody(from: request)
                #expect(body["provider"] as? String == "apple")
                #expect(body["contributor_agreement_version"] as? String == "1.0")
                #expect(body["contributor_agreement_accepted"] as? Bool == true)

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil,
                )!
                let data = Data("""
                {"access":"new-access","refresh":"new-refresh","account_created":true}
                """.utf8)
                return (response, data)
            }

            let tokenPair = try await client.socialLogin(
                provider: "apple",
                idToken: "apple-identity-token-long-enough",
                firstName: "Jane",
                lastName: "Doe",
                contributorAgreement: ContributorAgreement.currentAcceptance,
            )

            #expect(tokenPair.access == "new-access")
            #expect(tokenPair.refresh == "new-refresh")
        }

        @Test func `social login omits acceptance and decodes old server response`() async throws {
            MockURLProtocol.requestHandler = { request in
                let body = try requestJSONBody(from: request)
                #expect(body["provider"] as? String == "google")
                #expect(body["contributor_agreement_version"] == nil)
                #expect(body["contributor_agreement_accepted"] == nil)

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil,
                )!
                return (response, Fixtures.tokenPairJSON.data(using: .utf8)!)
            }

            let tokenPair = try await client.socialLogin(
                provider: "google",
                idToken: "google-identity-token-long-enough",
                contributorAgreement: nil,
            )

            #expect(tokenPair.access.contains("access"))
        }

        @Test func `new server social login ignores additive account created field`() async throws {
            MockURLProtocol.requestHandler = { request in
                let body = try requestJSONBody(from: request)
                #expect(body["contributor_agreement_version"] == nil)
                #expect(body["contributor_agreement_accepted"] == nil)

                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil,
                )!
                let data = Data("""
                {"access":"existing-access","refresh":"existing-refresh","account_created":false}
                """.utf8)
                return (response, data)
            }

            let tokenPair = try await client.socialLogin(
                provider: "apple",
                idToken: "existing-identity-token-long-enough",
                contributorAgreement: nil,
            )

            #expect(tokenPair.access == "existing-access")
            #expect(tokenPair.refresh == "existing-refresh")
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
                let data = Data("not json at all".utf8)
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

        // MARK: - Favourites

        @Test func `get favourites returns decoded response`() async throws {
            client.accessToken = "test-token"

            MockURLProtocol.requestHandler = { request in
                let url = request.url!
                #expect(url.path.contains("libraries/favourites"))
                #expect(request.httpMethod == "GET")
                let query = url.query ?? ""
                #expect(query.contains("page=1"))
                #expect(query.contains("page_size=20"))

                let response = HTTPURLResponse(
                    url: url, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.favouritesListJSON.data(using: .utf8)!
                return (response, data)
            }

            let result = try await client.getFavourites(page: 1, pageSize: 20)
            #expect(result.items.count == 1)
            #expect(result.items[0].isFavourited == true)
        }

        @Test func `add favourite sends POST request`() async throws {
            client.accessToken = "test-token"

            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "POST")
                #expect(request.url!.path.contains("libraries/test-slug/favourite"))

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 201,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.favouriteAddedJSON.data(using: .utf8)!
                return (response, data)
            }

            let result = try await client.addFavourite(slug: "test-slug")
            #expect(result.message == "Library added to favourites.")
        }

        @Test func `remove favourite sends DELETE request`() async throws {
            client.accessToken = "test-token"

            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "DELETE")
                #expect(request.url!.path.contains("libraries/test-slug/favourite"))

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 204,
                    httpVersion: nil, headerFields: nil,
                )!
                return (response, Data())
            }

            try await client.removeFavourite(slug: "test-slug")
        }

        // MARK: - Contributions

        @Test func `get contribution libraries returns decoded response`() async throws {
            client.accessToken = "test-token"

            MockURLProtocol.requestHandler = { request in
                let url = request.url!
                #expect(url.path.contains("libraries/mine"))
                #expect(request.httpMethod == "GET")
                let query = url.query ?? ""
                #expect(query.contains("page=1"))
                #expect(query.contains("page_size=20"))

                let response = HTTPURLResponse(
                    url: url, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.contributionLibrariesListJSON.data(using: .utf8)!
                return (response, data)
            }

            let result = try await client.getContributionLibraries(page: 1, pageSize: 20)
            #expect(result.items.count == 1)
            #expect(result.items[0].status == .approved)
            #expect(result.items[0].isFavourited == true)
        }

        @Test func `get contribution reports returns decoded response`() async throws {
            client.accessToken = "test-token"

            MockURLProtocol.requestHandler = { request in
                let url = request.url!
                #expect(url.path.contains("libraries/mine/reports"))
                #expect(request.httpMethod == "GET")

                let response = HTTPURLResponse(
                    url: url, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.contributionReportsListJSON.data(using: .utf8)!
                return (response, data)
            }

            let result = try await client.getContributionReports(page: 1, pageSize: 20)
            #expect(result.items.count == 1)
            #expect(result.items[0].reason == .damaged)
            #expect(result.items[0].status == .open)
            #expect(result.items[0].library.slug == "community-library-berlin")
        }

        @Test func `get contribution photos returns decoded response`() async throws {
            client.accessToken = "test-token"

            MockURLProtocol.requestHandler = { request in
                let url = request.url!
                #expect(url.path.contains("libraries/mine/photos"))
                #expect(request.httpMethod == "GET")

                let response = HTTPURLResponse(
                    url: url, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.contributionPhotosListJSON.data(using: .utf8)!
                return (response, data)
            }

            let result = try await client.getContributionPhotos(page: 1, pageSize: 20)
            #expect(result.items.count == 1)
            #expect(result.items[0].caption == "Front view")
            #expect(result.items[0].status == .pending)
            #expect(result.items[0].library.slug == "community-library-berlin")
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
