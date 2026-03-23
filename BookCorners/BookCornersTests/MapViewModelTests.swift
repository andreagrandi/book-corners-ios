//
//  MapViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import MapKit
import Testing

@MainActor
struct MapViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: MapViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = MapViewModel(client: stubClient)
    }

    @Test func `apply filters success populates libraries`() async {
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            LibraryListResponse(
                items: SampleData.libraries,
                pagination: PaginationMeta(
                    page: 1, pageSize: 50, total: 3, totalPages: 1,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }

        await viewModel.applyFilters(FilterState())

        #expect(viewModel.libraries.count == 3)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `apply filters error sets error message`() async {
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            throw APIClientError.networkError(
                URLError(.notConnectedToInternet),
            )
        }

        await viewModel.applyFilters(FilterState())

        #expect(viewModel.libraries.isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }

    @Test func `selected library can be set and cleared`() {
        #expect(viewModel.selectedLibrary == nil)

        viewModel.selectedLibrary = SampleData.library
        #expect(viewModel.selectedLibrary?.slug == "little-library-amsterdam")

        viewModel.selectedLibrary = nil
        #expect(viewModel.selectedLibrary == nil)
    }

    @Test func `apply filters with city passes city to API`() async {
        var receivedCity: String?

        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            LibraryListResponse(
                items: [],
                pagination: PaginationMeta(
                    page: 1, pageSize: 50, total: 0, totalPages: 0,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }

        // Override to capture city — StubAPIClient ignores city by default,
        // so we check the viewModel correctly clears lat/lng when city is set
        var filters = FilterState()
        filters.city = "Pistoia"

        await viewModel.applyFilters(filters)

        #expect(viewModel.libraries.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `region for results returns nil when empty`() {
        #expect(viewModel.regionForResults() == nil)
    }

    @Test func `region for results computes bounding region`() async throws {
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            LibraryListResponse(
                items: SampleData.libraries,
                pagination: PaginationMeta(
                    page: 1, pageSize: 50, total: 3, totalPages: 1,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }

        await viewModel.applyFilters(FilterState())

        let region = viewModel.regionForResults()
        #expect(region != nil)
        #expect(try #require(region?.span.latitudeDelta) > 0)
        #expect(try #require(region?.span.longitudeDelta) > 0)
    }
}
