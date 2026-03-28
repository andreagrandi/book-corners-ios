//
//  LibraryListView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 13/03/26.
//

import CoreLocation
import SwiftUI

struct LibraryListView: View {
    @Environment(\.apiClient) private var apiClient: APIClient
    @Environment(LocationService.self) private var locationService: LocationService
    @State private var viewModel: LibraryListViewModel?
    @State private var hasLoadedWithLocation = false
    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            if searchText.isEmpty, !locationService.isAuthorized {
                locationCTA
            } else if let viewModel {
                if viewModel.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage, retryAction: {
                        Task {
                            await viewModel.loadLibraries(
                                lat: locationService.currentLocation?.coordinate.latitude,
                                lng: locationService.currentLocation?.coordinate.longitude,
                            )
                        }
                    })
                } else if viewModel.libraries.isEmpty {
                    if searchText.isEmpty {
                        EmptyStateView(
                            message: "No libraries found nearby. Try pulling to refresh.",
                            title: "No Libraries Found",
                            icon: "books.vertical",
                        )
                    } else {
                        EmptyStateView(
                            message: "No libraries found for \"\(searchText)\".",
                            title: "No Libraries Found",
                            icon: "books.vertical",
                        )
                    }
                } else {
                    List {
                        ForEach(viewModel.libraries) { library in
                            NavigationLink(value: library) {
                                LibraryCardView(
                                    library: library,
                                    distance: distanceTo(library),
                                )
                                .onAppear {
                                    if library.id == viewModel.libraries.last?.id {
                                        Task {
                                            await viewModel.loadMore(
                                                lat: locationService.currentLocation?.coordinate.latitude,
                                                lng: locationService.currentLocation?.coordinate.longitude,
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        if viewModel.isLoadingMore {
                            ProgressView()
                        }
                    }
                    .navigationDestination(for: Library.self) { library in
                        LibraryDetailView(library: library)
                    }
                }
            }
        }
        .navigationTitle(searchText.isEmpty ? "Nearby" : "Results")
        .task {
            if viewModel == nil {
                viewModel = LibraryListViewModel(client: apiClient)
            }
            guard locationService.currentLocation != nil || !searchText.isEmpty else { return }
            await viewModel?.loadLibraries(
                lat: locationService.currentLocation?.coordinate.latitude,
                lng: locationService.currentLocation?.coordinate.longitude,
            )
        }
        .refreshable {
            await viewModel?.refresh(
                lat: locationService.currentLocation?.coordinate.latitude,
                lng: locationService.currentLocation?.coordinate.longitude,
            )
        }
        .onChange(of: locationService.currentLocation) { _, newValue in
            guard let newValue, !hasLoadedWithLocation else { return }
            hasLoadedWithLocation = true
            Task {
                await viewModel?.loadLibraries(
                    lat: newValue.coordinate.latitude,
                    lng: newValue.coordinate.longitude,
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search by city, area, or name")
        .onChange(of: searchText) {
            searchTask?.cancel() // always cancel previous

            if searchText.isEmpty {
                Task {
                    await viewModel?.clearSearch(
                        lat: locationService.currentLocation?.coordinate.latitude,
                        lng: locationService.currentLocation?.coordinate.longitude,
                    )
                }
            } else {
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !Task.isCancelled else { return }
                    await viewModel?.performSearch(query: searchText)
                }
            }
        }
        .onSubmit(of: .search) {
            searchTask?.cancel()

            if !searchText.isEmpty {
                Task {
                    await viewModel?.performSearch(query: searchText)
                }
            }
        }
    }

    private var locationCTA: some View {
        ContentUnavailableView {
            Label("See Libraries Near You", systemImage: "location.circle")
        } description: {
            Text("Enable location to find book-sharing libraries closest to you.")
        } actions: {
            if locationService.authorizationStatus == .notDetermined {
                Button("Enable Location") {
                    locationService.startMonitoring()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func distanceTo(_ library: Library) -> CLLocationDistance? {
        guard let location = locationService.currentLocation else { return nil }
        return library.distance(from: location)
    }
}

#Preview {
    LibraryListView()
        .environment(LocationService())
        .environment(\.apiClient, APIClient())
}
