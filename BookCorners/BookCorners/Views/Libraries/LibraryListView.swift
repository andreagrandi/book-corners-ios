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

    var body: some View {
        NavigationStack {
            if let viewModel {
                List {
                    ForEach(viewModel.libraries) { library in
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

                    if viewModel.isLoadingMore {
                        ProgressView()
                    }
                }
            }
        }
        .navigationTitle("Nearby")
        .task {
            if viewModel == nil {
                viewModel = LibraryListViewModel(client: apiClient)
            }
            await viewModel?.loadLibraries(
                lat: locationService.currentLocation?.coordinate.latitude,
                lng: locationService.currentLocation?.coordinate.longitude,
            )
        }
        .refreshable {
            await viewModel?.loadLibraries(
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
