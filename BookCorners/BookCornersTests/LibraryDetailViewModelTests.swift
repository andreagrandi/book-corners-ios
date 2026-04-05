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
        #expect(viewModel.library.slug == "community-library-amsterdam")
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `refresh success updates library`() async {
        let updatedLibrary = Library(
            id: 1,
            slug: "community-library-amsterdam",
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

        #expect(viewModel.library.slug == "community-library-amsterdam")
        #expect(viewModel.library.name == "Community Library Amsterdam")
        #expect(viewModel.errorMessage == "Error fetching library details")
        #expect(viewModel.isLoading == false)
    }

    @Test func `toggleFavourite adds favourite when not favourited`() async {
        var addedSlug: String?
        stubClient.addFavouriteHandler = { slug in
            addedSlug = slug
            return MessageResponse(message: "Library added to favourites.")
        }

        #expect(viewModel.library.isFavourited != true)

        await viewModel.toggleFavourite()

        #expect(viewModel.library.isFavourited == true)
        #expect(addedSlug == "community-library-amsterdam")
        #expect(viewModel.isFavouriting == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func `toggleFavourite removes favourite when favourited`() async {
        // Start with a favourited library
        let favouritedLibrary = Library(
            id: 1, slug: "community-library-amsterdam",
            name: "Community Library Amsterdam",
            description: "A cozy street library",
            photoUrl: "", thumbnailUrl: "",
            lat: 52.3676, lng: 4.9041,
            address: "Keizersgracht 123",
            city: "Amsterdam", country: "NL",
            postalCode: "1015 CJ",
            wheelchairAccessible: "yes",
            capacity: 50, isIndoor: false, isLit: true,
            website: "", contact: "", source: "osm",
            operatorName: "", brand: "",
            createdAt: Date(),
            isFavourited: true,
        )
        let vm = LibraryDetailViewModel(library: favouritedLibrary, client: stubClient)

        var removedSlug: String?
        stubClient.removeFavouriteHandler = { slug in
            removedSlug = slug
        }

        await vm.toggleFavourite()

        #expect(vm.library.isFavourited == false)
        #expect(removedSlug == "community-library-amsterdam")
        #expect(vm.errorMessage == nil)
    }

    @Test func `toggleFavourite reverts on API failure`() async {
        stubClient.addFavouriteHandler = { _ in
            throw APIClientError.networkError(URLError(.notConnectedToInternet))
        }

        #expect(viewModel.library.isFavourited != true)

        await viewModel.toggleFavourite()

        // Should revert to original state
        #expect(viewModel.library.isFavourited != true)
        #expect(viewModel.errorMessage == "Failed to update favourite")
        #expect(viewModel.isFavouriting == false)
    }
}
