//
//  PhotoModerationDetailView.swift
//  BookCorners
//

import SwiftUI

struct PhotoModerationDetailView: View {
    let photo: ModerationPhoto
    let viewModel: ModerationPhotoQueueViewModel

    @State private var showingApproveConfirmation = false
    @State private var showingRejectConfirmation = false

    private var currentPhoto: ModerationPhoto {
        if let detailPhoto = viewModel.detailPhoto, detailPhoto.id == photo.id {
            return detailPhoto
        }
        return photo
    }

    private var isUpdatingCurrentPhoto: Bool {
        viewModel.updatingPhotoID == currentPhoto.id
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PhotoModerationHeroPhoto(photo: currentPhoto)

                if let actionErrorMessage = viewModel.actionErrorMessage {
                    PhotoModerationDetailBanner(
                        message: actionErrorMessage,
                        tint: .red,
                        systemImage: "exclamationmark.triangle.fill",
                    )
                }

                PhotoModerationTitleSection(photo: currentPhoto)

                PhotoModerationDetailSection(title: "Library") {
                    PhotoModerationDetailRow(title: "Name", value: currentPhoto.library.displayName)
                    PhotoModerationDetailRow(title: "City", value: displayValue(currentPhoto.library.city))
                    PhotoModerationDetailRow(title: "Country", value: displayValue(currentPhoto.library.country))
                    PhotoModerationDetailRow(title: "Address", value: displayValue(currentPhoto.library.address))
                }

                PhotoModerationDetailSection(title: "Submission") {
                    PhotoModerationDetailRow(title: "Submitter", value: submitterText(for: currentPhoto))
                    PhotoModerationDetailRow(title: "Status", value: currentPhoto.status.displayName)
                    PhotoModerationDetailRow(
                        title: "Submitted",
                        value: currentPhoto.createdAt.formatted(date: .abbreviated, time: .shortened),
                    )
                    PhotoModerationDetailRow(title: "Photo ID", value: currentPhoto.id.formatted())
                }

                PhotoModerationActionSection(
                    photo: currentPhoto,
                    isUpdating: isUpdatingCurrentPhoto,
                    onApprove: {
                        viewModel.clearActionError()
                        showingApproveConfirmation = true
                    },
                    onReject: {
                        viewModel.clearActionError()
                        showingRejectConfirmation = true
                    },
                )
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(currentPhoto.library.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: photo.id) {
            viewModel.setDetailPhoto(photo)
        }
        .alert("Approve Photo?", isPresented: $showingApproveConfirmation) {
            Button("Approve") {
                approveCurrentPhoto()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will publish the photo on its library page.")
        }
        .alert("Reject Photo?", isPresented: $showingRejectConfirmation) {
            Button("Reject", role: .destructive) {
                rejectCurrentPhoto()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will keep the photo hidden from the public library page.")
        }
    }

    private func approveCurrentPhoto() {
        let photo = currentPhoto
        Task {
            await viewModel.approve(photo)
        }
    }

    private func rejectCurrentPhoto() {
        let photo = currentPhoto
        Task {
            await viewModel.reject(photo)
        }
    }

    private func displayValue(_ value: String, fallback: String = "Not provided") -> String {
        value.isEmpty ? fallback : value
    }

    private func submitterText(for photo: ModerationPhoto) -> String {
        if let createdBy = photo.createdBy {
            return "@\(createdBy.username)"
        }
        return "Unavailable"
    }
}

private struct PhotoModerationHeroPhoto: View {
    let photo: ModerationPhoto

    private var imageURL: URL? {
        photo.fullPhotoUrl ?? photo.fullThumbnailUrl
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
        .frame(maxWidth: .infinity, minHeight: 260, maxHeight: 320)
        .clipShape(.rect(cornerRadius: 18, style: .continuous))
        .accessibilityLabel("Submitted photo")
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.gray.opacity(0.12))

            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PhotoModerationTitleSection: View {
    let photo: ModerationPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(photo.library.displayName)
                        .font(.title.bold())
                        .foregroundStyle(.primary)

                    Text("\(photo.library.city), \(photo.library.country)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                PhotoModerationStatusChip(status: photo.status)
            }

            Text(captionText)
                .font(.body)
                .foregroundStyle(photo.caption.isEmpty ? .secondary : .primary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var captionText: String {
        photo.caption.isEmpty ? "No caption provided" : photo.caption
    }
}

private struct PhotoModerationDetailSection<Content: View>: View {
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

private struct PhotoModerationDetailRow: View {
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

private struct PhotoModerationActionSection: View {
    let photo: ModerationPhoto
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
                if photo.status == .pending {
                    Button(action: onApprove) {
                        actionLabel(title: "Approve Photo", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isUpdating)

                    Button(role: .destructive, action: onReject) {
                        actionLabel(title: "Reject Photo", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.red)
                    .disabled(isUpdating)
                } else {
                    Label("No pending action", systemImage: "checkmark.seal")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(photo.status.tint)
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

private struct PhotoModerationDetailBanner: View {
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

#Preview {
    NavigationStack {
        PhotoModerationDetailView(
            photo: SampleData.moderationPhoto,
            viewModel: ModerationPhotoQueueViewModel(client: MockAPIClient()),
        )
    }
}
