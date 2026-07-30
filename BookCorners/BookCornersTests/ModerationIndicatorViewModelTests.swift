//
//  ModerationIndicatorViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct ModerationIndicatorViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: ModerationIndicatorViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = ModerationIndicatorViewModel(client: stubClient)
    }

    @Test func `refresh shows pending work from moderation summary`() async {
        stubClient.getModerationSummaryHandler = {
            Self.summary(totalPending: 3)
        }

        await viewModel.refresh()

        #expect(viewModel.summary?.totalPending == 3)
        #expect(viewModel.hasPendingWork)
    }

    @Test func `refresh clears pending work when shared queue becomes empty`() async {
        var totalPending = 2
        stubClient.getModerationSummaryHandler = {
            Self.summary(totalPending: totalPending)
        }

        await viewModel.refresh()
        totalPending = 0
        await viewModel.refresh()

        #expect(viewModel.summary?.totalPending == 0)
        #expect(viewModel.hasPendingWork == false)
    }

    @Test func `refresh failure preserves last successful summary`() async {
        var shouldFail = false
        stubClient.getModerationSummaryHandler = {
            if shouldFail {
                throw APIClientError.networkError(URLError(.notConnectedToInternet))
            }
            return Self.summary(totalPending: 1)
        }

        await viewModel.refresh()
        shouldFail = true
        await viewModel.refresh()

        #expect(viewModel.summary?.totalPending == 1)
        #expect(viewModel.hasPendingWork)
    }

    private static func summary(totalPending: Int) -> ModerationSummary {
        ModerationSummary(
            pendingLibrariesCount: totalPending,
            openReportsCount: 0,
            pendingPhotosCount: 0,
            totalPending: totalPending,
            totalLibraries: 350,
            totalUsers: 128,
        )
    }
}
