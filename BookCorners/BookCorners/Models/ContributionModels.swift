//
//  ContributionModels.swift
//  BookCorners
//

import Foundation

nonisolated struct ContributionLibrary: Codable, Identifiable, Hashable {
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

    var fullPhotoUrl: URL? {
        ContributionMediaURL.resolve(photoUrl)
    }

    var fullThumbnailUrl: URL? {
        ContributionMediaURL.resolve(thumbnailUrl)
    }

    var displayName: String {
        name.isEmpty ? "Neighborhood Library" : name
    }

    enum CodingKeys: String, CodingKey {
        case id, slug, name, description, photoUrl, thumbnailUrl
        case lat, lng, address, city, country, postalCode
        case wheelchairAccessible, capacity, isIndoor, isLit
        case website, contact, source, brand, createdAt
        case operatorName = "operator"
        case isFavourited, status, rejectionReason
    }
}

nonisolated struct ContributionLibraryListResponse: Codable {
    let items: [ContributionLibrary]
    let pagination: PaginationMeta
}

nonisolated struct ContributionLibrarySummary: Codable, Identifiable, Hashable {
    let id: Int
    let slug: String
    let name: String
    let city: String
    let country: String
    let status: LibraryModerationStatus

    var displayName: String {
        name.isEmpty ? "Neighborhood Library" : name
    }
}

nonisolated struct ContributionReport: Codable, Identifiable, Hashable {
    let id: Int
    let library: ContributionLibrarySummary
    let reason: ReportReason
    let status: ReportModerationStatus
    let createdAt: Date
}

nonisolated struct ContributionReportListResponse: Codable {
    let items: [ContributionReport]
    let pagination: PaginationMeta
}

nonisolated struct ContributionPhoto: Codable, Identifiable, Hashable {
    let id: Int
    let library: ContributionLibrarySummary
    let caption: String
    let photoUrl: String
    let thumbnailUrl: String
    let status: PhotoModerationStatus
    let createdAt: Date

    var fullPhotoUrl: URL? {
        ContributionMediaURL.resolve(photoUrl)
    }

    var fullThumbnailUrl: URL? {
        ContributionMediaURL.resolve(thumbnailUrl)
    }

    var displayCaption: String {
        caption.isEmpty ? "Community photo" : caption
    }
}

nonisolated struct ContributionPhotoListResponse: Codable {
    let items: [ContributionPhoto]
    let pagination: PaginationMeta
}

private nonisolated enum ContributionMediaURL {
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
