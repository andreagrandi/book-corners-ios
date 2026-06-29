//
//  AdminDashboardView.swift
//  BookCorners
//

import SwiftUI

struct AdminDashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.apiClient) private var apiClient

    @State private var viewModel: ModerationLibraryQueueViewModel?

    private var summaryColumns: [GridItem] {
        let columnCount = horizontalSizeClass == .regular ? 4 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: columnCount,
        )
    }

    private var summaryItems: [AdminSummaryItem] {
        let summary = viewModel?.summary
        return [
            AdminSummaryItem(
                title: "Total Libraries",
                value: formattedCount(summary?.totalLibraries),
                systemImage: "books.vertical",
                tint: .blue,
                badge: summary == nil ? nil : "Live",
            ),
            AdminSummaryItem(
                title: "Pending Libraries",
                value: formattedCount(summary?.pendingLibrariesCount),
                systemImage: "clock.badge.exclamationmark",
                tint: .orange,
                badge: pendingBadge(summary?.pendingLibrariesCount),
            ),
            AdminSummaryItem(
                title: "Pending Photos",
                value: formattedCount(summary?.pendingPhotosCount),
                systemImage: "photo.on.rectangle",
                tint: .purple,
                badge: nil,
            ),
            AdminSummaryItem(
                title: "Open Reports",
                value: formattedCount(summary?.openReportsCount),
                systemImage: "exclamationmark.octagon",
                tint: .red,
                badge: nil,
            ),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AdminDashboardHeader()

                if let errorMessage = viewModel?.errorMessage {
                    AdminDashboardErrorBanner(message: errorMessage)
                }

                LazyVGrid(columns: summaryColumns, spacing: 12) {
                    ForEach(summaryItems) { item in
                        AdminSummaryCard(item: item)
                    }
                }

                AdminDashboardSection(title: "Moderation queue") {
                    AdminModerationList(summary: viewModel?.summary)
                }

                AdminDashboardSection(title: "System status") {
                    AdminStatusCard(
                        isLoading: viewModel?.isLoading == true,
                        errorMessage: viewModel?.errorMessage,
                        hasSummary: viewModel?.summary != nil,
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Admin Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = ModerationLibraryQueueViewModel(client: apiClient)
            }
            await viewModel?.loadInitialIfNeeded()
        }
        .refreshable {
            await viewModel?.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .moderationLibraryQueueDidChange)) { _ in
            Task {
                await viewModel?.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .moderationPhotoQueueDidChange)) { _ in
            Task {
                await viewModel?.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .adminModerationSummaryDidChange)) { _ in
            Task {
                await viewModel?.refresh()
            }
        }
    }

    private func formattedCount(_ value: Int?) -> String {
        guard let value else { return "—" }
        return value.formatted()
    }

    private func pendingBadge(_ count: Int?) -> String? {
        guard let count, count > 0 else { return nil }
        return "Review"
    }
}

private struct AdminDashboardHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dashboard")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            Text("Staff tools for reviewing community contributions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct AdminDashboardErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.orange)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: .rect(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .combine)
    }
}

private struct AdminDashboardSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(1.4)
                .padding(.horizontal, 4)

            content
        }
    }
}

private struct AdminSummaryCard: View {
    let item: AdminSummaryItem

    @ScaledMetric(relativeTo: .headline) private var iconContainerSize = 40.0
    @ScaledMetric(relativeTo: .headline) private var iconSize = 22.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: item.systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(item.tint)
                    .frame(width: iconContainerSize, height: iconContainerSize)
                    .background(item.tint.opacity(0.12), in: .rect(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)

                Spacer(minLength: 8)

                if let badge = item.badge {
                    Text(badge)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.tint.opacity(0.12), in: Capsule())
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.value)
                    .font(.title.bold())
                    .foregroundStyle(item.tint)
                    .minimumScaleFactor(0.7)

                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .topLeading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.value)")
    }
}

private struct AdminModerationList: View {
    let summary: ModerationSummary?

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink {
                LibraryModerationQueueView()
            } label: {
                AdminModerationRow(
                    title: "Library approvals",
                    subtitle: "Approve or reject submitted book-sharing libraries.",
                    status: queueStatus(summary?.pendingLibrariesCount),
                    systemImage: "books.vertical",
                    tint: .blue,
                )
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.leading, 64)

            NavigationLink {
                PhotoModerationQueueView()
            } label: {
                AdminModerationRow(
                    title: "Submitted photos",
                    subtitle: "Review community photos before they appear publicly.",
                    status: queueStatus(summary?.pendingPhotosCount),
                    systemImage: "camera",
                    tint: .purple,
                )
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.leading, 64)

            NavigationLink {
                AdminPlaceholderDetailView(
                    title: "User reports",
                    systemImage: "flag",
                )
            } label: {
                AdminModerationRow(
                    title: "User reports",
                    subtitle: "Resolve reports for inaccurate or damaged locations.",
                    status: queueStatus(summary?.openReportsCount),
                    systemImage: "flag",
                    tint: .red,
                )
            }
            .buttonStyle(.plain)
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }

    private func queueStatus(_ count: Int?) -> String {
        guard let count else { return "—" }
        return count == 0 ? "Clear" : "\(count)"
    }
}

private struct AdminModerationRow: View {
    let title: String
    let subtitle: String
    let status: String
    let systemImage: String
    let tint: Color

    @ScaledMetric(relativeTo: .body) private var iconContainerSize = 44.0
    @ScaledMetric(relativeTo: .body) private var iconSize = 22.0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: iconContainerSize, height: iconContainerSize)
                .background(tint.opacity(0.12), in: .rect(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text(status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tint.opacity(0.12), in: Capsule())

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle), \(status)")
        .accessibilityHint("Opens the moderation workflow")
    }
}

private struct AdminPlaceholderDetailView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text("This staff workflow will be connected in a follow-up moderation ticket.")
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AdminDashboardView()
    }
}
