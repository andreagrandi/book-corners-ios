//
//  AdminDashboardView.swift
//  BookCorners
//

import SwiftUI

struct AdminDashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let summaryItems = AdminDashboardData.summaryItems
    private let moderationItems = AdminDashboardData.moderationItems

    private var summaryColumns: [GridItem] {
        let columnCount = horizontalSizeClass == .regular ? 4 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: columnCount,
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AdminDashboardHeader()

                LazyVGrid(columns: summaryColumns, spacing: 12) {
                    ForEach(summaryItems) { item in
                        AdminSummaryCard(item: item)
                    }
                }

                AdminDashboardSection(title: "Moderation queue") {
                    AdminModerationList(items: moderationItems)
                }

                AdminDashboardSection(title: "System status") {
                    AdminStatusCard()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Admin Dashboard")
        .navigationBarTitleDisplayMode(.inline)
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
    let items: [AdminModerationItem]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                NavigationLink {
                    AdminPlaceholderDetailView(item: item)
                } label: {
                    AdminModerationRow(item: item)
                }
                .buttonStyle(.plain)

                if item.id != items.last?.id {
                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
}

private struct AdminModerationRow: View {
    let item: AdminModerationItem

    @ScaledMetric(relativeTo: .body) private var iconContainerSize = 44.0
    @ScaledMetric(relativeTo: .body) private var iconSize = 22.0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(item.tint)
                .frame(width: iconContainerSize, height: iconContainerSize)
                .background(item.tint.opacity(0.12), in: .rect(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(item.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text(item.status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(item.tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.tint.opacity(0.12), in: Capsule())

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.subtitle), \(item.status)")
        .accessibilityHint("Opens the moderation workflow")
    }
}

private struct AdminStatusCard: View {
    var body: some View {
        VStack(spacing: 0) {
            AdminStatusRow(title: "Staff session", value: "Active", tint: .green)
            Divider()
                .padding(.leading, 16)
            AdminStatusRow(title: "Moderation APIs", value: "Coming next", tint: .orange)
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
}

private struct AdminStatusRow: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Label(value, systemImage: "circle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint)
                .labelStyle(.titleAndIcon)
        }
        .font(.body)
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

private struct AdminPlaceholderDetailView: View {
    let item: AdminModerationItem

    var body: some View {
        ContentUnavailableView {
            Label(item.title, systemImage: item.systemImage)
        } description: {
            Text("This staff workflow will be connected in a follow-up moderation ticket.")
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum AdminDashboardData {
    static let summaryItems = [
        AdminSummaryItem(
            title: "Staff access",
            value: "On",
            systemImage: "checkmark.shield",
            tint: .blue,
            badge: "Staff",
        ),
        AdminSummaryItem(
            title: "Library approvals",
            value: "Soon",
            systemImage: "books.vertical",
            tint: .indigo,
            badge: nil,
        ),
        AdminSummaryItem(
            title: "Pending photos",
            value: "Soon",
            systemImage: "photo.on.rectangle",
            tint: .purple,
            badge: nil,
        ),
        AdminSummaryItem(
            title: "Open reports",
            value: "Soon",
            systemImage: "exclamationmark.octagon",
            tint: .red,
            badge: nil,
        ),
    ]

    static let moderationItems = [
        AdminModerationItem(
            title: "Library approvals",
            subtitle: "Approve or reject submitted book-sharing libraries.",
            status: "Next",
            systemImage: "books.vertical",
            tint: .blue,
        ),
        AdminModerationItem(
            title: "Submitted photos",
            subtitle: "Review community photos before they appear publicly.",
            status: "Next",
            systemImage: "camera",
            tint: .purple,
        ),
        AdminModerationItem(
            title: "User reports",
            subtitle: "Resolve reports for inaccurate or damaged locations.",
            status: "Next",
            systemImage: "flag",
            tint: .red,
        ),
    ]
}

private struct AdminSummaryItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    let badge: String?
}

private struct AdminModerationItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let status: String
    let systemImage: String
    let tint: Color
}

#Preview {
    NavigationStack {
        AdminDashboardView()
    }
}
