//
//  SubmitLibraryViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct SubmitLibraryViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: SubmitLibraryViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = SubmitLibraryViewModel(client: stubClient)
    }

    @Test func `isValid false when no photo`() {
        viewModel.address = "Via Roma 1"
        viewModel.city = "Florence"
        viewModel.country = "IT"
        viewModel.latitude = 43.77
        viewModel.longitude = 11.25

        #expect(viewModel.isValid == false)
    }

    @Test func `isValid false when missing address`() {
        viewModel.photoData = Data([0xFF])
        viewModel.city = "Florence"
        viewModel.country = "IT"
        viewModel.latitude = 43.77
        viewModel.longitude = 11.25

        #expect(viewModel.isValid == false)
    }

    @Test func `isValid false when missing coordinates`() {
        viewModel.photoData = Data([0xFF])
        viewModel.address = "Via Roma 1"
        viewModel.city = "Florence"
        viewModel.country = "IT"

        #expect(viewModel.isValid == false)
    }

    @Test func `isValid true when all required fields present`() {
        viewModel.photoData = Data([0xFF])
        viewModel.address = "Via Roma 1"
        viewModel.city = "Florence"
        viewModel.country = "IT"
        viewModel.latitude = 43.77
        viewModel.longitude = 11.25

        #expect(viewModel.isValid == true)
    }

    @Test func `submit success sets submittedLibrary`() async {
        viewModel.photoData = Data([0xFF])
        viewModel.address = "Via Roma 1"
        viewModel.city = "Florence"
        viewModel.country = "IT"
        viewModel.latitude = 43.77
        viewModel.longitude = 11.25

        await viewModel.submit()

        #expect(viewModel.submittedLibrary != nil)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `submit error sets errorMessage`() async {
        viewModel.photoData = Data([0xFF])
        viewModel.address = "Via Roma 1"
        viewModel.city = "Florence"
        viewModel.country = "IT"
        viewModel.latitude = 43.77
        viewModel.longitude = 11.25

        stubClient.submitLibraryHandler = { throw APIClientError.networkError(URLError(.notConnectedToInternet)) }

        await viewModel.submit()

        #expect(viewModel.submittedLibrary == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isSubmitting == false)
    }

    @Test func `reset clears all fields`() {
        viewModel.photoData = Data([0xFF])
        viewModel.address = "Via Roma 1"
        viewModel.city = "Florence"
        viewModel.country = "IT"
        viewModel.latitude = 43.77
        viewModel.longitude = 11.25
        viewModel.name = "Test Library"

        viewModel.reset()

        #expect(viewModel.photoData == nil)
        #expect(viewModel.address.isEmpty)
        #expect(viewModel.city.isEmpty)
        #expect(viewModel.country.isEmpty)
        #expect(viewModel.latitude == nil)
        #expect(viewModel.longitude == nil)
        #expect(viewModel.name.isEmpty)
    }

    @Test func `EXIF reader returns nil for data without GPS`() {
        let noGPSData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let coordinate = EXIFReader.extractCoordinates(from: noGPSData)
        #expect(coordinate == nil)
    }
}
