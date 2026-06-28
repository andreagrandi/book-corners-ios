//
//  ModerationLibraryQueueViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct ModerationLibraryQueueViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: ModerationLibraryQueueViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = ModerationLibraryQueueViewModel(client: stubClient, pageSize: 2)
    }

    @Test func `load initial fetches summary and pending library queue`() async {
        var summaryCallCount = 0
        var listCallCount = 0

        stubClient.getModerationSummaryHandler = {
            summaryCallCount += 1
            return Self.summary(pendingLibrariesCount: 2)
        }
        stubClient.getModerationLibrariesHandler = { request in
            listCallCount += 1
            #expect(request.status == .pending)
            #expect(request.query == nil)
            #expect(request.page == 1)
            #expect(request.pageSize == 2)
            return Self.listResponse(
                items: [Self.library(slug: "first-library")],
                hasNext: true,
            )
        }

        await viewModel.loadInitialIfNeeded()

        #expect(summaryCallCount == 1)
        #expect(listCallCount == 1)
        #expect(viewModel.summary?.pendingLibrariesCount == 2)
        #expect(viewModel.libraries.map(\.slug) == ["first-library"])
        #expect(viewModel.hasMorePages == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `search and status filter update library request`() async {
        stubClient.getModerationLibrariesHandler = { _ in
            Self.listResponse(items: [Self.library()])
        }

        await viewModel.performSearch(query: "  Florence  ")

        var request = stubClient.lastModerationLibraryListRequest
        #expect(request?.query == "Florence")
        #expect(request?.status == .pending)
        #expect(request?.page == 1)

        await viewModel.setStatusFilter(.approved)

        request = stubClient.lastModerationLibraryListRequest
        #expect(request?.query == "Florence")
        #expect(request?.status == .approved)
        #expect(request?.page == 1)
    }

    @Test func `refresh reloads counts and resets paginated list`() async {
        var summaryCallCount = 0
        stubClient.getModerationSummaryHandler = {
            summaryCallCount += 1
            return Self.summary(pendingLibrariesCount: summaryCallCount)
        }
        stubClient.getModerationLibrariesHandler = { request in
            if request.page == 1 {
                return Self.listResponse(
                    items: [Self.library(slug: "page-one")],
                    hasNext: true,
                )
            }
            return Self.listResponse(
                items: [Self.library(slug: "page-two")],
                page: 2,
            )
        }

        await viewModel.loadInitialIfNeeded()
        await viewModel.loadMore()
        #expect(viewModel.libraries.map(\.slug) == ["page-one", "page-two"])

        await viewModel.refresh()

        #expect(viewModel.summary?.pendingLibrariesCount == 2)
        #expect(viewModel.libraries.map(\.slug) == ["page-one"])
        #expect(stubClient.lastModerationLibraryListRequest?.page == 1)
    }

    @Test func `approve sends approved update and refreshes queue`() async throws {
        var didApprove = false
        stubClient.getModerationSummaryHandler = {
            Self.summary(pendingLibrariesCount: didApprove ? 0 : 1)
        }
        stubClient.getModerationLibrariesHandler = { _ in
            Self.listResponse(items: didApprove ? [] : [Self.library(slug: "pending-library")])
        }
        stubClient.updateModerationLibraryHandler = { slug, status, rejectionReason in
            didApprove = true
            return Self.library(
                slug: slug,
                status: status,
                rejectionReason: rejectionReason ?? "",
            )
        }

        await viewModel.loadInitialIfNeeded()
        let library = try #require(viewModel.libraries.first)

        await viewModel.approve(library)

        let update = try #require(stubClient.lastModerationLibraryUpdate)
        #expect(update.slug == "pending-library")
        #expect(update.status == .approved)
        #expect(update.rejectionReason == nil)
        #expect(viewModel.summary?.pendingLibrariesCount == 0)
        #expect(viewModel.libraries.isEmpty)
        #expect(viewModel.detailLibrary?.status == .approved)
        #expect(viewModel.actionErrorMessage == nil)
    }

    @Test func `reject trims reason and sends rejected update`() async throws {
        stubClient.updateModerationLibraryHandler = { slug, status, rejectionReason in
            Self.library(
                slug: slug,
                status: status,
                rejectionReason: rejectionReason ?? "",
            )
        }

        let library = Self.library(slug: "duplicate-library")
        await viewModel.reject(library, reason: "  Duplicate submission.  ")

        let update = try #require(stubClient.lastModerationLibraryUpdate)
        #expect(update.slug == "duplicate-library")
        #expect(update.status == .rejected)
        #expect(update.rejectionReason == "Duplicate submission.")
        #expect(viewModel.detailLibrary?.status == .rejected)
        #expect(viewModel.detailLibrary?.rejectionReason == "Duplicate submission.")
    }

    @Test func `reject requires a non-empty reason`() async {
        await viewModel.reject(Self.library(), reason: "   ")

        #expect(stubClient.lastModerationLibraryUpdate == nil)
        #expect(viewModel.actionErrorMessage == "Enter a rejection reason before rejecting this library.")
    }

    @Test func `load failure exposes user-facing error`() async {
        stubClient.getModerationSummaryHandler = {
            throw APIClientError.networkError(URLError(.notConnectedToInternet))
        }

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.libraries.isEmpty)
        #expect(viewModel.errorMessage == "Unable to connect. Check your internet connection.")
        #expect(viewModel.isLoading == false)
    }

    @Test func `action failure preserves queue and exposes action error`() async {
        stubClient.updateModerationLibraryHandler = { _, _, _ in
            throw APIClientError.forbidden(message: "Staff access required.")
        }

        await viewModel.approve(Self.library())

        #expect(viewModel.actionErrorMessage == "Staff access required.")
        #expect(viewModel.updatingLibrarySlug == nil)
    }

    private static func summary(pendingLibrariesCount: Int) -> ModerationSummary {
        ModerationSummary(
            pendingLibrariesCount: pendingLibrariesCount,
            openReportsCount: 1,
            pendingPhotosCount: 2,
            totalPending: pendingLibrariesCount + 3,
            totalLibraries: 350,
            totalUsers: 128,
        )
    }

    private static func listResponse(
        items: [ModerationLibrary],
        page: Int = 1,
        hasNext: Bool = false,
    ) -> ModerationLibraryListResponse {
        ModerationLibraryListResponse(
            items: items,
            pagination: PaginationMeta(
                page: page,
                pageSize: 2,
                total: items.count,
                totalPages: hasNext ? page + 1 : page,
                hasNext: hasNext,
                hasPrevious: page > 1,
            ),
        )
    }

    private static func library(
        slug: String = "pending-library",
        status: LibraryModerationStatus = .pending,
        rejectionReason: String = "",
    ) -> ModerationLibrary {
        ModerationLibrary(
            id: abs(slug.hashValue),
            slug: slug,
            name: "Corner Books",
            description: "A cozy book-sharing library near the park entrance.",
            photoUrl: "/media/libraries/photos/corner-books.jpg",
            thumbnailUrl: "/media/libraries/thumbnails/corner-books.jpg",
            lat: 43.7696,
            lng: 11.2558,
            address: "Via Rosina 15",
            city: "Florence",
            country: "IT",
            postalCode: "50123",
            wheelchairAccessible: "",
            capacity: nil,
            isIndoor: nil,
            isLit: nil,
            website: "",
            contact: "",
            source: "user",
            operatorName: "Book Club Florence",
            brand: "",
            createdAt: Date(timeIntervalSince1970: 1_782_048_600),
            isFavourited: false,
            status: status,
            rejectionReason: rejectionReason,
            createdBy: ModerationUser(id: 1, username: "janedoe"),
        )
    }
}
