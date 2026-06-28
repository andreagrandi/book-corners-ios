//
//  PhotoModerationQueueView.swift
//  BookCorners
//

import SwiftUI

struct PhotoModerationQueueView: View {
    @Environment(\.apiClient) private var apiClient

    @State private var viewModel: ModerationPhotoQueueViewModel?
    @State private var photoPendingApproval: ModerationPhoto?
    @State private var photoPendingRejection: ModerationPhoto?

    private let statusFilters: [PhotoModerationStatusFilter] = [.pending, .all, .approved, .rejected]

    private var isShowingApproveConfirmation: Binding<Bool> {
        Binding {
            photoPendingApproval != nil
        } set: { isPresented in
            if !isPresented {
                photoPendingApproval = nil
            }
        }
    }

    private var isShowingRejectConfirmation: Binding<Bool> {
        Binding {
            photoPendingRejection != nil
        } set: { isPresented in
            if !isPresented {
                photoPendingRejection = nil
            }
        }
    }

    var body: some View {
        Group {
            if let viewModel {
                content(for: viewModel)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Submitted Photos")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = ModerationPhotoQueueViewModel(client: apiClient)
            }
            await viewModel?.loadInitialIfNeeded()
        }
        .alert("Approve Photo?", isPresented: isShowingApproveConfirmation) {
            Button("Approve") {
                approveSelectedPhoto()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will publish the photo on its library page.")
        }
        .alert("Reject Photo?", isPresented: isShowingRejectConfirmation) {
            Button("Reject", role: .destructive) {
                rejectSelectedPhoto()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will keep the photo hidden from the public library page.")
        }
    }

    private func content(for viewModel: ModerationPhotoQueueViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PhotoModerationQueueHeader(
                    summary: viewModel.summary,
                    visibleCount: viewModel.photos.count,
                )
                statusPicker(for: viewModel)
                actionErrorBanner(for: viewModel)
                queueState(for: viewModel)
            }
            .padding(16)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private func statusPicker(for viewModel: ModerationPhotoQueueViewModel) -> some View {
        Picker("Status", selection: Binding(
            get: { viewModel.selectedStatus },
            set: { newStatus in
                Task {
                    await viewModel.setStatusFilter(newStatus)
                }
            },
        )) {
            ForEach(statusFilters, id: \.self) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private func actionErrorBanner(for viewModel: ModerationPhotoQueueViewModel) -> some View {
        if let actionErrorMessage = viewModel.actionErrorMessage {
            PhotoModerationMessageBanner(
                message: actionErrorMessage,
                tint: .red,
                systemImage: "exclamationmark.triangle.fill",
            )
        }
    }

    @ViewBuilder
    private func queueState(for viewModel: ModerationPhotoQueueViewModel) -> some View {
        if viewModel.isLoading, viewModel.photos.isEmpty {
            ProgressView("Loading photos…")
                .frame(maxWidth: .infinity, minHeight: 240)
        } else if let errorMessage = viewModel.errorMessage, viewModel.photos.isEmpty {
            ErrorView(message: errorMessage) {
                Task {
                    await viewModel.refresh()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 240)
        } else if viewModel.photos.isEmpty {
            emptyState(for: viewModel)
                .frame(maxWidth: .infinity, minHeight: 240)
        } else {
            photoCards(for: viewModel)
        }
    }

    private func photoCards(for viewModel: ModerationPhotoQueueViewModel) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.photos) { photo in
                PhotoModerationCard(
                    photo: photo,
                    viewModel: viewModel,
                    onApprove: {
                        photoPendingApproval = photo
                    },
                    onReject: {
                        photoPendingRejection = photo
                    },
                )
                .onAppear {
                    Task {
                        await viewModel.loadMoreIfNeeded(currentPhoto: photo)
                    }
                }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.vertical, 12)
            }
        }
    }

    private func emptyState(for viewModel: ModerationPhotoQueueViewModel) -> some View {
        ContentUnavailableView {
            Label("No Photo Submissions", systemImage: "photo.on.rectangle")
        } description: {
            Text("No \(viewModel.selectedStatus.displayName.lowercased()) photo submissions to review.")
        }
    }

    private func approveSelectedPhoto() {
        guard let photo = photoPendingApproval else { return }
        photoPendingApproval = nil
        Task {
            await viewModel?.approve(photo)
        }
    }

    private func rejectSelectedPhoto() {
        guard let photo = photoPendingRejection else { return }
        photoPendingRejection = nil
        Task {
            await viewModel?.reject(photo)
        }
    }
}

private struct PhotoModerationQueueHeader: View {
    let summary: ModerationSummary?
    let visibleCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Submitted photos")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("Review community photos before they appear publicly.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label("\(summary?.pendingPhotosCount ?? visibleCount) pending", systemImage: "clock")
                Label("\(visibleCount) shown", systemImage: "list.bullet")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PhotoModerationMessageBanner: View {
    let message: String
    let tint: Color
    let systemImage: String

    var body: some View {
        Label(message, systemImage: systemImage)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(tint)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.12), in: .rect(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}

private struct PhotoModerationCard: View {
    let photo: ModerationPhoto
    let viewModel: ModerationPhotoQueueViewModel
    let onApprove: () -> Void
    let onReject: () -> Void

    private var isUpdating: Bool {
        viewModel.updatingPhotoID == photo.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink {
                PhotoModerationDetailView(photo: photo, viewModel: viewModel)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    PhotoModerationThumbnail(photo: photo, size: 72)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top) {
                            Text(photo.library.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 8)

                            PhotoModerationStatusChip(status: photo.status)
                        }

                        Text(captionText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        Text(submitterText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text(photo.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)

            if photo.status == .pending {
                HStack(spacing: 10) {
                    Button(action: onApprove) {
                        actionLabel(title: "Approve", systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isUpdating)

                    Button(role: .destructive, action: onReject) {
                        actionLabel(title: "Reject", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(viewModel.isUpdating)
                }
                .controlSize(.large)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var captionText: String {
        photo.caption.isEmpty ? "No caption provided" : photo.caption
    }

    private var submitterText: String {
        if let createdBy = photo.createdBy {
            return "Submitted by @\(createdBy.username)"
        }
        return "Submitter unavailable"
    }

    @ViewBuilder
    private func actionLabel(title: String, systemImage: String) -> some View {
        if isUpdating {
            ProgressView()
                .controlSize(.small)
        } else {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    NavigationStack {
        PhotoModerationQueueView()
    }
}
