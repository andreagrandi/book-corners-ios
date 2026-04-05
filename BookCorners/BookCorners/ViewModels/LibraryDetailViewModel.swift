//
//  LibraryDetailViewModel.swift
//  BookCorners
//
//  Created by Andrea Grandi on 20/03/26.
//

import Foundation

extension Notification.Name {
    static let favouriteToggled = Notification.Name("favouriteToggled")
}

@Observable
class LibraryDetailViewModel {
    var library: Library
    var apiClient: any APIClientProtocol
    var isLoading: Bool = false
    var isFavouriting: Bool = false
    var errorMessage: String?

    init(library: Library, client: any APIClientProtocol) {
        self.library = library
        apiClient = client
    }

    func toggleFavourite() async {
        let wasFavourited = library.isFavourited == true
        isFavouriting = true
        defer { isFavouriting = false }

        // Optimistic update
        library.isFavourited = !wasFavourited

        do {
            if wasFavourited {
                try await apiClient.removeFavourite(slug: library.slug)
            } else {
                _ = try await apiClient.addFavourite(slug: library.slug)
            }
            apiClient.invalidateLibraryCache(slug: library.slug)
            NotificationCenter.default.post(name: .favouriteToggled, object: nil)
        } catch {
            // Revert on failure
            library.isFavourited = wasFavourited
            errorMessage = "Failed to update favourite"
        }
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            library = try await apiClient.getLibrary(slug: library.slug)
        } catch {
            errorMessage = "Error fetching library details"
        }
    }
}
