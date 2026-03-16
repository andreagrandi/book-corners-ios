//
//  LibraryListViewModel.swift
//  BookCorners
//
//  Created by Andrea Grandi on 16/03/26.
//

import Foundation

@Observable
class LibraryListViewModel {
    var apiClient: any APIClientProtocol

    var libraries: [Library] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String?
    var hasMorePages: Bool = false

    private var currentPage: Int = 1
    private var pageSize: Int = 20

    init(client: any APIClientProtocol) {
        apiClient = client
    }

    func loadLibraries(lat: Double? = nil, lng: Double? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await apiClient.getLibraries(
                page: 1, pageSize: pageSize,
                query: nil, city: nil, country: nil,
                lat: lat, lng: lng, radiusKm: 50, hasPhoto: nil,
            )

            libraries = response.items
            hasMorePages = response.pagination.hasNext
            currentPage = 1
        } catch {
            errorMessage = "Failed to load libraries"
        }
    }

    func refresh(lat: Double? = nil, lng: Double? = nil) async {
        errorMessage = nil

        do {
            let response = try await apiClient.getLibraries(
                page: 1, pageSize: pageSize,
                query: nil, city: nil, country: nil,
                lat: lat, lng: lng, radiusKm: 50, hasPhoto: nil,
            )

            libraries = response.items
            hasMorePages = response.pagination.hasNext
            currentPage = 1
        } catch {
            errorMessage = "Failed to load libraries"
        }
    }

    func loadMore(lat: Double? = nil, lng: Double? = nil) async {
        guard !isLoadingMore, hasMorePages else {
            return
        }

        isLoadingMore = true
        errorMessage = nil
        defer { isLoadingMore = false }

        do {
            let response = try await apiClient.getLibraries(
                page: currentPage + 1, pageSize: pageSize,
                query: nil, city: nil, country: nil,
                lat: lat, lng: lng, radiusKm: 50, hasPhoto: nil,
            )

            libraries.append(contentsOf: response.items)
            hasMorePages = response.pagination.hasNext
            currentPage += 1
        } catch {
            errorMessage = "Failed to load more libraries"
        }
    }
}
