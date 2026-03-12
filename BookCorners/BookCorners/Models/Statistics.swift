//
//  Statistics.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

nonisolated struct Statistics: Codable {
    let totalApproved: Int
    let totalWithImage: Int
    let topCountries: [CountryCount]
    let cumulativeSeries: [CumulativeEntry]
    let granularity: String
}

nonisolated struct CountryCount: Codable {
    let countryCode: String
    let countryName: String
    let flagEmoji: String
    let count: Int
}

nonisolated struct CumulativeEntry: Codable {
    let period: String
    let cumulativeCount: Int
}
