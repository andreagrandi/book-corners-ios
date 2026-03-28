//
//  SampleData.swift
//  BookCorners
//

import Foundation

enum SampleData {
    static let library = Library(
        id: 1,
        slug: "community-library-amsterdam",
        name: "Community Library Amsterdam",
        description: "A cozy street library near the canal, stocked with Dutch and English books.",
        photoUrl: "/media/libraries/photos/amsterdam.jpg",
        thumbnailUrl: "/media/libraries/thumbnails/amsterdam.jpg",
        lat: 52.3676,
        lng: 4.9041,
        address: "Keizersgracht 123",
        city: "Amsterdam",
        country: "NL",
        postalCode: "1015 CJ",
        wheelchairAccessible: "yes",
        capacity: 50,
        isIndoor: false,
        isLit: true,
        website: "",
        contact: "",
        source: "osm",
        operatorName: "",
        brand: "",
        createdAt: Date(),
    )

    static let libraries = [
        library,
        Library(
            id: 2,
            slug: "book-box-berlin",
            name: "Book Box Berlin",
            description: "A bright yellow book box in Kreuzberg.",
            photoUrl: "/media/libraries/photos/berlin.jpg",
            thumbnailUrl: "/media/libraries/thumbnails/berlin.jpg",
            lat: 52.4934,
            lng: 13.4234,
            address: "Oranienstrasse 45",
            city: "Berlin",
            country: "DE",
            postalCode: "10969",
            wheelchairAccessible: "yes",
            capacity: 30,
            isIndoor: false,
            isLit: false,
            website: "",
            contact: "",
            source: "user",
            operatorName: "",
            brand: "",
            createdAt: Date(),
        ),
        Library(
            id: 3,
            slug: "free-reads-florence",
            name: "Free Reads Florence",
            description: "A small wooden cabinet near Piazza Santo Spirito.",
            photoUrl: "",
            thumbnailUrl: "",
            lat: 43.7696,
            lng: 11.2558,
            address: "Piazza Santo Spirito 8",
            city: "Florence",
            country: "IT",
            postalCode: "50125",
            wheelchairAccessible: "limited",
            capacity: nil,
            isIndoor: false,
            isLit: nil,
            website: "",
            contact: "",
            source: "user",
            operatorName: "",
            brand: "",
            createdAt: Date(),
        ),
    ]

    static let user = User(
        id: 1,
        username: "andrea",
        email: "andrea@example.com",
        isSocialOnly: false,
    )

    static let tokenPair = TokenPair(
        access: "sample.access.token",
        refresh: "sample.refresh.token",
    )

    static let statistics = Statistics(
        totalApproved: 1234,
        totalWithImage: 987,
        topCountries: [
            CountryCount(countryCode: "DE", countryName: "Germany", flagEmoji: "🇩🇪", count: 456),
            CountryCount(countryCode: "NL", countryName: "Netherlands", flagEmoji: "🇳🇱", count: 321),
            CountryCount(countryCode: "IT", countryName: "Italy", flagEmoji: "🇮🇹", count: 198),
        ],
        cumulativeSeries: [
            CumulativeEntry(period: "2025-01-01", cumulativeCount: 800),
            CumulativeEntry(period: "2025-06-01", cumulativeCount: 1050),
            CumulativeEntry(period: "2026-01-01", cumulativeCount: 1234),
        ],
        granularity: "monthly",
    )

    static let report = Report(
        id: 1,
        reason: "damaged",
        createdAt: Date(),
    )

    static let libraryPhoto = LibraryPhoto(
        id: 1,
        caption: "Front view of the library",
        status: "approved",
        createdAt: Date(),
    )
}
