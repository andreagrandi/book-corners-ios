//
//  LibraryDetailViewModel.swift
//  BookCorners
//
//  Created by Andrea Grandi on 20/03/26.
//

import Foundation

@Observable
class LibraryDetailViewModel {
    var library: Library
    var apiClient: any APIClientProtocol
    var isLoading: Bool = false
    var errorMessage: String?

    init(library: Library, client: any APIClientProtocol) {
        self.library = library
        apiClient = client
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
