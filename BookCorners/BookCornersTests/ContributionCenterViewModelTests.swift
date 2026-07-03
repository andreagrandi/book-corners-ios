//
//  ContributionCenterViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct ContributionCenterViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: ContributionCenterViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = ContributionCenterViewModel(client: stubClient, pageSize: 2)
    }

    @Test func `load initial data populates every contribution section`() async {
        stubClient.getContributionLibrariesHandler = { page, pageSize in
            ContributionLibraryListResponse(
                items: [Self.library(id: 1, slug: "first-library")],
                pagination: Self.pagination(page: page, pageSize: pageSize, total: 4, hasNext: true),
            )
        }
        stubClient.getContributionReportsHandler = { page, pageSize in
            ContributionReportListResponse(
                items: [Self.report(id: 10)],
                pagination: Self.pagination(page: page, pageSize: pageSize, total: 1, hasNext: false),
            )
        }
        stubClient.getContributionPhotosHandler = { page, pageSize in
            ContributionPhotoListResponse(
                items: [Self.photo(id: 20)],
                pagination: Self.pagination(page: page, pageSize: pageSize, total: 2, hasNext: true),
            )
        }
        stubClient.getFavouritesHandler = { page, pageSize in
            LibraryListResponse(
                items: [SampleData.library],
                pagination: Self.pagination(page: page, pageSize: pageSize, total: 1, hasNext: false),
            )
        }

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.librarySubmissions.count == 1)
        #expect(viewModel.reports.count == 1)
        #expect(viewModel.photos.count == 1)
        #expect(viewModel.favourites.count == 1)
        #expect(viewModel.librarySubmissionCount == 4)
        #expect(viewModel.reportCount == 1)
        #expect(viewModel.photoCount == 2)
        #expect(viewModel.favouriteCount == 1)
        #expect(viewModel.hasMoreLibraries == true)
        #expect(viewModel.hasMorePhotos == true)
        #expect(viewModel.isLoadingLibraries == false)
        #expect(viewModel.isLoadingReports == false)
        #expect(viewModel.isLoadingPhotos == false)
        #expect(viewModel.isLoadingFavourites == false)
        #expect(stubClient.lastContributionLibrariesRequest?.page == 1)
        #expect(stubClient.lastContributionLibrariesRequest?.pageSize == 2)
        #expect(stubClient.lastFavouritesRequest?.pageSize == 2)
    }

    @Test func `load initial data keeps successful sections when one section fails`() async {
        stubClient.getContributionLibrariesHandler = { page, pageSize in
            ContributionLibraryListResponse(
                items: [Self.library(id: 1, slug: "first-library")],
                pagination: Self.pagination(page: page, pageSize: pageSize, total: 1, hasNext: false),
            )
        }
        stubClient.getContributionReportsHandler = { _, _ in
            throw APIClientError.networkError(URLError(.notConnectedToInternet))
        }
        stubClient.getContributionPhotosHandler = { page, pageSize in
            ContributionPhotoListResponse(
                items: [Self.photo(id: 20)],
                pagination: Self.pagination(page: page, pageSize: pageSize, total: 1, hasNext: false),
            )
        }
        stubClient.getFavouritesHandler = { page, pageSize in
            LibraryListResponse(
                items: [SampleData.library],
                pagination: Self.pagination(page: page, pageSize: pageSize, total: 1, hasNext: false),
            )
        }

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.librarySubmissions.count == 1)
        #expect(viewModel.photos.count == 1)
        #expect(viewModel.favourites.count == 1)
        #expect(viewModel.reports.isEmpty)
        #expect(viewModel.reportErrorMessage == "Failed to load reports")
        #expect(viewModel.libraryErrorMessage == nil)
        #expect(viewModel.photoErrorMessage == nil)
        #expect(viewModel.favouriteErrorMessage == nil)
    }

    @Test func `load more library submissions appends next page`() async {
        stubClient.getContributionLibrariesHandler = { page, pageSize in
            if page == 1 {
                return ContributionLibraryListResponse(
                    items: [Self.library(id: 1, slug: "first-library")],
                    pagination: Self.pagination(page: page, pageSize: pageSize, total: 2, hasNext: true),
                )
            }
            return ContributionLibraryListResponse(
                items: [Self.library(id: 2, slug: "second-library")],
                pagination: Self.pagination(page: page, pageSize: pageSize, total: 2, hasNext: false),
            )
        }
        stubClient.getContributionReportsHandler = { page, pageSize in
            ContributionReportListResponse(items: [], pagination: Self.pagination(page: page, pageSize: pageSize, total: 0, hasNext: false))
        }
        stubClient.getContributionPhotosHandler = { page, pageSize in
            ContributionPhotoListResponse(items: [], pagination: Self.pagination(page: page, pageSize: pageSize, total: 0, hasNext: false))
        }
        stubClient.getFavouritesHandler = { page, pageSize in
            LibraryListResponse(items: [], pagination: Self.pagination(page: page, pageSize: pageSize, total: 0, hasNext: false))
        }

        await viewModel.loadInitialIfNeeded()
        await viewModel.loadMoreLibrarySubmissions()

        #expect(viewModel.librarySubmissions.map(\.slug) == ["first-library", "second-library"])
        #expect(viewModel.hasMoreLibraries == false)
        #expect(viewModel.isLoadingMoreLibraries == false)
        #expect(stubClient.lastContributionLibrariesRequest?.page == 2)
    }

    @Test func `load initial if needed only fetches once`() async {
        var libraryCalls = 0
        stubClient.getContributionLibrariesHandler = { page, pageSize in
            libraryCalls += 1
            return ContributionLibraryListResponse(items: [], pagination: Self.pagination(page: page, pageSize: pageSize, total: 0, hasNext: false))
        }
        stubClient.getContributionReportsHandler = { page, pageSize in
            ContributionReportListResponse(items: [], pagination: Self.pagination(page: page, pageSize: pageSize, total: 0, hasNext: false))
        }
        stubClient.getContributionPhotosHandler = { page, pageSize in
            ContributionPhotoListResponse(items: [], pagination: Self.pagination(page: page, pageSize: pageSize, total: 0, hasNext: false))
        }
        stubClient.getFavouritesHandler = { page, pageSize in
            LibraryListResponse(items: [], pagination: Self.pagination(page: page, pageSize: pageSize, total: 0, hasNext: false))
        }

        await viewModel.loadInitialIfNeeded()
        await viewModel.loadInitialIfNeeded()

        #expect(libraryCalls == 1)
    }

    private static func pagination(
        page: Int,
        pageSize: Int,
        total: Int,
        hasNext: Bool,
    ) -> PaginationMeta {
        PaginationMeta(
            page: page,
            pageSize: pageSize,
            total: total,
            totalPages: hasNext ? page + 1 : page,
            hasNext: hasNext,
            hasPrevious: page > 1,
        )
    }

    private static func library(
        id: Int,
        slug: String,
        status: LibraryModerationStatus = .approved,
    ) -> ContributionLibrary {
        let library = SampleData.contributionLibrary
        return ContributionLibrary(
            id: id,
            slug: slug,
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
            rejectionReason: library.rejectionReason,
        )
    }

    private static func report(id: Int) -> ContributionReport {
        ContributionReport(
            id: id,
            library: SampleData.contributionLibrarySummary,
            reason: .damaged,
            status: .open,
            createdAt: Date(),
        )
    }

    private static func photo(id: Int) -> ContributionPhoto {
        ContributionPhoto(
            id: id,
            library: SampleData.contributionLibrarySummary,
            caption: "Front view",
            photoUrl: "/media/libraries/user_photos/photo.jpg",
            thumbnailUrl: "/media/libraries/user_photos/thumbnails/photo.jpg",
            status: .pending,
            createdAt: Date(),
        )
    }
}
