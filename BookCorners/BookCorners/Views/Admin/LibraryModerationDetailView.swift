//
//  LibraryModerationDetailView.swift
//  BookCorners
//

import SwiftUI

struct LibraryModerationDetailView: View {
    let library: ModerationLibrary
    let viewModel: ModerationLibraryQueueViewModel

    @State private var showingApproveConfirmation = false
    @State private var showingRejectPrompt = false
    @State private var rejectionReason = ""

    private var currentLibrary: ModerationLibrary {
        if let detailLibrary = viewModel.detailLibrary, detailLibrary.slug == library.slug {
            return detailLibrary
        }
        return library
    }

    private var isUpdatingCurrentLibrary: Bool {
        viewModel.updatingLibrarySlug == currentLibrary.slug
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LibraryModerationHeroPhoto(library: currentLibrary)

                if viewModel.isLoadingDetail {
                    ProgressView("Refreshing details…")
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                if let detailErrorMessage = viewModel.detailErrorMessage {
                    LibraryModerationDetailBanner(
                        message: detailErrorMessage,
                        tint: .orange,
                        systemImage: "exclamationmark.triangle.fill",
                    ) {
                        Task {
                            await viewModel.loadDetail(slug: library.slug)
                        }
                    }
                }

                if let actionErrorMessage = viewModel.actionErrorMessage {
                    LibraryModerationDetailBanner(
                        message: actionErrorMessage,
                        tint: .red,
                        systemImage: "exclamationmark.triangle.fill",
                        action: nil,
                    )
                }

                LibraryModerationTitleSection(library: currentLibrary)

                LibraryModerationDetailSection(title: "Location") {
                    LibraryModerationDetailRow(title: "Address", value: displayValue(currentLibrary.address))
                    LibraryModerationDetailRow(title: "City", value: displayValue(currentLibrary.city))
                    LibraryModerationDetailRow(title: "Country", value: displayValue(currentLibrary.country))
                    LibraryModerationDetailRow(title: "Postal Code", value: displayValue(currentLibrary.postalCode))
                }

                LibraryModerationDetailSection(title: "Submission") {
                    LibraryModerationDetailRow(title: "Submitter", value: submitterText(for: currentLibrary))
                    LibraryModerationDetailRow(title: "Status", value: currentLibrary.status.displayName)
                    LibraryModerationDetailRow(
                        title: "Submitted",
                        value: currentLibrary.createdAt.formatted(date: .abbreviated, time: .shortened),
                    )
                    LibraryModerationDetailRow(title: "Source", value: displayValue(currentLibrary.source.capitalized))
                }

                if currentLibrary.status == .rejected, !currentLibrary.rejectionReason.isEmpty {
                    LibraryModerationDetailSection(title: "Rejection reason") {
                        Text(currentLibrary.rejectionReason)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                LibraryModerationActionSection(
                    library: currentLibrary,
                    isUpdating: isUpdatingCurrentLibrary,
                    onApprove: {
                        viewModel.clearActionError()
                        showingApproveConfirmation = true
                    },
                    onReject: {
                        viewModel.clearActionError()
                        rejectionReason = ""
                        showingRejectPrompt = true
                    },
                )
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(currentLibrary.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: library.slug) {
            viewModel.setDetailLibrary(library)
            await viewModel.loadDetail(slug: library.slug)
        }
        .alert("Approve Library?", isPresented: $showingApproveConfirmation) {
            Button("Approve") {
                approveCurrentLibrary()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will publish the book-sharing library and remove it from the pending queue.")
        }
        .alert("Reject Library", isPresented: $showingRejectPrompt) {
            TextField("Reason", text: $rejectionReason, axis: .vertical)
                .lineLimit(2 ... 4)
                .textInputAutocapitalization(.sentences)

            Button("Reject", role: .destructive) {
                rejectCurrentLibrary()
            }
            .disabled(rejectionReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Share a clear reason so the submitter understands what needs to change.")
        }
    }

    private func approveCurrentLibrary() {
        let library = currentLibrary
        Task {
            await viewModel.approve(library)
        }
    }

    private func rejectCurrentLibrary() {
        let library = currentLibrary
        let reason = rejectionReason
        rejectionReason = ""
        Task {
            await viewModel.reject(library, reason: reason)
        }
    }

    private func displayValue(_ value: String, fallback: String = "Not provided") -> String {
        value.isEmpty ? fallback : value
    }

    private func submitterText(for library: ModerationLibrary) -> String {
        if let createdBy = library.createdBy {
            return "@\(createdBy.username)"
        }
        return "Unavailable"
    }
}

private struct LibraryModerationHeroPhoto: View {
    let library: ModerationLibrary

    private var imageURL: URL? {
        library.fullPhotoUrl ?? library.fullThumbnailUrl
    }

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 260)
        .clipShape(.rect(cornerRadius: 18, style: .continuous))
        .accessibilityLabel("Library photo")
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.gray.opacity(0.12))

            Image(systemName: "books.vertical")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
}

private struct LibraryModerationTitleSection: View {
    let library: ModerationLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(library.displayName)
                        .font(.title.bold())
                        .foregroundStyle(.primary)

                    Text("\(library.city), \(library.country)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                ModerationStatusChip(status: library.status)
            }

            if !library.description.isEmpty {
                Text(library.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct LibraryModerationDetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1.4)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct LibraryModerationDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer(minLength: 16)

            Text(value)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .font(.body)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

private struct LibraryModerationActionSection: View {
    let library: ModerationLibrary
    let isUpdating: Bool
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIONS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1.4)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                if library.status == .pending {
                    Button(action: onApprove) {
                        actionLabel(title: "Approve Library", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isUpdating)

                    Button(role: .destructive, action: onReject) {
                        actionLabel(title: "Reject Library", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.red)
                    .disabled(isUpdating)
                } else {
                    Label("No pending action", systemImage: "checkmark.seal")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(library.status.tint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private func actionLabel(title: String, systemImage: String) -> some View {
        if isUpdating {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct LibraryModerationDetailBanner: View {
    let message: String
    let tint: Color
    let systemImage: String
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(message, systemImage: systemImage)
                .font(.footnote.weight(.semibold))

            if let action {
                Button("Retry", action: action)
                    .font(.footnote.weight(.semibold))
            }
        }
        .foregroundStyle(tint)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: .rect(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        LibraryModerationDetailView(
            library: SampleData.moderationLibrary,
            viewModel: ModerationLibraryQueueViewModel(client: MockAPIClient()),
        )
    }
}
