//
//  MapTabView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 13/03/26.
//

import MapKit
import SwiftUI

private let kmPerDegreeLatitude = 111.0
struct MapTabView: View {
    @Environment(\.apiClient) private var apiClient
    @State private var viewModel: MapViewModel?
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var navigationPath = NavigationPath()

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
                            }
                        }
                    }
                }
            }
            .navigationTitle("Map")
            .mapControls { MapUserLocationButton(); MapCompass(); MapScaleView() }
            .mapStyle(.standard(elevation: .realistic))
            .onMapCameraChange(frequency: .onEnd) { context in
                guard let viewModel else { return }
                let center = context.camera.centerCoordinate
                let radiusKm = Int(context.region.span.latitudeDelta * kmPerDegreeLatitude / 2)
                viewModel.loadLibraries(lat: center.latitude, lng: center.longitude, radiusKm: max(radiusKm, 1))
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
            .navigationDestination(for: Library.self) { library in
                LibraryDetailView(library: library)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = MapViewModel(client: apiClient)
            }
        }
    }
}

#Preview {
    MapTabView()
}
