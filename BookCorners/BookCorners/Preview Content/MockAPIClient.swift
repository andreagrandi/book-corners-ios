//
//  MockAPIClient.swift
//  BookCorners
//

import Foundation

class MockAPIClient: APIClientProtocol {
    var accessToken: String?

    func getLibraries(
        page _: Int,
        pageSize _: Int,
        query _: String?,
        city _: String?,
        country _: String?,
        postalCode _: String?,
        lat _: Double?,
        lng _: Double?,
        radiusKm _: Int?,
        hasPhoto _: Bool?,
    ) async throws -> LibraryListResponse {
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

    func socialLogin(provider _: String, idToken _: String, firstName _: String?, lastName _: String?) async throws -> TokenPair {
        SampleData.tokenPair
    }

    func getMe() async throws -> User {
        SampleData.user
    }

    func submitLibrary(
        address _: String,
        city _: String,
        country _: String,
        latitude _: Double,
        longitude _: Double,
        photo _: Data,
        name _: String?,
        description _: String?,
        postalCode _: String?,
        wheelchairAccessible _: String?,
        capacity _: Int?,
        isIndoor _: Bool?,
        isLit _: Bool?,
        website _: String?,
        contact _: String?,
        operatorName _: String?,
        brand _: String?,
    ) async throws -> Library {
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
}
