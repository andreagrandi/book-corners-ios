//
//  SubmitLibraryView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 13/03/26.
//

import MapKit
import PhotosUI
import SwiftUI

struct SubmitLibraryView: View {
    var onCancel: (() -> Void)?

    @Environment(\.apiClient) private var apiClient
    @State private var viewModel: SubmitLibraryViewModel?
    @State private var pinCameraPosition: MapCameraPosition = .automatic
    @State private var showCamera = false
    @State private var showPhotoPicker = false

    var body: some View {
        NavigationStack {
            if let viewModel {
                formContent(viewModel)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = SubmitLibraryViewModel(client: apiClient)
            }
        }
    }

    private func formContent(_ viewModel: SubmitLibraryViewModel) -> some View {
        Form {
            // MARK: - Photo

            Section("Photo") {
                if let thumbnail = viewModel.photoThumbnail {
                    thumbnail
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Menu {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }

                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Label(
                        viewModel.photoData != nil ? "Change Photo" : "Select Photo",
                        systemImage: "photo",
                    )
                }
                .accessibilityLabel(viewModel.photoData != nil ? "Change photo" : "Select photo")
                .accessibilityHint("Opens photo or camera options")
            }

            // MARK: - Location

            Section("Location") {
                TextField("Address", text: Binding(
                    get: { viewModel.address },
                    set: {
                        viewModel.address = $0
                        viewModel.searchAddress($0)
                    },
                ))
                .textInputAutocapitalization(.words)

                if !viewModel.addressSuggestions.isEmpty {
                    ForEach(viewModel.addressSuggestions) { suggestion in
                        Button {
                            viewModel.selectSuggestion(suggestion)
                        } label: {
                            Text(suggestion.displayText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                TextField("City", text: Binding(
                    get: { viewModel.city },
                    set: { viewModel.city = $0 },
                ))
                .textInputAutocapitalization(.words)

                TextField("Postal Code", text: Binding(
                    get: { viewModel.postalCode },
                    set: { viewModel.postalCode = $0 },
                ))

                NavigationLink {
                    CountryPickerView(selectedCountryCode: Binding(
                        get: { viewModel.country },
                        set: { viewModel.country = $0 },
                    ))
                } label: {
                    HStack {
                        Text("Country")
                        Spacer()
                        Text(viewModel.country.isEmpty
                            ? "Select"
                            : countryName(for: viewModel.country))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Map pin

            if viewModel.hasCoordinates, let lat = viewModel.latitude, let lng = viewModel.longitude {
                Section("Pin Location — drag map to adjust") {
                    ZStack {
                        Map(position: $pinCameraPosition)
                            .mapStyle(.standard)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onMapCameraChange(frequency: .onEnd) { context in
                                viewModel.latitude = context.camera.centerCoordinate.latitude
                                viewModel.longitude = context.camera.centerCoordinate.longitude
                            }

                        Image(systemName: "mappin")
                            .font(.title)
                            .foregroundStyle(.red)
                            .offset(y: -12)
                    }
                    .onAppear {
                        pinCameraPosition = .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005),
                        ))
                    }

                    Text("\(lat, specifier: "%.5f"), \(lng, specifier: "%.5f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Details

            Section("Details") {
                TextField("Name (optional)", text: Binding(
                    get: { viewModel.name },
                    set: { viewModel.name = $0 },
                ))
                .textInputAutocapitalization(.words)

                TextField("Description (optional)", text: Binding(
                    get: { viewModel.libraryDescription },
                    set: { viewModel.libraryDescription = $0 },
                ), axis: .vertical)
                    .lineLimit(3 ... 6)
            }

            // MARK: - Accessibility

            Section("Accessibility") {
                Picker("Wheelchair", selection: Binding(
                    get: { viewModel.wheelchairAccessible },
                    set: { viewModel.wheelchairAccessible = $0 },
                )) {
                    Text("Unknown").tag("")
                    Text("Yes").tag("yes")
                    Text("No").tag("no")
                    Text("Limited").tag("limited")
                }

                Toggle("Indoor", isOn: Binding(
                    get: { viewModel.isIndoor ?? false },
                    set: { viewModel.isIndoor = $0 },
                ))

                Toggle("Lit at night", isOn: Binding(
                    get: { viewModel.isLit ?? false },
                    set: { viewModel.isLit = $0 },
                ))
            }

            // MARK: - Contact

            Section("Contact (optional)") {
                TextField("Website", text: Binding(
                    get: { viewModel.website },
                    set: { viewModel.website = $0 },
                ))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                TextField("Contact", text: Binding(
                    get: { viewModel.contact },
                    set: { viewModel.contact = $0 },
                ))

                TextField("Operator", text: Binding(
                    get: { viewModel.operatorName },
                    set: { viewModel.operatorName = $0 },
                ))

                TextField("Brand", text: Binding(
                    get: { viewModel.brand },
                    set: { viewModel.brand = $0 },
                ))
            }

            // MARK: - Submit

            Section {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await viewModel.submit() }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Submit Library")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.isValid || viewModel.isSubmitting)
            }
        }
        .navigationTitle("Submit Library")
        .toolbar {
            Button("Cancel") {
                viewModel.reset()
                onCancel?()
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                viewModel.setPhoto(image: image)
            }
            .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: Binding(
                get: { viewModel.selectedPhotoItem },
                set: { viewModel.selectedPhotoItem = $0 },
            ),
            matching: .images,
        )
        .onChange(of: viewModel.selectedPhotoItem) {
            Task { await viewModel.loadPhoto() }
        }
        .alert("Library Submitted!", isPresented: Binding(
            get: { viewModel.submittedLibrary != nil },
            set: { if !$0 { viewModel.reset(); onCancel?() } },
        )) {
            Button("OK") { viewModel.reset(); onCancel?() }
        } message: {
            Text("Your library has been submitted and will appear after review.")
        }
        .sensoryFeedback(.success, trigger: viewModel.submittedLibrary) { _, newValue in
            newValue != nil
        }
        .sensoryFeedback(.error, trigger: viewModel.errorMessage) { _, newValue in
            newValue != nil
        }
    }
}

private func countryName(for code: String) -> String {
    Locale.current.localizedString(forRegionCode: code) ?? code
}

#Preview {
    SubmitLibraryView()
}
