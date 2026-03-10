//
//  APIClient.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

class APIClient {
    let baseURL: URL
    var accessToken: String?

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = URL(string: "https://bookcorners.org/api/v1/")!,
        session: URLSession = .shared,
    ) {
        self.baseURL = baseURL
        self.session = session

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
    ) async throws -> T {
        // Build URL with query parameters
        var url = baseURL.appending(path: path)
        if let queryItems, !queryItems.isEmpty {
            url.append(queryItems: queryItems)
        }

        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        // Attach auth token if available
        if let accessToken {
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        // Encode body for POST/PUT/PATCH
        if let body {
            urlRequest.httpBody = try encoder.encode(body)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // Make the network call
        let (data, response) = try await session.data(for: urlRequest)

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.networkError(
                URLError(.badServerResponse),
            )
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw try parseError(statusCode: httpResponse.statusCode, data: data)
        }

        // Decode and return
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIClientError.decodingError(error)
        }
    }

    private func parseError(statusCode: Int, data: Data) throws -> APIClientError {
        let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
        let message = errorResponse?.message ?? "Unknown error"

        switch statusCode {
        case 401:
            return .unauthorized
        case 429:
            let retryAfter = errorResponse?.details?["retry_after"].flatMap(Int.init)
            return .rateLimited(retryAfter: retryAfter)
        default:
            return .httpError(statusCode: statusCode, message: message)
        }
    }

    func getLibrary(slug: String) async throws -> Library {
        try await request(path: "libraries/\(slug)")
    }

    func getStatistics() async throws -> Statistics {
        try await request(path: "statistics/")
    }

    func getLatestLibraries(limit: Int = 10, hasPhoto: Bool? = nil) async throws -> LatestLibrariesResponse {
        var items = [URLQueryItem(name: "limit", value: String(limit))]
        if let hasPhoto {
            items.append(URLQueryItem(name: "has_photo", value: String(hasPhoto)))
        }

        return try await request(path: "libraries/latest", queryItems: items)
    }

    func getLibraries(
        page: Int = 1,
        pageSize: Int = 20,
        query: String? = nil,
        city: String? = nil,
        country: String? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        radiusKm: Int? = nil,
        hasPhoto: Bool? = nil,
    ) async throws -> LibraryListResponse {
        var items = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize)),
        ]
        if let query { items.append(URLQueryItem(name: "q", value: query)) }
        if let city { items.append(URLQueryItem(name: "city", value: city)) }
        if let country { items.append(URLQueryItem(name: "country", value: country)) }
        if let lat { items.append(URLQueryItem(name: "lat", value: String(lat))) }
        if let lng { items.append(URLQueryItem(name: "lng", value: String(lng))) }
        if let radiusKm { items.append(URLQueryItem(name: "radius_km", value: String(radiusKm))) }
        if let hasPhoto { items.append(URLQueryItem(name: "has_photo", value: String(hasPhoto))) }

        return try await request(path: "libraries/", queryItems: items)
    }
}
