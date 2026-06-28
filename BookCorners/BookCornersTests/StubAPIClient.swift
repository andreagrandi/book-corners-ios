//
//  StubAPIClient.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation

struct ModerationLibraryUpdateCapture: Equatable {
    let slug: String
    let status: LibraryModerationStatus
    let rejectionReason: String?
}

/// A configurable stub that lets each test control what getLibraries() returns.
/// Python analogy: like setting mock.return_value or mock.side_effect per test.
/// Go analogy: a struct with function fields you swap out per test case.
class StubAPIClient: APIClientProtocol {
    var accessToken: String?

    /// Each test sets this closure to control the response.
    /// Parameters: (page, pageSize, query, lat, lng)
    var getLibrariesHandler: ((Int, Int, String?, Double?, Double?) throws -> LibraryListResponse)?
    var lastLibrarySearchRequest: LibrarySearchRequest?

    func getLibraries(request: LibrarySearchRequest) async throws -> LibraryListResponse {
        lastLibrarySearchRequest = request
        guard let handler = getLibrariesHandler else {
            fatalError("getLibrariesHandler not set — configure it in your test")
        }
        return try handler(request.page, request.pageSize, request.query, request.lat, request.lng)
    }

    /// Each test can set this to control getLibrary() response
    var getLibraryHandler: ((String) throws -> Library)?

    func getLibrary(slug: String) async throws -> Library {
        if let handler = getLibraryHandler {
            return try handler(slug)
        }
        return SampleData.library
    }

    func getLatestLibraries(limit _: Int, hasPhoto _: Bool?) async throws -> LatestLibrariesResponse {
        LatestLibrariesResponse(items: [])
    }

    func getStatistics() async throws -> Statistics {
        SampleData.statistics
    }

    func login(username _: String, password _: String) async throws -> TokenPair {
        SampleData.tokenPair
    }

    func register(username _: String, password _: String, email _: String) async throws -> TokenPair {
        SampleData.tokenPair
    }

    func refreshToken(refreshToken _: String) async throws -> AccessToken {
        AccessToken(access: "")
    }

    func socialLogin(
        provider _: String,
        idToken _: String,
        firstName _: String?,
        lastName _: String?,
    ) async throws -> TokenPair {
        SampleData.tokenPair
    }

    func getMe() async throws -> User {
        SampleData.user
    }

    var submitLibraryHandler: (() throws -> Library)?

    func submitLibrary(_: LibrarySubmissionRequest) async throws -> Library {
        if let handler = submitLibraryHandler {
            return try handler()
        }
        return SampleData.library
    }

    var reportLibraryHandler: (() throws -> Report)?

    func reportLibrary(slug _: String, reason _: String, details _: String?, photo _: Data?) async throws -> Report {
        if let handler = reportLibraryHandler {
            return try handler()
        }
        return SampleData.report
    }

    var addPhotoHandler: (() throws -> LibraryPhoto)?

    func addPhoto(slug _: String, photo _: Data, caption _: String?) async throws -> LibraryPhoto {
        if let handler = addPhotoHandler {
            return try handler()
        }
        return SampleData.libraryPhoto
    }

    func deleteAccount(password _: String?, confirm _: Bool?) async throws -> MessageResponse {
        MessageResponse(message: "Account deleted successfully.")
    }

    var getFavouritesHandler: ((Int, Int) throws -> LibraryListResponse)?

    func getFavourites(page: Int, pageSize: Int) async throws -> LibraryListResponse {
        if let handler = getFavouritesHandler {
            return try handler(page, pageSize)
        }
        return LibraryListResponse(
            items: [],
            pagination: PaginationMeta(
                page: 1, pageSize: 20, total: 0, totalPages: 0,
                hasNext: false, hasPrevious: false,
            ),
        )
    }

    var addFavouriteHandler: ((String) throws -> MessageResponse)?

    func addFavourite(slug: String) async throws -> MessageResponse {
        if let handler = addFavouriteHandler {
            return try handler(slug)
        }
        return MessageResponse(message: "Library added to favourites.")
    }

    var removeFavouriteHandler: ((String) throws -> Void)?

    func removeFavourite(slug: String) async throws {
        if let handler = removeFavouriteHandler {
            try handler(slug)
        }
    }

    var getModerationSummaryHandler: (() throws -> ModerationSummary)?

    func getModerationSummary() async throws -> ModerationSummary {
        if let handler = getModerationSummaryHandler {
            return try handler()
        }
        return SampleData.moderationSummary
    }

    var getModerationLibrariesHandler: ((ModerationLibraryListRequest) throws -> ModerationLibraryListResponse)?
    var lastModerationLibraryListRequest: ModerationLibraryListRequest?

    func getModerationLibraries(request: ModerationLibraryListRequest) async throws -> ModerationLibraryListResponse {
        lastModerationLibraryListRequest = request
        if let handler = getModerationLibrariesHandler {
            return try handler(request)
        }
        return ModerationLibraryListResponse(
            items: [SampleData.moderationLibrary],
            pagination: PaginationMeta(
                page: 1, pageSize: 20, total: 1, totalPages: 1,
                hasNext: false, hasPrevious: false,
            ),
        )
    }

    var getModerationLibraryHandler: ((String) throws -> ModerationLibrary)?
    var lastModerationLibrarySlug: String?

    func getModerationLibrary(slug: String) async throws -> ModerationLibrary {
        lastModerationLibrarySlug = slug
        if let handler = getModerationLibraryHandler {
            return try handler(slug)
        }
        return SampleData.moderationLibrary
    }

    var updateModerationLibraryHandler: ((String, LibraryModerationStatus, String?) throws -> ModerationLibrary)?
    var lastModerationLibraryUpdate: ModerationLibraryUpdateCapture?

    func updateModerationLibrary(
        slug: String,
        status: LibraryModerationStatus,
        rejectionReason: String?,
    ) async throws -> ModerationLibrary {
        lastModerationLibraryUpdate = ModerationLibraryUpdateCapture(
            slug: slug,
            status: status,
            rejectionReason: rejectionReason,
        )
        if let handler = updateModerationLibraryHandler {
            return try handler(slug, status, rejectionReason)
        }
        return SampleData.moderationLibrary
    }

    func getModerationReports(request _: ModerationReportListRequest) async throws -> ModerationReportListResponse {
        ModerationReportListResponse(
            items: [SampleData.moderationReport],
            pagination: PaginationMeta(
                page: 1, pageSize: 20, total: 1, totalPages: 1,
                hasNext: false, hasPrevious: false,
            ),
        )
    }

    func updateModerationReport(id _: Int, status _: ReportModerationStatus) async throws -> ModerationReport {
        SampleData.moderationReport
    }

    func getModerationPhotos(request _: ModerationPhotoListRequest) async throws -> ModerationPhotoListResponse {
        ModerationPhotoListResponse(
            items: [SampleData.moderationPhoto],
            pagination: PaginationMeta(
                page: 1, pageSize: 20, total: 1, totalPages: 1,
                hasNext: false, hasPrevious: false,
            ),
        )
    }

    func updateModerationPhoto(id _: Int, status _: PhotoModerationStatus) async throws -> ModerationPhoto {
        SampleData.moderationPhoto
    }

    func invalidateLibraryCache(slug _: String) {}
}
