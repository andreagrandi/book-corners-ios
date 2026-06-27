//
//  ModerationModels.swift
//  BookCorners
//

import Foundation

nonisolated enum ModerationStatusFilter: String, Codable, CaseIterable {
    case all
    case pending
    case approved
    case rejected
}

nonisolated enum LibraryModerationStatus: String, Codable, CaseIterable {
    case pending
    case approved
    case rejected
}

nonisolated enum ReportModerationStatusFilter: String, Codable, CaseIterable {
    case all
    case open
    case resolved
    case dismissed
}

nonisolated enum ReportModerationStatus: String, Codable, CaseIterable {
    case open
    case resolved
    case dismissed
}

nonisolated enum ReportModerationReasonFilter: String, Codable, CaseIterable {
    case all
    case damaged
    case missing
    case incorrectInfo = "incorrect_info"
    case inappropriate
    case other
}

nonisolated enum PhotoModerationStatusFilter: String, Codable, CaseIterable {
    case all
    case pending
    case approved
    case rejected
}

nonisolated enum PhotoModerationStatus: String, Codable, CaseIterable {
    case pending
    case approved
    case rejected
}

nonisolated struct ModerationLibraryListRequest: Equatable {
    var status: ModerationStatusFilter = .all
    var query: String?
    var country: String?
    var source: String?
    var page = 1
    var pageSize = 20
}

nonisolated struct ModerationReportListRequest: Equatable {
    var status: ReportModerationStatusFilter = .all
    var reason: ReportModerationReasonFilter = .all
    var page = 1
    var pageSize = 20
}

nonisolated struct ModerationPhotoListRequest: Equatable {
    var status: PhotoModerationStatusFilter = .all
    var page = 1
    var pageSize = 20
}

nonisolated struct ModerationSummary: Codable, Equatable {
    let pendingLibrariesCount: Int
    let openReportsCount: Int
    let pendingPhotosCount: Int
    let totalPending: Int
    let totalLibraries: Int
    let totalUsers: Int
}

nonisolated struct ModerationUser: Codable, Identifiable, Hashable {
    let id: Int
    let username: String
}

nonisolated struct ModerationLibrarySummary: Codable, Identifiable, Hashable {
    let id: Int
    let slug: String
    let name: String
    let address: String
    let city: String
    let country: String
    let status: LibraryModerationStatus

    var displayName: String {
        name.isEmpty ? "Neighborhood Library" : name
    }
}

nonisolated struct ModerationLibrary: Codable, Identifiable, Hashable {
    let id: Int
    let slug: String
    let name: String
    let description: String
    let photoUrl: String
    let thumbnailUrl: String
    let lat: Double
    let lng: Double
    let address: String
    let city: String
    let country: String
    let postalCode: String
    let wheelchairAccessible: String
    let capacity: Int?
    let isIndoor: Bool?
    let isLit: Bool?
    let website: String
    let contact: String
    let source: String
    let operatorName: String
    let brand: String
    let createdAt: Date
    let isFavourited: Bool?
    let status: LibraryModerationStatus
    let rejectionReason: String
    let createdBy: ModerationUser?

    var fullPhotoUrl: URL? {
        ModerationMediaURL.resolve(photoUrl)
    }

    var fullThumbnailUrl: URL? {
        ModerationMediaURL.resolve(thumbnailUrl)
    }

    var displayName: String {
        name.isEmpty ? "Neighborhood Library" : name
    }

    var websiteURL: URL? {
        guard !website.isEmpty else { return nil }
        return URL(string: website)
    }

    enum CodingKeys: String, CodingKey {
        case id, slug, name, description, photoUrl, thumbnailUrl
        case lat, lng, address, city, country, postalCode
        case wheelchairAccessible, capacity, isIndoor, isLit
        case website, contact, source, brand, createdAt
        case operatorName = "operator"
        case isFavourited, status, rejectionReason, createdBy
    }
}

nonisolated struct ModerationLibraryListResponse: Codable {
    let items: [ModerationLibrary]
    let pagination: PaginationMeta
}

nonisolated struct ModerationReport: Codable, Identifiable, Equatable {
    let id: Int
    let library: ModerationLibrarySummary
    let createdBy: ModerationUser?
    let reason: ReportReason
    let details: String
    let photoUrl: String
    let status: ReportModerationStatus
    let createdAt: Date

    var fullPhotoUrl: URL? {
        ModerationMediaURL.resolve(photoUrl)
    }
}

nonisolated struct ModerationReportListResponse: Codable {
    let items: [ModerationReport]
    let pagination: PaginationMeta
}

nonisolated struct ModerationPhoto: Codable, Identifiable, Equatable {
    let id: Int
    let library: ModerationLibrarySummary
    let createdBy: ModerationUser?
    let caption: String
    let photoUrl: String
    let thumbnailUrl: String
    let status: PhotoModerationStatus
    let createdAt: Date

    var fullPhotoUrl: URL? {
        ModerationMediaURL.resolve(photoUrl)
    }

    var fullThumbnailUrl: URL? {
        ModerationMediaURL.resolve(thumbnailUrl)
    }
}

nonisolated struct ModerationPhotoListResponse: Codable {
    let items: [ModerationPhoto]
    let pagination: PaginationMeta
}

nonisolated struct LibraryModerationUpdateRequest: Encodable {
    let status: LibraryModerationStatus
    let rejectionReason: String?
}

nonisolated struct ReportModerationUpdateRequest: Encodable {
    let status: ReportModerationStatus
}

nonisolated struct PhotoModerationUpdateRequest: Encodable {
    let status: PhotoModerationStatus
}

private nonisolated enum ModerationMediaURL {
    static let baseURL: String = {
        guard let apiBase = ProcessInfo.processInfo.environment["API_BASE_URL"],
              let url = URL(string: apiBase),
              let scheme = url.scheme,
              let host = url.host()
        else {
            return "https://bookcorners.org"
        }
        let port = url.port.map { ":\($0)" } ?? ""
        return "\(scheme)://\(host)\(port)"
    }()

    static func resolve(_ path: String) -> URL? {
        guard !path.isEmpty else { return nil }
        if let absoluteURL = URL(string: path), absoluteURL.scheme != nil {
            return absoluteURL
        }
        return URL(string: "\(baseURL)\(path)")
    }
}
