//
//  APIClientProtocol.swift
//  BookCorners
//
//  Created by Andrea Grandi on 11/03/26.
//

import Foundation

protocol APIClientProtocol {
    var accessToken: String? { get set }

    func getLibraries(request: LibrarySearchRequest) async throws -> LibraryListResponse
    func getLibrary(slug: String) async throws -> Library
    func getLatestLibraries(limit: Int, hasPhoto: Bool?) async throws -> LatestLibrariesResponse
    func getStatistics() async throws -> Statistics
    func login(username: String, password: String) async throws -> TokenPair
    func getMe() async throws -> User
    func register(username: String, password: String, email: String) async throws -> TokenPair
    func refreshToken(refreshToken: String) async throws -> AccessToken
    func socialLogin(provider: String, idToken: String, firstName: String?, lastName: String?) async throws -> TokenPair
    func registerDeviceToken(
        token: String,
        environment: APNsEnvironment,
    ) async throws -> DeviceTokenRegistrationResponse
    func unregisterDeviceToken(token: String) async throws
    func submitLibrary(_ submission: LibrarySubmissionRequest) async throws -> Library
    func reportLibrary(
        slug: String,
        reason: String,
        details: String?,
        photo: Data?,
    ) async throws -> Report
    func addPhoto(
        slug: String,
        photo: Data,
        caption: String?,
    ) async throws -> LibraryPhoto
    func deleteAccount(password: String?, confirm: Bool?) async throws -> MessageResponse
    func getFavourites(page: Int, pageSize: Int) async throws -> LibraryListResponse
    func addFavourite(slug: String) async throws -> MessageResponse
    func removeFavourite(slug: String) async throws
    func getModerationSummary() async throws -> ModerationSummary
    func getModerationLibraries(request: ModerationLibraryListRequest) async throws -> ModerationLibraryListResponse
    func getModerationLibrary(slug: String) async throws -> ModerationLibrary
    func updateModerationLibrary(
        slug: String,
        status: LibraryModerationStatus,
        rejectionReason: String?,
    ) async throws -> ModerationLibrary
    func getModerationReports(request: ModerationReportListRequest) async throws -> ModerationReportListResponse
    func updateModerationReport(id: Int, status: ReportModerationStatus) async throws -> ModerationReport
    func getModerationPhotos(request: ModerationPhotoListRequest) async throws -> ModerationPhotoListResponse
    func updateModerationPhoto(id: Int, status: PhotoModerationStatus) async throws -> ModerationPhoto
    func invalidateLibraryCache(slug: String)
}
