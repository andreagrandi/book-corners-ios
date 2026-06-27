//
//  LibraryRequestModels.swift
//  BookCorners
//

import Foundation

nonisolated struct LibrarySearchRequest: Equatable {
    var page = 1
    var pageSize = 20
    var query: String?
    var city: String?
    var country: String?
    var postalCode: String?
    var lat: Double?
    var lng: Double?
    var radiusKm: Int?
    var hasPhoto: Bool?
}

nonisolated struct LibrarySubmissionRequest: Equatable {
    let address: String
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    let photo: Data
    var name: String?
    var description: String?
    var postalCode: String?
    var wheelchairAccessible: String?
    var capacity: Int?
    var isIndoor: Bool?
    var isLit: Bool?
    var website: String?
    var contact: String?
    var operatorName: String?
    var brand: String?
}
