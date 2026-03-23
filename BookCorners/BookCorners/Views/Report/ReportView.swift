//
//  ReportView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 23/03/26.
//

import SwiftUI

struct ReportView: View {
    @Environment(\.apiClient) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let librarySlug: String

    @State private var viewModel: ReportViewModel?

    var body: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    Picker("Reason", selection: Binding(
                        get: { viewModel?.reason ?? .damaged },
                        set: { viewModel?.reason = $0 },
                    )) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            Text(reason.displayName).tag(reason)
                        }
                    }
                }

                Section("Details (optional)") {
                    TextField("Describe the issue", text: Binding(
                        get: { viewModel?.details ?? "" },
                        set: { viewModel?.details = $0 },
                    ), axis: .vertical)
                        .lineLimit(3 ... 6)
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
                            Text("Submit Report")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(viewModel?.isSubmitting ?? false)
                }
            }
            .navigationTitle("Report Issue")
            .toolbar { Button("Cancel") { dismiss() } }
        }
        .task {
            if viewModel == nil {
                viewModel = ReportViewModel(apiClient: apiClient, librarySlug: librarySlug)
            }
        }
        .onChange(of: viewModel?.didSubmitSuccessfully) {
            if viewModel?.didSubmitSuccessfully == true {
                dismiss()
            }
        }
    }
}

#Preview {
    ReportView(librarySlug: "test")
}
