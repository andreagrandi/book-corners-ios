//
//  ModerationAPIClientTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

extension SerialNetworkTests {
    @MainActor struct ModerationAPIClientTests {
        let client: APIClient

        init() {
            client = APIClient(
                baseURL: URL(string: "https://test.example.com/api/v1/")!,
                session: MockURLProtocol.mockSession,
            )
        }

        @Test func `get moderation summary returns decoded response`() async throws {
            client.accessToken = "staff-token"

            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "GET")
                #expect(request.url?.path == "/api/v1/libraries/moderation/summary")
                #expect(request.allHTTPHeaderFields?["Authorization"] == "Bearer staff-token")

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.moderationSummaryJSON.data(using: .utf8)!
                return (response, data)
            }

            let summary = try await client.getModerationSummary()
            #expect(summary.totalPending == 11)
            #expect(summary.totalLibraries == 350)
        }

        @Test func `get moderation libraries builds query parameters`() async throws {
            MockURLProtocol.requestHandler = { request in
                let url = request.url!
                #expect(request.httpMethod == "GET")
                #expect(url.path == "/api/v1/libraries/moderation")
                #expect(Self.queryValue("status", in: url) == "pending")
                #expect(Self.queryValue("q", in: url) == "Florence")
                #expect(Self.queryValue("country", in: url) == "IT")
                #expect(Self.queryValue("source", in: url) == "user")
                #expect(Self.queryValue("page", in: url) == "2")
                #expect(Self.queryValue("page_size", in: url) == "10")

                let response = HTTPURLResponse(
                    url: url, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.moderationLibraryListJSON.data(using: .utf8)!
                return (response, data)
            }

            let result = try await client.getModerationLibraries(
                request: ModerationLibraryListRequest(
                    status: .pending,
                    query: "Florence",
                    country: "IT",
                    source: "user",
                    page: 2,
                    pageSize: 10,
                ),
            )
            #expect(result.items.count == 1)
            #expect(result.items[0].createdBy?.username == "janedoe")
        }

        @Test func `get moderation library uses detail path`() async throws {
            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "GET")
                #expect(request.url?.path == "/api/v1/libraries/moderation/florence-via-rosina-15-corner-books")

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.moderationLibraryJSON.data(using: .utf8)!
                return (response, data)
            }

            let library = try await client.getModerationLibrary(slug: "florence-via-rosina-15-corner-books")
            #expect(library.slug == "florence-via-rosina-15-corner-books")
            #expect(library.status == .pending)
        }

        @Test func `update moderation library sends patch payload`() async throws {
            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "PATCH")
                #expect(request.url?.path == "/api/v1/libraries/moderation/florence-via-rosina-15-corner-books")
                let payload = try Self.jsonPayload(from: request)
                #expect(payload["status"] as? String == "rejected")
                #expect(payload["rejection_reason"] as? String == "Duplicate submission.")

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.moderationLibraryJSON.data(using: .utf8)!
                return (response, data)
            }

            let library = try await client.updateModerationLibrary(
                slug: "florence-via-rosina-15-corner-books",
                status: .rejected,
                rejectionReason: "Duplicate submission.",
            )
            #expect(library.id == 42)
        }

        @Test func `get moderation reports builds query parameters`() async throws {
            MockURLProtocol.requestHandler = { request in
                let url = request.url!
                #expect(request.httpMethod == "GET")
                #expect(url.path == "/api/v1/libraries/moderation/reports")
                #expect(Self.queryValue("status", in: url) == "open")
                #expect(Self.queryValue("reason", in: url) == "damaged")
                #expect(Self.queryValue("page", in: url) == "3")
                #expect(Self.queryValue("page_size", in: url) == "15")

                let response = HTTPURLResponse(
                    url: url, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.moderationReportListJSON.data(using: .utf8)!
                return (response, data)
            }

            let result = try await client.getModerationReports(
                request: ModerationReportListRequest(
                    status: .open,
                    reason: .damaged,
                    page: 3,
                    pageSize: 15,
                ),
            )
            #expect(result.items[0].id == 7)
            #expect(result.items[0].reason == .damaged)
        }

        @Test func `update moderation report sends patch payload`() async throws {
            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "PATCH")
                #expect(request.url?.path == "/api/v1/libraries/moderation/reports/7")
                let payload = try Self.jsonPayload(from: request)
                #expect(payload["status"] as? String == "resolved")

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.moderationReportJSON.data(using: .utf8)!
                return (response, data)
            }

            let report = try await client.updateModerationReport(id: 7, status: .resolved)
            #expect(report.id == 7)
        }

        @Test func `get moderation photos builds query parameters`() async throws {
            MockURLProtocol.requestHandler = { request in
                let url = request.url!
                #expect(request.httpMethod == "GET")
                #expect(url.path == "/api/v1/libraries/moderation/photos")
                #expect(Self.queryValue("status", in: url) == "pending")
                #expect(Self.queryValue("page", in: url) == "4")
                #expect(Self.queryValue("page_size", in: url) == "12")

                let response = HTTPURLResponse(
                    url: url, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.moderationPhotoListJSON.data(using: .utf8)!
                return (response, data)
            }

            let result = try await client.getModerationPhotos(
                request: ModerationPhotoListRequest(
                    status: .pending,
                    page: 4,
                    pageSize: 12,
                ),
            )
            #expect(result.items[0].id == 12)
            #expect(result.items[0].status == .pending)
        }

        @Test func `update moderation photo sends patch payload`() async throws {
            MockURLProtocol.requestHandler = { request in
                #expect(request.httpMethod == "PATCH")
                #expect(request.url?.path == "/api/v1/libraries/moderation/photos/12")
                let payload = try Self.jsonPayload(from: request)
                #expect(payload["status"] as? String == "approved")

                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.moderationPhotoJSON.data(using: .utf8)!
                return (response, data)
            }

            let photo = try await client.updateModerationPhoto(id: 12, status: .approved)
            #expect(photo.id == 12)
        }

        @Test func `staff forbidden response throws forbidden`() async {
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 403,
                    httpVersion: nil, headerFields: nil,
                )!
                let data = Fixtures.staffAccessRequiredJSON.data(using: .utf8)!
                return (response, data)
            }

            do {
                _ = try await client.getModerationSummary()
                Issue.record("Expected forbidden error")
            } catch {
                guard case let APIClientError.forbidden(message) = error else {
                    Issue.record("Expected .forbidden, got \(error)")
                    return
                }
                #expect(message == "Staff access required.")
            }
        }

        private static func queryValue(_ name: String, in url: URL) -> String? {
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first { $0.name == name }?
                .value
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
                let readCount = buffer.withUnsafeMutableBufferPointer { pointer in
                    stream.read(pointer.baseAddress!, maxLength: pointer.count)
                }
                if readCount < 0 {
                    throw stream.streamError ?? URLError(.cannotDecodeContentData)
                }
                if readCount == 0 {
                    break
                }
                data.append(buffer, count: readCount)
            }
            return data
        }
    }
}
