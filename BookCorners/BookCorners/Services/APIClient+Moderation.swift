//
//  APIClient+Moderation.swift
//  BookCorners
//

import Foundation

extension APIClient {
    func getModerationSummary() async throws -> ModerationSummary {
        try await request(path: "libraries/moderation/summary")
    }

    func getModerationLibraries(
        request moderationRequest: ModerationLibraryListRequest = .init(),
    ) async throws -> ModerationLibraryListResponse {
        var items = [
            URLQueryItem(name: "status", value: moderationRequest.status.rawValue),
            URLQueryItem(name: "page", value: String(moderationRequest.page)),
            URLQueryItem(name: "page_size", value: String(moderationRequest.pageSize)),
        ]
        if let query = moderationRequest.query {
            items.append(URLQueryItem(name: "q", value: query))
        }
        if let country = moderationRequest.country {
            items.append(URLQueryItem(name: "country", value: country))
        }
        if let source = moderationRequest.source {
            items.append(URLQueryItem(name: "source", value: source))
        }

        return try await request(path: "libraries/moderation", queryItems: items)
    }

    func getModerationLibrary(slug: String) async throws -> ModerationLibrary {
        try await request(path: "libraries/moderation/\(slug)")
    }

    func updateModerationLibrary(
        slug: String,
        status: LibraryModerationStatus,
        rejectionReason: String? = nil,
    ) async throws -> ModerationLibrary {
        try await request(
            path: "libraries/moderation/\(slug)",
            method: "PATCH",
            body: LibraryModerationUpdateRequest(status: status, rejectionReason: rejectionReason),
        )
    }

    func getModerationReports(
        request moderationRequest: ModerationReportListRequest = .init(),
    ) async throws -> ModerationReportListResponse {
        let items = [
            URLQueryItem(name: "status", value: moderationRequest.status.rawValue),
            URLQueryItem(name: "reason", value: moderationRequest.reason.rawValue),
            URLQueryItem(name: "page", value: String(moderationRequest.page)),
            URLQueryItem(name: "page_size", value: String(moderationRequest.pageSize)),
        ]

        return try await request(path: "libraries/moderation/reports", queryItems: items)
    }

    func updateModerationReport(id: Int, status: ReportModerationStatus) async throws -> ModerationReport {
        try await request(
            path: "libraries/moderation/reports/\(id)",
            method: "PATCH",
            body: ReportModerationUpdateRequest(status: status),
        )
    }

    func getModerationPhotos(
        request moderationRequest: ModerationPhotoListRequest = .init(),
    ) async throws -> ModerationPhotoListResponse {
        let items = [
            URLQueryItem(name: "status", value: moderationRequest.status.rawValue),
            URLQueryItem(name: "page", value: String(moderationRequest.page)),
            URLQueryItem(name: "page_size", value: String(moderationRequest.pageSize)),
        ]

        return try await request(path: "libraries/moderation/photos", queryItems: items)
    }

    func updateModerationPhoto(id: Int, status: PhotoModerationStatus) async throws -> ModerationPhoto {
        try await request(
            path: "libraries/moderation/photos/\(id)",
            method: "PATCH",
            body: PhotoModerationUpdateRequest(status: status),
        )
    }
}
