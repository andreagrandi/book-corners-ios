//
//  Library.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

nonisolated struct Library: Codable, Identifiable, Hashable {
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
    var isFavourited: Bool? = nil

    private static let mediaBaseURL: String = {
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

    var fullPhotoUrl: URL? {
        guard !photoUrl.isEmpty else { return nil }
        return URL(string: "\(Self.mediaBaseURL)\(photoUrl)")
    }

    var fullThumbnailUrl: URL? {
        guard !thumbnailUrl.isEmpty else { return nil }
        return URL(string: "\(Self.mediaBaseURL)\(thumbnailUrl)")
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
        case isFavourited
    }
}
