//
//  SubmitPhotoView.swift
//  BookCorners
//

import PhotosUI
import SwiftUI

struct SubmitPhotoView: View {
    @Environment(\.apiClient) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let librarySlug: String

    @State private var viewModel: SubmitPhotoViewModel?
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    PhotosPicker(
                        selection: Binding(
                            get: { viewModel?.selectedPhotoItem },
                            set: { viewModel?.selectedPhotoItem = $0 },
                        ),
                        matching: .images,
                    ) {
                        if let thumbnail = viewModel?.photoThumbnail {
                            thumbnail
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                                .clipped()
                                .clipShape(.rect(cornerRadius: 8))
                        } else {
                            Label("Select Photo", systemImage: "photo")
                                .frame(maxWidth: .infinity, minHeight: 100)
                        }
                    }
                    .accessibilityLabel(viewModel?.photoData != nil ? "Change photo" : "Select photo")
                    .accessibilityHint("Opens photo picker")
                }

                Section("Caption (optional)") {
                    TextField("Describe the photo", text: Binding(
                        get: { viewModel?.caption ?? "" },
                        set: { viewModel?.caption = $0 },
                    ))
                }

                Section {
                    if let error = viewModel?.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await viewModel?.submit() }
                    } label: {
                        if viewModel?.isSubmitting ?? false {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit Photo")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!(viewModel?.isValid ?? false) || (viewModel?.isSubmitting ?? false))
                }
            }
            .navigationTitle("Add Photo")
            .toolbar { Button("Cancel") { dismiss() } }
        }
        .task {
            if viewModel == nil {
                viewModel = SubmitPhotoViewModel(apiClient: apiClient, librarySlug: librarySlug)
            }
        }
        .onChange(of: viewModel?.selectedPhotoItem) {
            Task { await viewModel?.loadPhoto() }
        }
        .onChange(of: viewModel?.didSubmitSuccessfully) {
            if viewModel?.didSubmitSuccessfully == true {
                showSuccessAlert = true
            }
        }
        .sensoryFeedback(.success, trigger: viewModel?.didSubmitSuccessfully) { _, newValue in
            newValue == true
        }
        .sensoryFeedback(.error, trigger: viewModel?.errorMessage) { _, newValue in
            newValue != nil
        }
        .alert("Photo Submitted", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your photo has been submitted and will appear after review.")
        }
    }
}

#Preview {
    SubmitPhotoView(librarySlug: "test")
}
