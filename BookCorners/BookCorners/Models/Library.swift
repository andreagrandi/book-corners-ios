//
//  Library.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

nonisolated struct Library: Codable, Identifiable {
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

    enum CodingKeys: String, CodingKey {
        case id, slug, name, description, photoUrl, thumbnailUrl
        case lat, lng, address, city, country, postalCode
        case wheelchairAccessible, capacity, isIndoor, isLit
        case website, contact, source, brand, createdAt
        case operatorName = "operator"
    }
}
