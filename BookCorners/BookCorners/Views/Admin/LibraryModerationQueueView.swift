//
//  LibraryModerationQueueView.swift
//  BookCorners
//

import SwiftUI

struct LibraryModerationQueueView: View {
    @Environment(\.apiClient) private var apiClient

    @State private var viewModel: ModerationLibraryQueueViewModel?
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var libraryPendingApproval: ModerationLibrary?
    @State private var libraryPendingRejection: ModerationLibrary?
    @State private var rejectionReason = ""

    private let statusFilters: [ModerationStatusFilter] = [.pending, .all, .approved, .rejected]

    private var isShowingApproveConfirmation: Binding<Bool> {
        Binding {
            libraryPendingApproval != nil
        } set: { isPresented in
            if !isPresented {
                libraryPendingApproval = nil
            }
        }
    }

    private var isShowingRejectPrompt: Binding<Bool> {
        Binding {
            libraryPendingRejection != nil
        } set: { isPresented in
            if !isPresented {
                libraryPendingRejection = nil
                rejectionReason = ""
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
        .navigationTitle("Library Approvals")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = ModerationLibraryQueueViewModel(client: apiClient)
            }
            await viewModel?.loadInitialIfNeeded()
        }
        .searchable(text: $searchText, prompt: "Search library submissions")
        .onChange(of: searchText) { _, newValue in
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                await viewModel?.performSearch(query: newValue)
            }
        }
        .onSubmit(of: .search) {
            searchTask?.cancel()
            Task {
                await viewModel?.performSearch(query: searchText)
            }
        }
        .alert("Approve Library?", isPresented: isShowingApproveConfirmation) {
            Button("Approve") {
                approveSelectedLibrary()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will publish the book-sharing library and remove it from the pending queue.")
        }
        .alert("Reject Library", isPresented: isShowingRejectPrompt) {
            TextField("Reason", text: $rejectionReason, axis: .vertical)
                .lineLimit(2 ... 4)
                .textInputAutocapitalization(.sentences)

            Button("Reject", role: .destructive) {
                rejectSelectedLibrary()
            }
            .disabled(rejectionReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Share a clear reason so the submitter understands what needs to change.")
        }
    }

    private func content(for viewModel: ModerationLibraryQueueViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LibraryModerationQueueHeader(
                    summary: viewModel.summary,
                    visibleCount: viewModel.libraries.count,
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

    private func statusPicker(for viewModel: ModerationLibraryQueueViewModel) -> some View {
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
    private func actionErrorBanner(for viewModel: ModerationLibraryQueueViewModel) -> some View {
        if let actionErrorMessage = viewModel.actionErrorMessage {
            LibraryModerationMessageBanner(
                message: actionErrorMessage,
                tint: .red,
                systemImage: "exclamationmark.triangle.fill",
            )
        }
    }

    @ViewBuilder
    private func queueState(for viewModel: ModerationLibraryQueueViewModel) -> some View {
        if viewModel.isLoading, viewModel.libraries.isEmpty {
            ProgressView("Loading submissions…")
                .frame(maxWidth: .infinity, minHeight: 240)
        } else if let errorMessage = viewModel.errorMessage, viewModel.libraries.isEmpty {
            ErrorView(message: errorMessage) {
                Task {
                    await viewModel.refresh()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 240)
        } else if viewModel.libraries.isEmpty {
            emptyState(for: viewModel)
                .frame(maxWidth: .infinity, minHeight: 240)
        } else {
            libraryCards(for: viewModel)
        }
    }

    private func libraryCards(for viewModel: ModerationLibraryQueueViewModel) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.libraries) { library in
                LibraryModerationCard(
                    library: library,
                    viewModel: viewModel,
                    onApprove: {
                        libraryPendingApproval = library
                    },
                    onReject: {
                        rejectionReason = ""
                        libraryPendingRejection = library
                    },
                )
                .onAppear {
                    Task {
                        await viewModel.loadMoreIfNeeded(currentLibrary: library)
                    }
                }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.vertical, 12)
            }
        }
    }

    private func emptyState(for viewModel: ModerationLibraryQueueViewModel) -> some View {
        let message = if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            "No \(viewModel.selectedStatus.displayName.lowercased()) library submissions to review."
        } else {
            "No library submissions match \"\(searchText)\"."
        }

        return ContentUnavailableView {
            Label("No Library Submissions", systemImage: "tray")
        } description: {
            Text(message)
        }
    }

    private func approveSelectedLibrary() {
        guard let library = libraryPendingApproval else { return }
        libraryPendingApproval = nil
        Task {
            await viewModel?.approve(library)
        }
    }

    private func rejectSelectedLibrary() {
        guard let library = libraryPendingRejection else { return }
        let reason = rejectionReason
        libraryPendingRejection = nil
        rejectionReason = ""
        Task {
            await viewModel?.reject(library, reason: reason)
        }
    }
}

private struct LibraryModerationQueueHeader: View {
    let summary: ModerationSummary?
    let visibleCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Submitted libraries")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("Review pending book-sharing libraries before they appear publicly.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label("\(summary?.pendingLibrariesCount ?? visibleCount) pending", systemImage: "clock")
                Label("\(visibleCount) shown", systemImage: "list.bullet")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct LibraryModerationMessageBanner: View {
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

private struct LibraryModerationCard: View {
    let library: ModerationLibrary
    let viewModel: ModerationLibraryQueueViewModel
    let onApprove: () -> Void
    let onReject: () -> Void

    private var isUpdating: Bool {
        viewModel.updatingLibrarySlug == library.slug
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink {
                LibraryModerationDetailView(library: library, viewModel: viewModel)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    LibraryModerationThumbnail(library: library, size: 64)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top) {
                            Text(library.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 8)

                            ModerationStatusChip(status: library.status)
                        }

                        Text(submitterText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text("\(library.city), \(library.country)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)

            if library.status == .pending {
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

    private var submitterText: String {
        if let createdBy = library.createdBy {
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
        LibraryModerationQueueView()
    }
}
