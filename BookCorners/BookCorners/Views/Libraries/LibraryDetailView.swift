//
//  LibraryDetailView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 20/03/26.
//

import MapKit
import SwiftUI

struct LibraryDetailView: View {
    let library: Library
    @Environment(\.apiClient) private var apiClient
    @State private var viewModel: LibraryDetailViewModel?
    @Environment(AuthService.self) private var authService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroPhoto

                VStack(alignment: .leading, spacing: 4) {
                    Text(library.displayName)
                        .font(.title)
                        .bold()

                    Text("\(library.address), \(library.city), \(library.country)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !library.description.isEmpty {
                        Text(library.description)
                    }
                    if let websiteURL = library.websiteURL {
                        Link(destination: websiteURL) {
                            Label(library.website, systemImage: "globe")
                        }
                        .font(.subheadline)
                    }
                    if !library.contact.isEmpty {
                        Label(library.contact, systemImage: "envelope")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                miniMap
                metadataSection

                VStack {
                    Button("Get Directions") {
                        let placemark = MKPlacemark(coordinate: libraryCoordinate)
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.name = library.name
                        mapItem.openInMaps(launchOptions: [
                            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking,
                        ])
                    }
                    .buttonStyle(.borderedProminent)

                    if authService.isAuthenticated {
                        Button("Report Issue") {}
                            .buttonStyle(.bordered)

                        Button("Add Photo") {}
                            .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(library.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = LibraryDetailViewModel(library: library, client: apiClient)
            }
            await viewModel?.refresh()
        }
    }

    private var libraryCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: library.lat, longitude: library.lng)
    }

    private var miniMap: some View {
        Map(initialPosition: .camera(MapCamera(
            centerCoordinate: libraryCoordinate,
            distance: 1000,
        )), interactionModes: []) {
            Marker(library.name, systemImage: "book.fill", coordinate: libraryCoordinate)
        }
        .frame(height: 200)
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var heroPhoto: some View {
        if let photoURL = library.fullPhotoUrl {
            AsyncImage(url: photoURL) { phase in
                switch phase {
                case .empty:
                    photoPlaceholder
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 250)
                        .clipped()
                case .failure:
                    photoPlaceholder
                @unknown default:
                    photoPlaceholder
                }
            }
        } else {
            photoPlaceholder
        }
    }

    private var photoPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(.gray.opacity(0.12))

            Image(systemName: "books.vertical")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
    }

    @ViewBuilder
    private var metadataSection: some View {
        let hasMetadata = !library.wheelchairAccessible.isEmpty
            || library.capacity != nil
            || library.isIndoor != nil
            || library.isLit != nil

        if hasMetadata {
            VStack(alignment: .leading, spacing: 8) {
                if !library.wheelchairAccessible.isEmpty {
                    MetadataRow(icon: "figure.roll", label: "Wheelchair", value: library.wheelchairAccessible)
                }
                if let capacity = library.capacity {
                    MetadataRow(icon: "books.vertical", label: "Capacity", value: "\(capacity) books")
                }
                if let isIndoor = library.isIndoor {
                    MetadataRow(icon: "building.2", label: "Location", value: isIndoor ? "Indoor" : "Outdoor")
                }
                if let isLit = library.isLit {
                    MetadataRow(icon: "lightbulb", label: "Lit at night", value: isLit ? "Yes" : "No")
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct MetadataRow: View {
    let icon: String // SF Symbol name
    let label: String
    let value: String

    var body: some View {
        Label {
            HStack {
                Text(label)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
        }
    }
}

#Preview {
    LibraryDetailView(library: SampleData.library)
        .environment(AuthService(apiClient: APIClient(), keychainService: KeychainService()))
        .environment(\.apiClient, APIClient())
}
