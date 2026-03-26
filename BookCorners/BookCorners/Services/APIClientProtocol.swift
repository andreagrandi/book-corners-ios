//
//  APIClientProtocol.swift
//  BookCorners
//
//  Created by Andrea Grandi on 11/03/26.
//

import Foundation

protocol APIClientProtocol {
    var accessToken: String? { get set }

    func getLibraries(page: Int,
                      pageSize: Int,
                      query: String?,
                      city: String?,
                      country: String?,
                      postalCode: String?,
                      lat: Double?,
                      lng: Double?,
                      radiusKm: Int?,
                      hasPhoto: Bool?) async throws -> LibraryListResponse
    func getLibrary(slug: String) async throws -> Library
    func getLatestLibraries(limit: Int, hasPhoto: Bool?) async throws -> LatestLibrariesResponse
    func getStatistics() async throws -> Statistics
    func login(username: String, password: String) async throws -> TokenPair
    func getMe() async throws -> User
    func register(username: String, password: String, email: String) async throws -> TokenPair
    func refreshToken(refreshToken: String) async throws -> AccessToken
    func socialLogin(provider: String, idToken: String, firstName: String?, lastName: String?) async throws -> TokenPair
    func submitLibrary(
        address: String,
        city: String,
        country: String,
        latitude: Double,
        longitude: Double,
        photo: Data,
        name: String?,
        description: String?,
        postalCode: String?,
        wheelchairAccessible: String?,
        capacity: Int?,
        isIndoor: Bool?,
        isLit: Bool?,
        website: String?,
        contact: String?,
        operatorName: String?,
        brand: String?,
    ) async throws -> Library
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
}
