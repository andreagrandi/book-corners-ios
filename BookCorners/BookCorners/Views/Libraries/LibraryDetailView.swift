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
    @State private var showReport = false
    @State private var showSubmitPhoto = false
    @State private var showMapPicker = false

    private var displayLibrary: Library {
        viewModel?.library ?? library
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let error = viewModel?.errorMessage {
                    ErrorView(message: error) {
                        Task { await viewModel?.refresh() }
                    }
                }

                heroPhoto

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayLibrary.displayName)
                        .font(.title)
                        .bold()

                    Text("\(displayLibrary.address), \(displayLibrary.city), \(displayLibrary.country)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !displayLibrary.description.isEmpty {
                        Text(displayLibrary.description)
                    }
                    if let websiteURL = displayLibrary.websiteURL {
                        Link(destination: websiteURL) {
                            Label(displayLibrary.website, systemImage: "globe")
                        }
                        .font(.subheadline)
                    }
                    if !displayLibrary.contact.isEmpty {
                        Label(displayLibrary.contact, systemImage: "envelope")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                miniMap
                metadataSection

                VStack(spacing: 12) {
                    Button {
                        let apps = DirectionsService.availableApps()
                        if apps.count > 1 {
                            showMapPicker = true
                        } else {
                            DirectionsService.openDirections(
                                to: libraryCoordinate,
                                name: displayLibrary.displayName,
                                using: .appleMaps,
                            )
                        }
                    } label: {
                        Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .confirmationDialog("Open directions in", isPresented: $showMapPicker) {
                        ForEach(DirectionsService.availableApps()) { app in
                            Button(app.rawValue) {
                                DirectionsService.openDirections(
                                    to: libraryCoordinate,
                                    name: displayLibrary.displayName,
                                    using: app,
                                )
                            }
                        }
                    }

                    if authService.isAuthenticated {
                        HStack(spacing: 12) {
                            Button {
                                showReport = true
                            } label: {
                                Label("Report", systemImage: "exclamationmark.triangle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .sheet(isPresented: $showReport) {
                                ReportView(librarySlug: displayLibrary.slug)
                            }

                            Button {
                                showSubmitPhoto = true
                            } label: {
                                Label("Add Photo", systemImage: "camera")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .sheet(isPresented: $showSubmitPhoto) {
                                SubmitPhotoView(librarySlug: displayLibrary.slug)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .overlay(alignment: .top) {
            if viewModel?.isLoading == true {
                ProgressView()
                    .padding(8)
                    .background(.ultraThinMaterial, in: .circle)
                    .padding(.top, 8)
            }
        }
        .navigationTitle(displayLibrary.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ShareLink(
                item: URL(string: "https://bookcorners.org/libraries/\(displayLibrary.slug)/")!,
                subject: Text(displayLibrary.displayName),
                message: Text("Check out this little library!"),
            )
        }
        .task {
            if viewModel == nil {
                viewModel = LibraryDetailViewModel(library: library, client: apiClient)
            }
            await viewModel?.refresh()
        }
    }

    private var libraryCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: displayLibrary.lat, longitude: displayLibrary.lng)
    }

    private var miniMap: some View {
        Map(initialPosition: .camera(MapCamera(
            centerCoordinate: libraryCoordinate,
            distance: 1000,
        )), interactionModes: []) {
            Marker(displayLibrary.name, systemImage: "book.fill", coordinate: libraryCoordinate)
        }
        .frame(height: 200)
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityLabel("Map showing library location")
        .accessibilityHint("Non-interactive preview")
    }

    @ViewBuilder
    private var heroPhoto: some View {
        if let photoURL = displayLibrary.fullPhotoUrl {
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
                        .accessibilityLabel("Photo of \(displayLibrary.displayName)")
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
        .accessibilityLabel("No photo available")
    }

    @ViewBuilder
    private var metadataSection: some View {
        let hasMetadata = !displayLibrary.wheelchairAccessible.isEmpty
            || displayLibrary.capacity != nil
            || displayLibrary.isIndoor != nil
            || displayLibrary.isLit != nil

        if hasMetadata {
            VStack(alignment: .leading, spacing: 8) {
                if !displayLibrary.wheelchairAccessible.isEmpty {
                    MetadataRow(icon: "figure.roll", label: "Wheelchair", value: displayLibrary.wheelchairAccessible)
                }
                if let capacity = displayLibrary.capacity {
                    MetadataRow(icon: "books.vertical", label: "Capacity", value: "\(capacity) books")
                }
                if let isIndoor = displayLibrary.isIndoor {
                    MetadataRow(icon: "building.2", label: "Location", value: isIndoor ? "Indoor" : "Outdoor")
                }
                if let isLit = displayLibrary.isLit {
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
