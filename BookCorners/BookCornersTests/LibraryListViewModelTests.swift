//
//  LibraryListViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct LibraryListViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: LibraryListViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = LibraryListViewModel(client: stubClient)
    }

    @Test func `load libraries success`() async {
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            LibraryListResponse(
                items: SampleData.libraries,
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 3, totalPages: 1,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }

        await viewModel.loadLibraries()

        #expect(viewModel.libraries.count == 3)
        #expect(viewModel.libraries[0].slug == "community-library-amsterdam")
        #expect(viewModel.hasMorePages == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `load libraries sets has more pages`() async {
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            LibraryListResponse(
                items: [SampleData.library],
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 40, totalPages: 2,
                    hasNext: true, hasPrevious: false,
                ),
            )
        }

        await viewModel.loadLibraries()

        #expect(viewModel.libraries.count == 1)
        #expect(viewModel.hasMorePages == true)
    }

    @Test func `load more appends items`() async {
        // First load — page 1, more pages available
        stubClient.getLibrariesHandler = { page, _, _, _, _ in
            if page == 1 {
                LibraryListResponse(
                    items: [SampleData.libraries[0]],
                    pagination: PaginationMeta(
                        page: 1, pageSize: 1, total: 2, totalPages: 2,
                        hasNext: true, hasPrevious: false,
                    ),
                )
            } else {
                LibraryListResponse(
                    items: [SampleData.libraries[1]],
                    pagination: PaginationMeta(
                        page: 2, pageSize: 1, total: 2, totalPages: 2,
                        hasNext: false, hasPrevious: true,
                    ),
                )
            }
        }

        await viewModel.loadLibraries()
        #expect(viewModel.libraries.count == 1)
        #expect(viewModel.hasMorePages == true)

        await viewModel.loadMore()
        #expect(viewModel.libraries.count == 2)
        #expect(viewModel.libraries[0].slug == "community-library-amsterdam")
        #expect(viewModel.libraries[1].slug == "book-box-berlin")
        #expect(viewModel.hasMorePages == false)
        #expect(viewModel.isLoadingMore == false)
    }

    @Test func `load more does nothing when no more pages`() async {
        // Load with hasNext = false
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            LibraryListResponse(
                items: SampleData.libraries,
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 3, totalPages: 1,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }

        await viewModel.loadLibraries()
        #expect(viewModel.libraries.count == 3)

        // loadMore should return early — handler would crash if called
        // with an unexpected page, so no call = success
        var loadMoreCalled = false
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            loadMoreCalled = true
            fatalError("Should not be called")
        }

        await viewModel.loadMore()
        #expect(viewModel.libraries.count == 3)
        #expect(loadMoreCalled == false)
    }

    @Test func `load libraries error sets message`() async {
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            throw APIClientError.networkError(
                URLError(.notConnectedToInternet),
            )
        }

        await viewModel.loadLibraries()

        #expect(viewModel.libraries.isEmpty)
        #expect(viewModel.errorMessage == "Failed to load libraries")
        #expect(viewModel.isLoading == false)
    }

    @Test func `load more error sets message`() async {
        // First load succeeds
        stubClient.getLibrariesHandler = { page, _, _, _, _ in
            if page == 1 {
                return LibraryListResponse(
                    items: [SampleData.library],
                    pagination: PaginationMeta(
                        page: 1, pageSize: 1, total: 2, totalPages: 2,
                        hasNext: true, hasPrevious: false,
                    ),
                )
            }
            throw APIClientError.networkError(
                URLError(.notConnectedToInternet),
            )
        }

        await viewModel.loadLibraries()
        #expect(viewModel.libraries.count == 1)

        await viewModel.loadMore()

        // Original items preserved, error message set
        #expect(viewModel.libraries.count == 1)
        #expect(viewModel.errorMessage == "Failed to load more libraries")
        #expect(viewModel.isLoadingMore == false)
    }

    @Test func `load libraries passes coordinates`() async {
        var receivedLat: Double?
        var receivedLng: Double?

        stubClient.getLibrariesHandler = { _, _, _, lat, lng in
            receivedLat = lat
            receivedLng = lng
            return LibraryListResponse(
                items: [],
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 0, totalPages: 0,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }

        await viewModel.loadLibraries(lat: 52.37, lng: 4.90)

        #expect(receivedLat == 52.37)
        #expect(receivedLng == 4.90)
    }

    @Test func `perform search passes query and clears coordinates`() async {
        var receivedQuery: String?
        var receivedLat: Double?
        var receivedLng: Double?

        stubClient.getLibrariesHandler = { _, _, query, lat, lng in
            receivedQuery = query
            receivedLat = lat
            receivedLng = lng
            return LibraryListResponse(
                items: [SampleData.library],
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 1, totalPages: 1,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }

        await viewModel.performSearch(query: "Berlin")

        #expect(receivedQuery == "Berlin")
        #expect(receivedLat == nil)
        #expect(receivedLng == nil)
        #expect(viewModel.searchQuery == "Berlin")
        #expect(viewModel.libraries.count == 1)
    }

    @Test func `clear search resets query and reloads with coordinates`() async {
        // First, put the VM in search mode
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            LibraryListResponse(
                items: [SampleData.library],
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 1, totalPages: 1,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }
        await viewModel.performSearch(query: "Berlin")
        #expect(viewModel.searchQuery == "Berlin")

        // Now clear search with coordinates
        var receivedQuery: String?
        var receivedLat: Double?
        var receivedLng: Double?

        stubClient.getLibrariesHandler = { _, _, query, lat, lng in
            receivedQuery = query
            receivedLat = lat
            receivedLng = lng
            return LibraryListResponse(
                items: SampleData.libraries,
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 3, totalPages: 1,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }

        await viewModel.clearSearch(lat: 52.37, lng: 4.90)

        #expect(viewModel.searchQuery == "")
        #expect(receivedQuery == nil)
        #expect(receivedLat == 52.37)
        #expect(receivedLng == 4.90)
        #expect(viewModel.libraries.count == 3)
    }

    @Test func `switch to favourites mode loads from favourites endpoint`() async {
        stubClient.getFavouritesHandler = { _, _ in
            LibraryListResponse(
                items: [SampleData.library],
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 1, totalPages: 1,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }

        await viewModel.switchMode(.favourites)

        #expect(viewModel.listMode == .favourites)
        #expect(viewModel.libraries.count == 1)
        #expect(viewModel.libraries[0].slug == "community-library-amsterdam")
    }

    @Test func `switch back to nearby mode loads from nearby endpoint`() async {
        // Start in favourites mode
        stubClient.getFavouritesHandler = { _, _ in
            LibraryListResponse(
                items: [SampleData.library],
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 1, totalPages: 1,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }
        await viewModel.switchMode(.favourites)
        #expect(viewModel.listMode == .favourites)

        // Switch back to nearby
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            LibraryListResponse(
                items: SampleData.libraries,
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 3, totalPages: 1,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }
        await viewModel.switchMode(.nearby, lat: 52.37, lng: 4.90)

        #expect(viewModel.listMode == .nearby)
        #expect(viewModel.libraries.count == 3)
    }

    @Test func `favourites mode load more paginates correctly`() async {
        stubClient.getFavouritesHandler = { page, _ in
            if page == 1 {
                LibraryListResponse(
                    items: [SampleData.libraries[0]],
                    pagination: PaginationMeta(
                        page: 1, pageSize: 1, total: 2, totalPages: 2,
                        hasNext: true, hasPrevious: false,
                    ),
                )
            } else {
                LibraryListResponse(
                    items: [SampleData.libraries[1]],
                    pagination: PaginationMeta(
                        page: 2, pageSize: 1, total: 2, totalPages: 2,
                        hasNext: false, hasPrevious: true,
                    ),
                )
            }
        }

        await viewModel.switchMode(.favourites)
        #expect(viewModel.libraries.count == 1)
        #expect(viewModel.hasMorePages == true)

        await viewModel.loadMore()
        #expect(viewModel.libraries.count == 2)
        #expect(viewModel.hasMorePages == false)
    }

    @Test func `search with no results sets empty libraries`() async {
        stubClient.getLibrariesHandler = { _, _, _, _, _ in
            LibraryListResponse(
                items: [],
                pagination: PaginationMeta(
                    page: 1, pageSize: 20, total: 0, totalPages: 0,
                    hasNext: false, hasPrevious: false,
                ),
            )
        }

        await viewModel.performSearch(query: "xyznonexistent")

        #expect(viewModel.libraries.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.searchQuery == "xyznonexistent")
    }
}
