//
//  ModerationPhotoQueueViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct ModerationPhotoQueueViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: ModerationPhotoQueueViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = ModerationPhotoQueueViewModel(client: stubClient, pageSize: 2)
    }

    @Test func `load initial fetches summary and pending photo queue`() async {
        var summaryCallCount = 0
        var listCallCount = 0

        stubClient.getModerationSummaryHandler = {
            summaryCallCount += 1
            return Self.summary(pendingPhotosCount: 2)
        }
        stubClient.getModerationPhotosHandler = { request in
            listCallCount += 1
            #expect(request.status == .pending)
            #expect(request.page == 1)
            #expect(request.pageSize == 2)
            return Self.listResponse(
                items: [Self.photo(id: 1)],
                hasNext: true,
            )
        }

        await viewModel.loadInitialIfNeeded()

        #expect(summaryCallCount == 1)
        #expect(listCallCount == 1)
        #expect(viewModel.summary?.pendingPhotosCount == 2)
        #expect(viewModel.photos.map(\.id) == [1])
        #expect(viewModel.hasMorePages == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `status filter updates photo request`() async {
        stubClient.getModerationPhotosHandler = { _ in
            Self.listResponse(items: [Self.photo()])
        }

        await viewModel.setStatusFilter(.approved)

        let request = stubClient.lastModerationPhotoListRequest
        #expect(request?.status == .approved)
        #expect(request?.page == 1)
        #expect(request?.pageSize == 2)
    }

    @Test func `refresh reloads counts and resets paginated list`() async {
        var summaryCallCount = 0
        stubClient.getModerationSummaryHandler = {
            summaryCallCount += 1
            return Self.summary(pendingPhotosCount: summaryCallCount)
        }
        stubClient.getModerationPhotosHandler = { request in
            if request.page == 1 {
                return Self.listResponse(
                    items: [Self.photo(id: 1)],
                    hasNext: true,
                )
            }
            return Self.listResponse(
                items: [Self.photo(id: 2)],
                page: 2,
            )
        }

        await viewModel.loadInitialIfNeeded()
        await viewModel.loadMore()
        #expect(viewModel.photos.map(\.id) == [1, 2])

        await viewModel.refresh()

        #expect(viewModel.summary?.pendingPhotosCount == 2)
        #expect(viewModel.photos.map(\.id) == [1])
        #expect(stubClient.lastModerationPhotoListRequest?.page == 1)
    }

    @Test func `approve sends approved update and refreshes queue`() async throws {
        var didApprove = false
        stubClient.getModerationSummaryHandler = {
            Self.summary(pendingPhotosCount: didApprove ? 0 : 1)
        }
        stubClient.getModerationPhotosHandler = { _ in
            Self.listResponse(items: didApprove ? [] : [Self.photo(id: 7)])
        }
        stubClient.updateModerationPhotoHandler = { id, status in
            didApprove = true
            return Self.photo(id: id, status: status)
        }

        await viewModel.loadInitialIfNeeded()
        let photo = try #require(viewModel.photos.first)

        await viewModel.approve(photo)

        let update = try #require(stubClient.lastModerationPhotoUpdate)
        #expect(update.id == 7)
        #expect(update.status == .approved)
        #expect(viewModel.summary?.pendingPhotosCount == 0)
        #expect(viewModel.photos.isEmpty)
        #expect(viewModel.detailPhoto?.status == .approved)
        #expect(viewModel.actionErrorMessage == nil)
    }

    @Test func `reject sends rejected update and refreshes queue`() async throws {
        var didReject = false
        stubClient.getModerationSummaryHandler = {
            Self.summary(pendingPhotosCount: didReject ? 0 : 1)
        }
        stubClient.getModerationPhotosHandler = { _ in
            Self.listResponse(items: didReject ? [] : [Self.photo(id: 8)])
        }
        stubClient.updateModerationPhotoHandler = { id, status in
            didReject = true
            return Self.photo(id: id, status: status)
        }

        await viewModel.loadInitialIfNeeded()
        let photo = try #require(viewModel.photos.first)

        await viewModel.reject(photo)

        let update = try #require(stubClient.lastModerationPhotoUpdate)
        #expect(update.id == 8)
        #expect(update.status == .rejected)
        #expect(viewModel.summary?.pendingPhotosCount == 0)
        #expect(viewModel.photos.isEmpty)
        #expect(viewModel.detailPhoto?.status == .rejected)
    }

    @Test func `load failure exposes user-facing error`() async {
        stubClient.getModerationSummaryHandler = {
            throw APIClientError.networkError(URLError(.notConnectedToInternet))
        }

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.photos.isEmpty)
        #expect(viewModel.errorMessage == "Unable to connect. Check your internet connection.")
        #expect(viewModel.isLoading == false)
    }

    @Test func `action failure preserves queue and exposes action error`() async {
        stubClient.updateModerationPhotoHandler = { _, _ in
            throw APIClientError.forbidden(message: "Staff access required.")
        }

        await viewModel.approve(Self.photo(id: 9))

        #expect(viewModel.actionErrorMessage == "Staff access required.")
        #expect(viewModel.updatingPhotoID == nil)
    }

    private static func summary(pendingPhotosCount: Int) -> ModerationSummary {
        ModerationSummary(
            pendingLibrariesCount: 1,
            openReportsCount: 1,
            pendingPhotosCount: pendingPhotosCount,
            totalPending: pendingPhotosCount + 2,
            totalLibraries: 350,
            totalUsers: 128,
        )
    }

    private static func listResponse(
        items: [ModerationPhoto],
        page: Int = 1,
        hasNext: Bool = false,
    ) -> ModerationPhotoListResponse {
        ModerationPhotoListResponse(
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

    private static func photo(
        id: Int = 7,
        status: PhotoModerationStatus = .pending,
        caption: String = "Front view",
    ) -> ModerationPhoto {
        ModerationPhoto(
            id: id,
            library: ModerationLibrarySummary(
                id: 42,
                slug: "florence-via-rosina-15-corner-books",
                name: "Corner Books",
                address: "Via Rosina 15",
                city: "Florence",
                country: "IT",
                status: .approved,
            ),
            createdBy: ModerationUser(id: 3, username: "reader"),
            caption: caption,
            photoUrl: "/media/libraries/user_photos/photo-\(id).jpg",
            thumbnailUrl: "/media/libraries/user_photos/thumbnails/photo-\(id).jpg",
            status: status,
            createdAt: Date(timeIntervalSince1970: 1_782_135_600),
        )
    }
}
