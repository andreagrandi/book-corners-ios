//
//  ReportViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct ReportViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: ReportViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = ReportViewModel(apiClient: stubClient, librarySlug: "test-library")
    }

    @Test func `default state has damaged reason and empty details`() {
        #expect(viewModel.reason == .damaged)
        #expect(viewModel.details.isEmpty)
        #expect(viewModel.didSubmitSuccessfully == false)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `submit success sets didSubmitSuccessfully`() async {
        await viewModel.submit()

        #expect(viewModel.didSubmitSuccessfully == true)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `submit error sets errorMessage`() async {
        stubClient.reportLibraryHandler = {
            throw APIClientError.networkError(URLError(.notConnectedToInternet))
        }

        await viewModel.submit()

        #expect(viewModel.didSubmitSuccessfully == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSubmitting == false)
    }
}
