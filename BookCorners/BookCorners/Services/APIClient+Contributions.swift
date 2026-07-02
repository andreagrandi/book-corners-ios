//
//  APIClient+Contributions.swift
//  BookCorners
//

import Foundation

extension APIClient {
    func getContributionLibraries(page: Int = 1, pageSize: Int = 20) async throws -> ContributionLibraryListResponse {
        try await request(
            path: "libraries/mine",
            queryItems: contributionPaginationItems(page: page, pageSize: pageSize),
            cachePolicy: .reloadIgnoringLocalCacheData,
        )
    }

    func getContributionReports(page: Int = 1, pageSize: Int = 20) async throws -> ContributionReportListResponse {
        try await request(
            path: "libraries/mine/reports",
            queryItems: contributionPaginationItems(page: page, pageSize: pageSize),
            cachePolicy: .reloadIgnoringLocalCacheData,
        )
    }

    func getContributionPhotos(page: Int = 1, pageSize: Int = 20) async throws -> ContributionPhotoListResponse {
        try await request(
            path: "libraries/mine/photos",
            queryItems: contributionPaginationItems(page: page, pageSize: pageSize),
            cachePolicy: .reloadIgnoringLocalCacheData,
        )
    }

    private func contributionPaginationItems(page: Int, pageSize: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize)),
        ]
    }
}
