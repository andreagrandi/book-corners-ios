//
//  ModelDecodingTests.swift
//  BookCornersTests
//
//  Created by Andrea Grandi on 12/03/26.
//

@testable import BookCorners
import Foundation
import Testing

struct ModelDecodingTests {
    let decoder: JSONDecoder

    init() {
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    @Test func `library decodes from JSON`() throws {
        let data = try #require(Fixtures.libraryJSON.data(using: .utf8))
        let library = try decoder.decode(Library.self, from: data)

        #expect(library.id == 1)
        #expect(library.slug == "community-library-berlin")
        #expect(library.name == "Community Library Berlin")
        #expect(library.lat == 52.52)
        #expect(library.lng == 13.405)
        #expect(library.capacity == 30)
        #expect(library.operatorName == "Book Club Berlin")
    }

    @Test func `library with null fields decodes`() throws {
        let data = try #require(Fixtures.libraryNullFieldsJSON.data(using: .utf8))
        let library = try decoder.decode(Library.self, from: data)

        #expect(library.capacity == nil)
        #expect(library.isIndoor == nil)
        #expect(library.isLit == nil)
    }

    @Test func `library list response decodes`() throws {
        let data = try #require(Fixtures.libraryListJSON.data(using: .utf8))
        let response = try decoder.decode(LibraryListResponse.self, from: data)

        #expect(response.items.count == 1)
        #expect(response.items[0].slug == "community-library-berlin")
        #expect(response.pagination.page == 1)
        #expect(response.pagination.pageSize == 20)
        #expect(response.pagination.total == 1)
        #expect(response.pagination.totalPages == 1)
        #expect(response.pagination.hasNext == false)
        #expect(response.pagination.hasPrevious == false)
    }

    @Test func `latest libraries response decodes`() throws {
        let data = try #require(Fixtures.latestLibrariesJSON.data(using: .utf8))
        let response = try decoder.decode(LatestLibrariesResponse.self, from: data)

        #expect(response.items.count == 1)
        #expect(response.items[0].name == "Community Library Berlin")
    }

    @Test func `token pair decodes`() throws {
        let data = try #require(Fixtures.tokenPairJSON.data(using: .utf8))
        let tokenPair = try decoder.decode(TokenPair.self, from: data)

        #expect(tokenPair.access.contains("access"))
        #expect(tokenPair.refresh.contains("refresh"))
    }

    @Test func `user decodes`() throws {
        let data = try #require(Fixtures.userJSON.data(using: .utf8))
        let user = try decoder.decode(User.self, from: data)

        #expect(user.id == 42)
        #expect(user.username == "booklover")
        #expect(user.email == "booklover@example.com")
        #expect(user.isSocialOnly == false)
        #expect(user.isStaff == false)
    }

    @Test func `staff user decodes`() throws {
        let data = try #require(Fixtures.staffUserJSON.data(using: .utf8))
        let user = try decoder.decode(User.self, from: data)

        #expect(user.id == 44)
        #expect(user.username == "moderator")
        #expect(user.isStaff == true)
    }

    @Test func `non-staff user decodes`() throws {
        let data = try #require(Fixtures.nonStaffUserJSON.data(using: .utf8))
        let user = try decoder.decode(User.self, from: data)

        #expect(user.id == 45)
        #expect(user.username == "reader")
        #expect(user.isStaff == false)
    }

    @Test func `user without staff field decodes as non-staff`() throws {
        let data = Data("""
        {
            "id": 46,
            "username": "legacy",
            "email": "legacy@example.com",
            "is_social_only": false
        }
        """.utf8)
        let user = try decoder.decode(User.self, from: data)

        #expect(user.isStaff == false)
    }

    @Test func `statistics decodes`() throws {
        let data = try #require(Fixtures.statisticsJSON.data(using: .utf8))
        let stats = try decoder.decode(Statistics.self, from: data)

        #expect(stats.totalApproved == 1523)
        #expect(stats.totalWithImage == 987)
        #expect(stats.granularity == "monthly")
        #expect(stats.topCountries.count == 2)
        #expect(stats.topCountries[0].countryCode == "DE")
        #expect(stats.topCountries[0].count == 450)
        #expect(stats.cumulativeSeries.count == 2)
        #expect(stats.cumulativeSeries[1].cumulativeCount == 1523)
    }

    @Test func `api error response decodes`() throws {
        let data = try #require(Fixtures.apiErrorJSON.data(using: .utf8))
        let error = try decoder.decode(APIErrorResponse.self, from: data)

        #expect(error.message == "Invalid credentials")
        #expect(error.details?["username"] == "Not found")
    }

    @Test func `library with is_favourited true decodes`() throws {
        let data = try #require(Fixtures.libraryFavouritedJSON.data(using: .utf8))
        let library = try decoder.decode(Library.self, from: data)

        #expect(library.isFavourited == true)
    }

    @Test func `library with is_favourited false decodes`() throws {
        let data = try #require(Fixtures.libraryJSON.data(using: .utf8))
        let library = try decoder.decode(Library.self, from: data)

        #expect(library.isFavourited == false)
    }

    @Test func `library without is_favourited field decodes as nil`() throws {
        let data = try #require(Fixtures.libraryNullFieldsJSON.data(using: .utf8))
        let library = try decoder.decode(Library.self, from: data)

        #expect(library.isFavourited == nil)
    }

    @Test func `favourites list response decodes`() throws {
        let data = try #require(Fixtures.favouritesListJSON.data(using: .utf8))
        let response = try decoder.decode(LibraryListResponse.self, from: data)

        #expect(response.items.count == 1)
        #expect(response.items[0].isFavourited == true)
        #expect(response.pagination.total == 1)
    }

    @Test func `moderation summary decodes`() throws {
        let data = try #require(Fixtures.moderationSummaryJSON.data(using: .utf8))
        let summary = try decoder.decode(ModerationSummary.self, from: data)

        #expect(summary.pendingLibrariesCount == 4)
        #expect(summary.openReportsCount == 2)
        #expect(summary.pendingPhotosCount == 5)
        #expect(summary.totalPending == 11)
        #expect(summary.totalLibraries == 350)
        #expect(summary.totalUsers == 128)
    }

    @Test func `moderation library decodes`() throws {
        let data = try #require(Fixtures.moderationLibraryJSON.data(using: .utf8))
        let library = try decoder.decode(ModerationLibrary.self, from: data)

        #expect(library.id == 42)
        #expect(library.slug == "florence-via-rosina-15-corner-books")
        #expect(library.status == .pending)
        #expect(library.rejectionReason == "")
        #expect(library.createdBy?.username == "janedoe")
        #expect(library.operatorName == "Book Club Florence")
    }

    @Test func `moderation library list response decodes`() throws {
        let data = try #require(Fixtures.moderationLibraryListJSON.data(using: .utf8))
        let response = try decoder.decode(ModerationLibraryListResponse.self, from: data)

        #expect(response.items.count == 1)
        #expect(response.items[0].status == .pending)
        #expect(response.items[0].createdBy?.id == 1)
        #expect(response.pagination.page == 1)
        #expect(response.pagination.total == 1)
    }

    @Test func `moderation report list response decodes`() throws {
        let data = try #require(Fixtures.moderationReportListJSON.data(using: .utf8))
        let response = try decoder.decode(ModerationReportListResponse.self, from: data)

        #expect(response.items.count == 1)
        #expect(response.items[0].id == 7)
        #expect(response.items[0].library.status == .approved)
        #expect(response.items[0].reason == .damaged)
        #expect(response.items[0].status == .open)
        #expect(response.items[0].createdBy?.username == "reader")
        #expect(response.pagination.totalPages == 1)
    }

    @Test func `moderation photo list response decodes`() throws {
        let data = try #require(Fixtures.moderationPhotoListJSON.data(using: .utf8))
        let response = try decoder.decode(ModerationPhotoListResponse.self, from: data)

        #expect(response.items.count == 1)
        #expect(response.items[0].id == 12)
        #expect(response.items[0].library.slug == "florence-via-rosina-15-corner-books")
        #expect(response.items[0].status == .pending)
        #expect(response.items[0].createdBy?.id == 3)
        #expect(response.pagination.hasNext == false)
    }

    @Test func `invalid JSON throws decoding error`() throws {
        let badJSON = "{\"id\": \"not_a_number\"}"
        let data = try #require(badJSON.data(using: .utf8))

        #expect(throws: (any Error).self) {
            try decoder.decode(Library.self, from: data)
        }
    }
}
