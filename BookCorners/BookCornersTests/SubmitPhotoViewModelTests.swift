//
//  SubmitPhotoViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct SubmitPhotoViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: SubmitPhotoViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = SubmitPhotoViewModel(apiClient: stubClient, librarySlug: "test-library")
    }

    @Test func `default state has no photo and empty caption`() {
        #expect(viewModel.photoData == nil)
        #expect(viewModel.caption.isEmpty)
        #expect(viewModel.isValid == false)
        #expect(viewModel.didSubmitSuccessfully == false)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `isValid becomes true when photoData is set`() {
        viewModel.photoData = Data([0xFF, 0xD8])

        #expect(viewModel.isValid == true)
    }

    @Test func `submit success sets didSubmitSuccessfully`() async {
        viewModel.photoData = Data([0xFF, 0xD8])

        await viewModel.submit()

        #expect(viewModel.didSubmitSuccessfully == true)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `submit error sets errorMessage`() async {
        viewModel.photoData = Data([0xFF, 0xD8])
        stubClient.addPhotoHandler = {
            throw APIClientError.networkError(URLError(.notConnectedToInternet))
        }

        await viewModel.submit()

        #expect(viewModel.didSubmitSuccessfully == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSubmitting == false)
    }

    @Test func `submit without photo does nothing`() async {
        await viewModel.submit()

        #expect(viewModel.didSubmitSuccessfully == false)
        #expect(viewModel.isSubmitting == false)
    }

    @Test func `caption is passed when not empty`() async {
        viewModel.photoData = Data([0xFF, 0xD8])
        viewModel.caption = "Front view"

        await viewModel.submit()

        #expect(viewModel.didSubmitSuccessfully == true)
    }
}
