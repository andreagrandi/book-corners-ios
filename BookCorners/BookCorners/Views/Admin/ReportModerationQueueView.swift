//
//  ReportModerationQueueView.swift
//  BookCorners
//

import SwiftUI

struct ReportModerationQueueView: View {
    @Environment(\.apiClient) private var apiClient

    @State private var viewModel: ModerationReportQueueViewModel?
    @State private var reportPendingResolution: ModerationReport?
    @State private var reportPendingDismissal: ModerationReport?

    private let statusFilters: [ReportModerationStatusFilter] = [.open, .all, .resolved, .dismissed]
    private let reasonFilters: [ReportModerationReasonFilter] = [
        .all,
        .damaged,
        .missing,
        .incorrectInfo,
        .inappropriate,
        .other,
    ]

    private var isShowingResolveConfirmation: Binding<Bool> {
        Binding {
            reportPendingResolution != nil
        } set: { isPresented in
            if !isPresented {
                reportPendingResolution = nil
            }
        }
    }

    private var isShowingDismissConfirmation: Binding<Bool> {
        Binding {
            reportPendingDismissal != nil
        } set: { isPresented in
            if !isPresented {
                reportPendingDismissal = nil
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
        .navigationTitle("User Reports")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = ModerationReportQueueViewModel(client: apiClient)
            }
            await viewModel?.loadInitialIfNeeded()
        }
        .alert("Resolve Report?", isPresented: isShowingResolveConfirmation) {
            Button("Resolve") {
                resolveSelectedReport()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mark this report as handled once the library issue has been reviewed.")
        }
        .alert("Dismiss Report?", isPresented: isShowingDismissConfirmation) {
            Button("Dismiss", role: .destructive) {
                dismissSelectedReport()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Dismiss this report if no moderation action is needed.")
        }
    }

    private func content(for viewModel: ModerationReportQueueViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ReportModerationQueueHeader(
                    summary: viewModel.summary,
                    visibleCount: viewModel.reports.count,
                )
                statusPicker(for: viewModel)
                reasonPicker(for: viewModel)
                actionErrorBanner(for: viewModel)
                queueState(for: viewModel)
            }
            .padding(16)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private func statusPicker(for viewModel: ModerationReportQueueViewModel) -> some View {
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

    private func reasonPicker(for viewModel: ModerationReportQueueViewModel) -> some View {
        HStack(spacing: 12) {
            Label("Reason", systemImage: "line.3.horizontal.decrease.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Picker("Reason", selection: Binding(
                get: { viewModel.selectedReason },
                set: { newReason in
                    Task {
                        await viewModel.setReasonFilter(newReason)
                    }
                },
            )) {
                ForEach(reasonFilters, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reason filter, \(viewModel.selectedReason.displayName)")
    }

    @ViewBuilder
    private func actionErrorBanner(for viewModel: ModerationReportQueueViewModel) -> some View {
        if let actionErrorMessage = viewModel.actionErrorMessage {
            ReportModerationMessageBanner(
                message: actionErrorMessage,
                tint: .red,
                systemImage: "exclamationmark.triangle.fill",
            )
        }
    }

    @ViewBuilder
    private func queueState(for viewModel: ModerationReportQueueViewModel) -> some View {
        if viewModel.isLoading, viewModel.reports.isEmpty {
            ProgressView("Loading reports…")
                .frame(maxWidth: .infinity, minHeight: 240)
        } else if let errorMessage = viewModel.errorMessage, viewModel.reports.isEmpty {
            ErrorView(message: errorMessage) {
                Task {
                    await viewModel.refresh()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 240)
        } else if viewModel.reports.isEmpty {
            emptyState(for: viewModel)
                .frame(maxWidth: .infinity, minHeight: 240)
        } else {
            reportCards(for: viewModel)
        }
    }

    private func reportCards(for viewModel: ModerationReportQueueViewModel) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.reports) { report in
                ReportModerationCard(
                    report: report,
                    viewModel: viewModel,
                    onResolve: {
                        reportPendingResolution = report
                    },
                    onDismiss: {
                        reportPendingDismissal = report
                    },
                )
                .onAppear {
                    Task {
                        await viewModel.loadMoreIfNeeded(currentReport: report)
                    }
                }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.vertical, 12)
            }
        }
    }

    private func emptyState(for viewModel: ModerationReportQueueViewModel) -> some View {
        ContentUnavailableView {
            Label("No User Reports", systemImage: "flag")
        } description: {
            Text(emptyStateMessage(for: viewModel))
        }
    }

    private func emptyStateMessage(for viewModel: ModerationReportQueueViewModel) -> String {
        let status = viewModel.selectedStatus.displayName.lowercased()
        guard viewModel.selectedReason != .all else {
            return "No \(status) reports to review."
        }
        return "No \(status) reports for \(viewModel.selectedReason.displayName.lowercased())."
    }

    private func resolveSelectedReport() {
        guard let report = reportPendingResolution else { return }
        reportPendingResolution = nil
        Task {
            await viewModel?.resolve(report)
        }
    }

    private func dismissSelectedReport() {
        guard let report = reportPendingDismissal else { return }
        reportPendingDismissal = nil
        Task {
            await viewModel?.dismiss(report)
        }
    }
}

private struct ReportModerationQueueHeader: View {
    let summary: ModerationSummary?
    let visibleCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("User reports")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("Review community reports about book-sharing libraries.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label("\(summary?.openReportsCount ?? visibleCount) open", systemImage: "flag")
                Label("\(visibleCount) shown", systemImage: "list.bullet")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ReportModerationMessageBanner: View {
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

private struct ReportModerationCard: View {
    let report: ModerationReport
    let viewModel: ModerationReportQueueViewModel
    let onResolve: () -> Void
    let onDismiss: () -> Void

    private var isUpdating: Bool {
        viewModel.updatingReportID == report.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink {
                ReportModerationDetailView(report: report, viewModel: viewModel)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    ReportModerationThumbnail(report: report, size: 64)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .top) {
                            Text(report.reason.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 8)

                            ReportModerationStatusChip(status: report.status)
                        }

                        Text(report.library.displayName)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text(detailsText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        Text(reporterText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
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

            if report.status == .open {
                HStack(spacing: 10) {
                    Button(action: onResolve) {
                        actionLabel(title: "Resolve", systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isUpdating)

                    Button(role: .destructive, action: onDismiss) {
                        actionLabel(title: "Dismiss", systemImage: "xmark")
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

    private var detailsText: String {
        report.details.isEmpty ? "No details provided" : report.details
    }

    private var reporterText: String {
        if let createdBy = report.createdBy {
            return "Reported by @\(createdBy.username)"
        }
        return "Reporter unavailable"
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
        ReportModerationQueueView()
    }
}
