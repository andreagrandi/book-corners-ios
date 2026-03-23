//
//  FilterState.swift
//  BookCorners
//

import Foundation

struct FilterState {
    var keywords: String = ""
    var city: String = ""
    var country: String = ""
    var postalCode: String = ""
    var radiusKm: Int = 50

    var isActive: Bool {
        !keywords.isEmpty || !city.isEmpty || !country.isEmpty || !postalCode.isEmpty || radiusKm != 50
    }

    mutating func clear() {
        keywords = ""
        city = ""
        country = ""
        postalCode = ""
        radiusKm = 50
    }
}
