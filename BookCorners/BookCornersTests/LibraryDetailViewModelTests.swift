//
//  LibraryDetailViewModelTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Foundation
import Testing

@MainActor
struct LibraryDetailViewModelTests {
    let stubClient: StubAPIClient
    let viewModel: LibraryDetailViewModel

    init() {
        stubClient = StubAPIClient()
        viewModel = LibraryDetailViewModel(library: SampleData.library, client: stubClient)
    }

    @Test func `init exposes library immediately`() {
        #expect(viewModel.library.slug == "little-library-amsterdam")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `refresh success updates library`() async {
        let updatedLibrary = Library(
            id: 1,
            slug: "little-library-amsterdam",
            name: "Updated Name",
            description: "New description",
            photoUrl: "/media/new.jpg",
            thumbnailUrl: "/media/new-thumb.jpg",
            lat: 52.3676, lng: 4.9041,
            address: "Keizersgracht 123",
            city: "Amsterdam", country: "NL",
            postalCode: "1015 CJ",
            wheelchairAccessible: "yes",
            capacity: 50, isIndoor: false, isLit: true,
            website: "", contact: "", source: "osm",
            operatorName: "", brand: "",
            createdAt: Date(),
        )

        stubClient.getLibraryHandler = { _ in updatedLibrary }

        await viewModel.refresh()

        #expect(viewModel.library.name == "Updated Name")
        #expect(viewModel.library.description == "New description")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `refresh failure preserves original library`() async {
        stubClient.getLibraryHandler = { _ in
            throw APIClientError.networkError(URLError(.notConnectedToInternet))
        }

        await viewModel.refresh()

        #expect(viewModel.library.slug == "little-library-amsterdam")
        #expect(viewModel.library.name == "Little Library Amsterdam")
        #expect(viewModel.errorMessage == "Error fetching library details")
        #expect(viewModel.isLoading == false)
    }
}
