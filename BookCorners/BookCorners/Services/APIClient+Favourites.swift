//
//  APIClient+Favourites.swift
//  BookCorners
//

import Foundation

extension APIClient {
    func getFavourites(page: Int = 1, pageSize: Int = 20) async throws -> LibraryListResponse {
        let items = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize)),
        ]
        return try await request(
            path: "libraries/favourites",
            queryItems: items,
            cachePolicy: .reloadIgnoringLocalCacheData,
        )
    }

    func addFavourite(slug: String) async throws -> MessageResponse {
        try await request(path: "libraries/\(slug)/favourite", method: "POST")
    }

    func removeFavourite(slug: String) async throws {
        try await requestVoid(path: "libraries/\(slug)/favourite", method: "DELETE")
    }
}
