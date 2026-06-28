//
//  ModerationReportQueueViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct ModerationReportQueueViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: ModerationReportQueueViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = ModerationReportQueueViewModel(client: stubClient, pageSize: 2)
    }

    @Test func `load initial fetches summary and open report queue`() async {
        var summaryCallCount = 0
        var listCallCount = 0

        stubClient.getModerationSummaryHandler = {
            summaryCallCount += 1
            return Self.summary(openReportsCount: 2)
        }
        stubClient.getModerationReportsHandler = { request in
            listCallCount += 1
            #expect(request.status == .open)
            #expect(request.reason == .all)
            #expect(request.page == 1)
            #expect(request.pageSize == 2)
            return Self.listResponse(
                items: [Self.report(id: 1)],
                hasNext: true,
            )
        }

        await viewModel.loadInitialIfNeeded()

        #expect(summaryCallCount == 1)
        #expect(listCallCount == 1)
        #expect(viewModel.summary?.openReportsCount == 2)
        #expect(viewModel.reports.map(\.id) == [1])
        #expect(viewModel.hasMorePages == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `status filter updates report request`() async {
        stubClient.getModerationReportsHandler = { _ in
            Self.listResponse(items: [Self.report(status: .resolved)])
        }

        await viewModel.setStatusFilter(.resolved)

        let request = stubClient.lastModerationReportListRequest
        #expect(request?.status == .resolved)
        #expect(request?.reason == .all)
        #expect(request?.page == 1)
        #expect(request?.pageSize == 2)
    }

    @Test func `reason filter updates report request`() async {
        stubClient.getModerationReportsHandler = { _ in
            Self.listResponse(items: [Self.report(reason: .incorrectInfo)])
        }

        await viewModel.setReasonFilter(.incorrectInfo)

        let request = stubClient.lastModerationReportListRequest
        #expect(request?.status == .open)
        #expect(request?.reason == .incorrectInfo)
        #expect(request?.page == 1)
        #expect(request?.pageSize == 2)
    }

    @Test func `refresh reloads counts and resets paginated list`() async {
        var summaryCallCount = 0
        stubClient.getModerationSummaryHandler = {
            summaryCallCount += 1
            return Self.summary(openReportsCount: summaryCallCount)
        }
        stubClient.getModerationReportsHandler = { request in
            if request.page == 1 {
                return Self.listResponse(
                    items: [Self.report(id: 1)],
                    hasNext: true,
                )
            }
            return Self.listResponse(
                items: [Self.report(id: 2)],
                page: 2,
            )
        }

        await viewModel.loadInitialIfNeeded()
        await viewModel.loadMore()
        #expect(viewModel.reports.map(\.id) == [1, 2])

        await viewModel.refresh()

        #expect(viewModel.summary?.openReportsCount == 2)
        #expect(viewModel.reports.map(\.id) == [1])
        #expect(stubClient.lastModerationReportListRequest?.page == 1)
    }

    @Test func `resolve sends resolved update and refreshes queue`() async throws {
        var didResolve = false
        stubClient.getModerationSummaryHandler = {
            Self.summary(openReportsCount: didResolve ? 0 : 1)
        }
        stubClient.getModerationReportsHandler = { _ in
            Self.listResponse(items: didResolve ? [] : [Self.report(id: 7)])
        }
        stubClient.updateModerationReportHandler = { id, status in
            didResolve = true
            return Self.report(id: id, status: status)
        }

        await viewModel.loadInitialIfNeeded()
        let report = try #require(viewModel.reports.first)

        await viewModel.resolve(report)

        let update = try #require(stubClient.lastModerationReportUpdate)
        #expect(update.id == 7)
        #expect(update.status == .resolved)
        #expect(viewModel.summary?.openReportsCount == 0)
        #expect(viewModel.reports.isEmpty)
        #expect(viewModel.detailReport?.status == .resolved)
        #expect(viewModel.actionErrorMessage == nil)
    }

    @Test func `dismiss sends dismissed update and refreshes queue`() async throws {
        var didDismiss = false
        stubClient.getModerationSummaryHandler = {
            Self.summary(openReportsCount: didDismiss ? 0 : 1)
        }
        stubClient.getModerationReportsHandler = { _ in
            Self.listResponse(items: didDismiss ? [] : [Self.report(id: 8)])
        }
        stubClient.updateModerationReportHandler = { id, status in
            didDismiss = true
            return Self.report(id: id, status: status)
        }

        await viewModel.loadInitialIfNeeded()
        let report = try #require(viewModel.reports.first)

        await viewModel.dismiss(report)

        let update = try #require(stubClient.lastModerationReportUpdate)
        #expect(update.id == 8)
        #expect(update.status == .dismissed)
        #expect(viewModel.summary?.openReportsCount == 0)
        #expect(viewModel.reports.isEmpty)
        #expect(viewModel.detailReport?.status == .dismissed)
    }

    @Test func `load failure exposes user-facing error`() async {
        stubClient.getModerationSummaryHandler = {
            throw APIClientError.networkError(URLError(.notConnectedToInternet))
        }

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.reports.isEmpty)
        #expect(viewModel.errorMessage == "Unable to connect. Check your internet connection.")
        #expect(viewModel.isLoading == false)
    }

    @Test func `action failure preserves queue and exposes action error`() async {
        stubClient.updateModerationReportHandler = { _, _ in
            throw APIClientError.forbidden(message: "Staff access required.")
        }

        await viewModel.resolve(Self.report(id: 9))

        #expect(viewModel.actionErrorMessage == "Staff access required.")
        #expect(viewModel.updatingReportID == nil)
    }

    private static func summary(openReportsCount: Int) -> ModerationSummary {
        ModerationSummary(
            pendingLibrariesCount: 1,
            openReportsCount: openReportsCount,
            pendingPhotosCount: 2,
            totalPending: openReportsCount + 3,
            totalLibraries: 350,
            totalUsers: 128,
        )
    }

    private static func listResponse(
        items: [ModerationReport],
        page: Int = 1,
        hasNext: Bool = false,
    ) -> ModerationReportListResponse {
        ModerationReportListResponse(
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

    private static func report(
        id: Int = 7,
        status: ReportModerationStatus = .open,
        reason: ReportReason = .damaged,
        details: String = "The door hinge is broken.",
    ) -> ModerationReport {
        ModerationReport(
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
            reason: reason,
            details: details,
            photoUrl: "/media/reports/photos/report-\(id).jpg",
            status: status,
            createdAt: Date(timeIntervalSince1970: 1_782_049_200),
        )
    }
}
