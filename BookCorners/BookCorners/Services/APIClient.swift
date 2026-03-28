//
//  APIClient.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation
import SwiftUI

class APIClient: APIClientProtocol {
    let baseURL: URL
    var accessToken: String?
    var tokenRefresher: (() async throws -> String)?

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = URL(
            string: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "https://bookcorners.org/api/v1/",
        )!,
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

        let isAuthEndpoint = url.path.contains("auth/refresh") || url.path.contains("auth/login") || url.path.contains("auth/register") || url.path.contains("auth/social")
        if httpResponse.statusCode == 401, let refresher = tokenRefresher, !isAuthEndpoint {
            let newToken = try await refresher()
            accessToken = newToken

            // Rebuild the request with the new token
            urlRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")

            // Retry once
            let (retryData, retryResponse) = try await session.data(for: urlRequest)

            guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                throw APIClientError.networkError(URLError(.badServerResponse))
            }
            guard (200 ... 299).contains(retryHttpResponse.statusCode) else {
                throw try parseError(statusCode: retryHttpResponse.statusCode, data: retryData)
            }

            do {
                return try decoder.decode(T.self, from: retryData)
            } catch {
                throw APIClientError.decodingError(error)
            }
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

    private func multipartRequest<T: Decodable>(
        path: String,
        multipart: MultipartFormData,
    ) async throws -> T {
        let url = baseURL.appending(path: path)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(multipart.contentType, forHTTPHeaderField: "Content-Type")
        if let accessToken {
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = multipart.encode()

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.networkError(URLError(.badServerResponse))
        }
        if httpResponse.statusCode == 401, let refresher = tokenRefresher {
            let newToken = try await refresher()
            accessToken = newToken

            urlRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")

            let (retryData, retryResponse) = try await session.data(for: urlRequest)

            guard let retryHttpResponse = retryResponse as? HTTPURLResponse else {
                throw APIClientError.networkError(URLError(.badServerResponse))
            }
            guard (200 ... 299).contains(retryHttpResponse.statusCode) else {
                throw try parseError(statusCode: retryHttpResponse.statusCode, data: retryData)
            }

            do {
                return try decoder.decode(T.self, from: retryData)
            } catch {
                throw APIClientError.decodingError(error)
            }
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw try parseError(statusCode: httpResponse.statusCode, data: data)
        }

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

    // MARK: - Read Endpoints

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
        postalCode: String? = nil,
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
        if let postalCode { items.append(URLQueryItem(name: "postal_code", value: postalCode)) }
        if let lat { items.append(URLQueryItem(name: "lat", value: String(lat))) }
        if let lng { items.append(URLQueryItem(name: "lng", value: String(lng))) }
        if let radiusKm { items.append(URLQueryItem(name: "radius_km", value: String(radiusKm))) }
        if let hasPhoto { items.append(URLQueryItem(name: "has_photo", value: String(hasPhoto))) }

        return try await request(path: "libraries/", queryItems: items)
    }

    func login(username: String, password: String) async throws -> TokenPair {
        try await request(path: "auth/login", method: "POST", body: LoginRequest(username: username, password: password))
    }

    func getMe() async throws -> User {
        try await request(path: "auth/me", method: "GET")
    }

    func register(username: String, password: String, email: String) async throws -> TokenPair {
        try await request(
            path: "auth/register", method: "POST",
            body: RegisterRequest(username: username, password: password, email: email),
        )
    }

    func refreshToken(refreshToken: String) async throws -> AccessToken {
        try await request(path: "auth/refresh", method: "POST", body: RefreshRequest(refresh: refreshToken))
    }

    func socialLogin(provider: String, idToken: String, firstName: String? = nil, lastName: String? = nil) async throws -> TokenPair {
        try await request(
            path: "auth/social",
            method: "POST",
            body: SocialLoginRequest(provider: provider, idToken: idToken, firstName: firstName, lastName: lastName),
        )
    }

    // MARK: - Write Endpoints (multipart)

    func submitLibrary(
        address: String,
        city: String,
        country: String,
        latitude: Double,
        longitude: Double,
        photo: Data,
        name: String? = nil,
        description: String? = nil,
        postalCode: String? = nil,
        wheelchairAccessible: String? = nil,
        capacity: Int? = nil,
        isIndoor: Bool? = nil,
        isLit: Bool? = nil,
        website: String? = nil,
        contact: String? = nil,
        operatorName: String? = nil,
        brand: String? = nil,
    ) async throws -> Library {
        var multipart = MultipartFormData()

        // Required fields
        multipart.addField(name: "address", value: address)
        multipart.addField(name: "city", value: city)
        multipart.addField(name: "country", value: country)
        multipart.addField(name: "latitude", value: String(latitude))
        multipart.addField(name: "longitude", value: String(longitude))
        multipart.addFile(name: "photo", fileName: "photo.jpg", mimeType: "image/jpeg", data: photo)

        // Optional fields
        if let name { multipart.addField(name: "name", value: name) }
        if let description { multipart.addField(name: "description", value: description) }
        if let postalCode { multipart.addField(name: "postal_code", value: postalCode) }
        if let wheelchairAccessible { multipart.addField(name: "wheelchair_accessible", value: wheelchairAccessible) }
        if let capacity { multipart.addField(name: "capacity", value: String(capacity)) }
        if let isIndoor { multipart.addField(name: "is_indoor", value: String(isIndoor)) }
        if let isLit { multipart.addField(name: "is_lit", value: String(isLit)) }
        if let website { multipart.addField(name: "website", value: website) }
        if let contact { multipart.addField(name: "contact", value: contact) }
        if let operatorName { multipart.addField(name: "operator", value: operatorName) }
        if let brand { multipart.addField(name: "brand", value: brand) }

        return try await multipartRequest(path: "libraries/", multipart: multipart)
    }

    func reportLibrary(
        slug: String,
        reason: String,
        details: String? = nil,
        photo: Data? = nil,
    ) async throws -> Report {
        var multipart = MultipartFormData()

        // Required fields
        multipart.addField(name: "reason", value: reason)

        // Optional fields
        if let details { multipart.addField(name: "details", value: details) }
        if let photo { multipart.addFile(name: "photo", fileName: "photo.jpg", mimeType: "image/jpeg", data: photo) }

        return try await multipartRequest(path: "libraries/\(slug)/report", multipart: multipart)
    }

    func addPhoto(
        slug: String,
        photo: Data,
        caption: String? = nil,
    ) async throws -> LibraryPhoto {
        var multipart = MultipartFormData()

        // Required fields
        multipart.addFile(name: "photo", fileName: "photo.jpg", mimeType: "image/jpeg", data: photo)

        // Optional fields
        if let caption { multipart.addField(name: "caption", value: caption) }

        return try await multipartRequest(path: "libraries/\(slug)/photo", multipart: multipart)
    }

    // MARK: - Account Management

    func deleteAccount(password: String? = nil, confirm: Bool? = nil) async throws -> MessageResponse {
        try await request(
            path: "auth/me",
            method: "DELETE",
            body: DeleteAccountRequest(password: password, confirm: confirm),
        )
    }
}

extension EnvironmentValues {
    @Entry var apiClient: APIClient = .init()
}
