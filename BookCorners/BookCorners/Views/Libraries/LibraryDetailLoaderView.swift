//
//  LibraryDetailLoaderView.swift
//  BookCorners
//

import SwiftUI

struct LibraryDetailLoaderView: View {
    @Environment(\.apiClient) private var apiClient

    let slug: String

    @State private var library: Library?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let library {
                LibraryDetailView(library: library)
            } else {
                loadingState
                    .navigationTitle("Library")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task {
            if library == nil, errorMessage == nil {
                await loadLibrary()
            }
        }
    }

    @ViewBuilder
    private var loadingState: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            ErrorView(message: errorMessage, retryAction: {
                Task {
                    await loadLibrary()
                }
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            EmptyStateView(
                message: "This library is not available yet.",
                title: "Library Unavailable",
                icon: "books.vertical",
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func loadLibrary() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            library = try await apiClient.getLibrary(slug: slug)
        } catch {
            errorMessage = "Failed to load library"
        }
    }
}

#Preview {
    NavigationStack {
        LibraryDetailLoaderView(slug: SampleData.library.slug)
    }
    .environment(\.apiClient, APIClient())
    .environment(AuthService(apiClient: APIClient(), keychainService: KeychainService()))
}
