//
//  MapTabView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 13/03/26.
//

import MapKit
import SwiftUI

private let kmPerDegreeLatitude = 111.0
private let maxRadiusKm = 100

struct MapTabView: View {
    @Environment(\.apiClient) private var apiClient
    @Environment(LocationService.self) private var locationService
    @State private var viewModel: MapViewModel?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var navigationPath = NavigationPath()
    @State private var filterState = FilterState()
    @State private var showFilters = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Map(position: $cameraPosition) {
                if let viewModel {
                    ForEach(viewModel.libraries) { library in
                        Annotation(library.displayName,
                                   coordinate: CLLocationCoordinate2D(
                                       latitude: library.lat, longitude: library.lng,
                                   )) {
                            Button {
                                viewModel.selectedLibrary = library
                            } label: {
                                Image(systemName: "book.fill")
                                    .font(.title3)
                                    .padding(8)
                                    .foregroundStyle(.white)
                                    .background(.red)
                                    .clipShape(Circle())
                                    .accessibilityLabel("Library: \(library.displayName)")
                                    .accessibilityHint("Shows library details")
                            }
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: viewModel?.selectedLibrary) { _, newValue in
                newValue != nil
            }
            .toolbar {
                Button {
                    showFilters = true
                } label: {
                    Label("Filter", systemImage: filterState.isActive
                        ? "line.3.horizontal.decrease.circle.fill"
                        : "line.3.horizontal.decrease.circle")
                }
            }
            .overlay(alignment: .top) {
                if let error = viewModel?.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .mapControls { MapUserLocationButton(); MapCompass(); MapScaleView() }
            .mapStyle(.standard(elevation: .realistic))
            .onMapCameraChange(frequency: .onEnd) { context in
                guard let viewModel else { return }
                let center = context.camera.centerCoordinate
                let radiusKm = min(Int(context.region.span.latitudeDelta * kmPerDegreeLatitude / 2), maxRadiusKm)
                viewModel.loadLibraries(lat: center.latitude, lng: center.longitude, radiusKm: max(radiusKm, 1), filters: filterState)
            }
            .sheet(item: Binding(
                get: { viewModel?.selectedLibrary },
                set: { viewModel?.selectedLibrary = $0 },
            )) { library in
                LibraryCardView(library: library, distance: nil)
                    .presentationDetents([.fraction(0.25)])
                Button("View Details") {
                    viewModel?.selectedLibrary = nil
                    navigationPath.append(library)
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheetView(filterState: $filterState) {
                    guard let viewModel else { return }
                    Task {
                        await viewModel.applyFilters(filterState)
                        if filterState.isActive, let region = viewModel.regionForResults() {
                            cameraPosition = .region(region)
                        }
                    }
                }
            }
            .navigationDestination(for: Library.self) { library in
                LibraryDetailView(library: library)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = MapViewModel(client: apiClient)
            }
        }
        .onChange(of: locationService.currentLocation) { _, location in
            guard let viewModel, viewModel.libraries.isEmpty, let location else { return }
            viewModel.loadLibraries(
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude,
                radiusKm: maxRadiusKm,
                filters: filterState,
            )
        }
        .onChange(of: cameraPosition.followsUserLocation) { _, followsUser in
            guard followsUser, let viewModel, let location = locationService.currentLocation else { return }
            filterState = FilterState()
            viewModel.loadLibraries(
                lat: location.coordinate.latitude,
                lng: location.coordinate.longitude,
                radiusKm: maxRadiusKm,
            )
        }
    }
}

#Preview {
    MapTabView()
}
