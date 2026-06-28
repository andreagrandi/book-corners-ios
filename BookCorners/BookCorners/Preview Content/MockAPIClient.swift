//
//  MockAPIClient.swift
//  BookCorners
//

import Foundation

class MockAPIClient: APIClientProtocol {
    var accessToken: String?

    func getLibraries(request _: LibrarySearchRequest) async throws -> LibraryListResponse {
        LibraryListResponse(
            items: SampleData.libraries,
            pagination: PaginationMeta(
                page: 1,
                pageSize: 20,
                total: 3,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
            ),
        )
    }

    func getLibrary(slug _: String) async throws -> Library {
        SampleData.library
    }

    func getLatestLibraries(limit _: Int, hasPhoto _: Bool?) async throws -> LatestLibrariesResponse {
        LatestLibrariesResponse(items: SampleData.libraries)
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
        AccessToken(access: "new.access.token")
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

    func submitLibrary(_: LibrarySubmissionRequest) async throws -> Library {
        SampleData.library
    }

    func reportLibrary(
        slug _: String,
        reason _: String,
        details _: String?,
        photo _: Data?,
    ) async throws -> Report {
        SampleData.report
    }

    func addPhoto(
        slug _: String,
        photo _: Data,
        caption _: String?,
    ) async throws -> LibraryPhoto {
        SampleData.libraryPhoto
    }

    func deleteAccount(password _: String?, confirm _: Bool?) async throws -> MessageResponse {
        MessageResponse(message: "Account deleted successfully.")
    }

    func getFavourites(page _: Int, pageSize _: Int) async throws -> LibraryListResponse {
        LibraryListResponse(
            items: SampleData.libraries.filter { $0.isFavourited == true },
            pagination: PaginationMeta(
                page: 1, pageSize: 20, total: 1, totalPages: 1,
                hasNext: false, hasPrevious: false,
            ),
        )
    }

    func addFavourite(slug _: String) async throws -> MessageResponse {
        MessageResponse(message: "Library added to favourites.")
    }

    func removeFavourite(slug _: String) async throws {}

    func getModerationSummary() async throws -> ModerationSummary {
        SampleData.moderationSummary
    }

    func getModerationLibraries(request: ModerationLibraryListRequest) async throws -> ModerationLibraryListResponse {
        var items = [SampleData.moderationLibrary]
        if request.status != .all {
            items = items.filter { $0.status.rawValue == request.status.rawValue }
        }
        if let query = request.query, !query.isEmpty {
            items = items.filter {
                $0.displayName.localizedCaseInsensitiveContains(query) ||
                    $0.city.localizedCaseInsensitiveContains(query) ||
                    $0.country.localizedCaseInsensitiveContains(query)
            }
        }

        return ModerationLibraryListResponse(
            items: items,
            pagination: PaginationMeta(
                page: 1, pageSize: 20, total: items.count, totalPages: items.isEmpty ? 0 : 1,
                hasNext: false, hasPrevious: false,
            ),
        )
    }

    func getModerationLibrary(slug _: String) async throws -> ModerationLibrary {
        SampleData.moderationLibrary
    }

    func updateModerationLibrary(
        slug _: String,
        status: LibraryModerationStatus,
        rejectionReason: String?,
    ) async throws -> ModerationLibrary {
        updatedModerationLibrary(
            status: status,
            rejectionReason: rejectionReason ?? "",
        )
    }

    func getModerationReports(request: ModerationReportListRequest) async throws -> ModerationReportListResponse {
        var items = [SampleData.moderationReport]
        if request.status != .all {
            items = items.filter { $0.status.rawValue == request.status.rawValue }
        }
        if request.reason != .all {
            items = items.filter { $0.reason.rawValue == request.reason.rawValue }
        }

        return ModerationReportListResponse(
            items: items,
            pagination: PaginationMeta(
                page: 1, pageSize: 20, total: items.count, totalPages: items.isEmpty ? 0 : 1,
                hasNext: false, hasPrevious: false,
            ),
        )
    }

    func updateModerationReport(id _: Int, status: ReportModerationStatus) async throws -> ModerationReport {
        updatedModerationReport(status: status)
    }

    func getModerationPhotos(request: ModerationPhotoListRequest) async throws -> ModerationPhotoListResponse {
        var items = [SampleData.moderationPhoto]
        if request.status != .all {
            items = items.filter { $0.status.rawValue == request.status.rawValue }
        }

        return ModerationPhotoListResponse(
            items: items,
            pagination: PaginationMeta(
                page: 1, pageSize: 20, total: items.count, totalPages: items.isEmpty ? 0 : 1,
                hasNext: false, hasPrevious: false,
            ),
        )
    }

    func updateModerationPhoto(id _: Int, status: PhotoModerationStatus) async throws -> ModerationPhoto {
        updatedModerationPhoto(status: status)
    }

    private func updatedModerationLibrary(
        status: LibraryModerationStatus,
        rejectionReason: String,
    ) -> ModerationLibrary {
        let library = SampleData.moderationLibrary
        return ModerationLibrary(
            id: library.id,
            slug: library.slug,
            name: library.name,
            description: library.description,
            photoUrl: library.photoUrl,
            thumbnailUrl: library.thumbnailUrl,
            lat: library.lat,
            lng: library.lng,
            address: library.address,
            city: library.city,
            country: library.country,
            postalCode: library.postalCode,
            wheelchairAccessible: library.wheelchairAccessible,
            capacity: library.capacity,
            isIndoor: library.isIndoor,
            isLit: library.isLit,
            website: library.website,
            contact: library.contact,
            source: library.source,
            operatorName: library.operatorName,
            brand: library.brand,
            createdAt: library.createdAt,
            isFavourited: library.isFavourited,
            status: status,
            rejectionReason: rejectionReason,
            createdBy: library.createdBy,
        )
    }

    private func updatedModerationReport(status: ReportModerationStatus) -> ModerationReport {
        let report = SampleData.moderationReport
        return ModerationReport(
            id: report.id,
            library: report.library,
            createdBy: report.createdBy,
            reason: report.reason,
            details: report.details,
            photoUrl: report.photoUrl,
            status: status,
            createdAt: report.createdAt,
        )
    }

    private func updatedModerationPhoto(status: PhotoModerationStatus) -> ModerationPhoto {
        let photo = SampleData.moderationPhoto
        return ModerationPhoto(
            id: photo.id,
            library: photo.library,
            createdBy: photo.createdBy,
            caption: photo.caption,
            photoUrl: photo.photoUrl,
            thumbnailUrl: photo.thumbnailUrl,
            status: status,
            createdAt: photo.createdAt,
        )
    }

    func invalidateLibraryCache(slug _: String) {}
}
