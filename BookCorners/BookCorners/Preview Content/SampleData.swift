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
        isFavourited: false,
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
            isFavourited: false,
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
            isFavourited: false,
        ),
    ]

    static let user = User(
        id: 1,
        username: "andrea",
        email: "andrea@example.com",
        isSocialOnly: false,
        isStaff: false,
    )

    static let staffUser = User(
        id: 2,
        username: "moderator",
        email: "moderator@example.com",
        isSocialOnly: false,
        isStaff: true,
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

    static let contributionLibrarySummary = ContributionLibrarySummary(
        id: 1,
        slug: "community-library-amsterdam",
        name: "Community Library Amsterdam",
        city: "Amsterdam",
        country: "NL",
        status: .approved,
    )

    static let contributionLibrary = ContributionLibrary(
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
        source: "user",
        operatorName: "",
        brand: "",
        createdAt: Date(),
        isFavourited: true,
        status: .approved,
        rejectionReason: "",
    )

    static let contributionReport = ContributionReport(
        id: 1,
        library: contributionLibrarySummary,
        reason: .damaged,
        status: .open,
        createdAt: Date(),
    )

    static let contributionPhoto = ContributionPhoto(
        id: 1,
        library: contributionLibrarySummary,
        caption: "Front view of the library",
        photoUrl: "/media/libraries/user_photos/photo.jpg",
        thumbnailUrl: "/media/libraries/user_photos/thumbnails/photo.jpg",
        status: .pending,
        createdAt: Date(),
    )

    static let moderationSummary = ModerationSummary(
        pendingLibrariesCount: 3,
        openReportsCount: 1,
        pendingPhotosCount: 2,
        totalPending: 6,
        totalLibraries: 1234,
        totalUsers: 128,
    )

    static let moderationUser = ModerationUser(
        id: 2,
        username: "moderator",
    )

    static let moderationLibrarySummary = ModerationLibrarySummary(
        id: 1,
        slug: "community-library-amsterdam",
        name: "Community Library Amsterdam",
        address: "Keizersgracht 123",
        city: "Amsterdam",
        country: "NL",
        status: .pending,
    )

    static let moderationLibrary = ModerationLibrary(
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
        source: "user",
        operatorName: "",
        brand: "",
        createdAt: Date(),
        isFavourited: false,
        status: .pending,
        rejectionReason: "",
        createdBy: moderationUser,
    )

    static let moderationReport = ModerationReport(
        id: 1,
        library: moderationLibrarySummary,
        createdBy: moderationUser,
        reason: .damaged,
        details: "The door hinge is broken.",
        photoUrl: "/media/reports/photos/report.jpg",
        status: .open,
        createdAt: Date(),
    )

    static let moderationPhoto = ModerationPhoto(
        id: 1,
        library: moderationLibrarySummary,
        createdBy: moderationUser,
        caption: "Front view of the library",
        photoUrl: "/media/libraries/user_photos/photo.jpg",
        thumbnailUrl: "/media/libraries/user_photos/thumbnails/photo.jpg",
        status: .pending,
        createdAt: Date(),
    )
}
