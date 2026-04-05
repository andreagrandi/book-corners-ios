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
    @Environment(AuthService.self) private var authService
    @State private var viewModel: LibraryListViewModel?
    @State private var hasLoadedWithLocation = false
    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Never>?

    private var isNearbyMode: Bool {
        viewModel?.listMode == .nearby
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if authService.isAuthenticated {
                    modePicker
                }

                if isNearbyMode, searchText.isEmpty, !locationService.isAuthorized {
                    locationCTA
                } else if let viewModel {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxHeight: .infinity)
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
                        emptyState
                    } else {
                        libraryList
                    }
                }
            }
            .navigationTitle(navigationTitle)
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
                guard let newValue, !hasLoadedWithLocation, isNearbyMode else { return }
                hasLoadedWithLocation = true
                Task {
                    await viewModel?.loadLibraries(
                        lat: newValue.coordinate.latitude,
                        lng: newValue.coordinate.longitude,
                    )
                }
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if !isAuthenticated, viewModel?.listMode == .favourites {
                    Task {
                        await viewModel?.switchMode(
                            .nearby,
                            lat: locationService.currentLocation?.coordinate.latitude,
                            lng: locationService.currentLocation?.coordinate.longitude,
                        )
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search by city, area, or name")
            .onChange(of: searchText) {
                searchTask?.cancel()

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
            .onReceive(NotificationCenter.default.publisher(for: .favouriteToggled)) { _ in
                Task {
                    await viewModel?.refresh(
                        lat: locationService.currentLocation?.coordinate.latitude,
                        lng: locationService.currentLocation?.coordinate.longitude,
                    )
                }
            }
        }
    }

    private var navigationTitle: String {
        if let viewModel {
            switch viewModel.listMode {
            case .nearby:
                return searchText.isEmpty ? "Nearby" : "Results"
            case .favourites:
                return "Favourites"
            }
        }
        return "Nearby"
    }

    private var modePicker: some View {
        Picker("Mode", selection: Binding(
            get: { viewModel?.listMode ?? .nearby },
            set: { newMode in
                Task {
                    searchText = ""
                    await viewModel?.switchMode(
                        newMode,
                        lat: locationService.currentLocation?.coordinate.latitude,
                        lng: locationService.currentLocation?.coordinate.longitude,
                    )
                }
            },
        )) {
            Text("Nearby").tag(ListMode.nearby)
            Text("Favourites").tag(ListMode.favourites)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var emptyState: some View {
        if isNearbyMode {
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
            EmptyStateView(
                message: "Libraries you favourite will appear here.",
                title: "No Favourites Yet",
                icon: "heart",
            )
        }
    }

    private var libraryList: some View {
        List {
            if let viewModel {
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
        }
        .navigationDestination(for: Library.self) { library in
            LibraryDetailView(library: library)
        }
    }

    private var locationCTA: some View {
        ContentUnavailableView {
            Label("See Libraries Near You", systemImage: "location.circle")
        } description: {
            Text("Enable location to find book-sharing libraries closest to you.")
        } actions: {
            if locationService.authorizationStatus == .notDetermined {
                Button("Continue") {
                    locationService.startMonitoring()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
        .environment(AuthService(apiClient: APIClient(), keychainService: KeychainService()))
        .environment(\.apiClient, APIClient())
}
