//
//  ReportModerationDetailView.swift
//  BookCorners
//

import SwiftUI

struct ReportModerationDetailView: View {
    let report: ModerationReport
    let viewModel: ModerationReportQueueViewModel

    @State private var showingResolveConfirmation = false
    @State private var showingDismissConfirmation = false

    private var currentReport: ModerationReport {
        if let detailReport = viewModel.detailReport, detailReport.id == report.id {
            return detailReport
        }
        return report
    }

    private var isUpdatingCurrentReport: Bool {
        viewModel.updatingReportID == currentReport.id
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ReportModerationEvidencePhoto(report: currentReport)

                if let actionErrorMessage = viewModel.actionErrorMessage {
                    ReportModerationDetailBanner(
                        message: actionErrorMessage,
                        tint: .red,
                        systemImage: "exclamationmark.triangle.fill",
                    )
                }

                ReportModerationTitleSection(report: currentReport)

                ReportModerationDetailSection(title: "Library") {
                    ReportModerationDetailRow(title: "Name", value: currentReport.library.displayName)
                    ReportModerationDetailRow(title: "City", value: displayValue(currentReport.library.city))
                    ReportModerationDetailRow(title: "Country", value: displayValue(currentReport.library.country))
                    ReportModerationDetailRow(title: "Address", value: displayValue(currentReport.library.address))
                }

                ReportModerationDetailSection(title: "Report") {
                    ReportModerationDetailRow(title: "Reason", value: currentReport.reason.displayName)
                    ReportModerationDetailRow(title: "Details", value: displayValue(currentReport.details))
                }

                ReportModerationDetailSection(title: "Submission") {
                    ReportModerationDetailRow(title: "Reporter", value: reporterText(for: currentReport))
                    ReportModerationDetailRow(title: "Status", value: currentReport.status.displayName)
                    ReportModerationDetailRow(
                        title: "Submitted",
                        value: currentReport.createdAt.formatted(date: .abbreviated, time: .shortened),
                    )
                    ReportModerationDetailRow(title: "Report ID", value: currentReport.id.formatted())
                }

                ReportModerationActionSection(
                    report: currentReport,
                    isUpdating: isUpdatingCurrentReport,
                    onResolve: {
                        viewModel.clearActionError()
                        showingResolveConfirmation = true
                    },
                    onDismiss: {
                        viewModel.clearActionError()
                        showingDismissConfirmation = true
                    },
                )
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(currentReport.reason.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: report.id) {
            viewModel.setDetailReport(report)
        }
        .alert("Resolve Report?", isPresented: $showingResolveConfirmation) {
            Button("Resolve") {
                resolveCurrentReport()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mark this report as handled once the library issue has been reviewed.")
        }
        .alert("Dismiss Report?", isPresented: $showingDismissConfirmation) {
            Button("Dismiss", role: .destructive) {
                dismissCurrentReport()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Dismiss this report if no moderation action is needed.")
        }
    }

    private func resolveCurrentReport() {
        let report = currentReport
        Task {
            await viewModel.resolve(report)
        }
    }

    private func dismissCurrentReport() {
        let report = currentReport
        Task {
            await viewModel.dismiss(report)
        }
    }

    private func displayValue(_ value: String, fallback: String = "Not provided") -> String {
        value.isEmpty ? fallback : value
    }

    private func reporterText(for report: ModerationReport) -> String {
        if let createdBy = report.createdBy {
            return "@\(createdBy.username)"
        }
        return "Unavailable"
    }
}

private struct ReportModerationEvidencePhoto: View {
    let report: ModerationReport

    private var imageURL: URL? {
        report.fullPhotoUrl
    }

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        imagePlaceholder
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 320)
                .clipShape(.rect(cornerRadius: 18, style: .continuous))
                .accessibilityLabel("Evidence photo")
            } else {
                noEvidencePlaceholder
            }
        }
    }

    private var imagePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.red.opacity(0.12))

            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.red)
        }
    }

    private var noEvidencePlaceholder: some View {
        Label("No evidence photo attached", systemImage: "photo.badge.exclamationmark")
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}

private struct ReportModerationTitleSection: View {
    let report: ModerationReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.reason.displayName)
                        .font(.title.bold())
                        .foregroundStyle(.primary)

                    Text(report.library.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                ReportModerationStatusChip(status: report.status)
            }

            Text(detailsText)
                .font(.body)
                .foregroundStyle(report.details.isEmpty ? .secondary : .primary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var detailsText: String {
        report.details.isEmpty ? "No details provided" : report.details
    }
}

private struct ReportModerationDetailSection<Content: View>: View {
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

private struct ReportModerationDetailRow: View {
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

private struct ReportModerationActionSection: View {
    let report: ModerationReport
    let isUpdating: Bool
    let onResolve: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIONS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1.4)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                if report.status == .open {
                    Button(action: onResolve) {
                        actionLabel(title: "Resolve Report", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isUpdating)

                    Button(role: .destructive, action: onDismiss) {
                        actionLabel(title: "Dismiss Report", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.red)
                    .disabled(isUpdating)
                } else {
                    Label("No pending action", systemImage: "checkmark.seal")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(report.status.tint)
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

private struct ReportModerationDetailBanner: View {
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
        ReportModerationDetailView(
            report: SampleData.moderationReport,
            viewModel: ModerationReportQueueViewModel(client: MockAPIClient()),
        )
    }
}
