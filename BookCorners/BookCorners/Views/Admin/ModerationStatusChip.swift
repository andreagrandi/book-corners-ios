//
//  ModerationStatusChip.swift
//  BookCorners
//

import SwiftUI

struct ModerationStatusChip: View {
    let status: LibraryModerationStatus

    var body: some View {
        StatusChipLabel(displayName: status.displayName, tint: status.tint)
    }
}

struct PhotoModerationStatusChip: View {
    let status: PhotoModerationStatus

    var body: some View {
        StatusChipLabel(displayName: status.displayName, tint: status.tint)
    }
}

struct ReportModerationStatusChip: View {
    let status: ReportModerationStatus

    var body: some View {
        StatusChipLabel(displayName: status.displayName, tint: status.tint)
    }
}

private struct StatusChipLabel: View {
    let displayName: String
    let tint: Color

    var body: some View {
        Text(displayName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: Capsule())
            .accessibilityLabel("Status: \(displayName)")
    }
}

extension LibraryModerationStatus {
    var displayName: String {
        switch self {
        case .pending:
            "Pending"
        case .approved:
            "Approved"
        case .rejected:
            "Rejected"
        }
    }

    var tint: Color {
        switch self {
        case .pending:
            .orange
        case .approved:
            .green
        case .rejected:
            .red
        }
    }
}

extension ModerationStatusFilter {
    var displayName: String {
        switch self {
        case .all:
            "All"
        case .pending:
            "Pending"
        case .approved:
            "Approved"
        case .rejected:
            "Rejected"
        }
    }
}

extension PhotoModerationStatus {
    var displayName: String {
        switch self {
        case .pending:
            "Pending"
        case .approved:
            "Approved"
        case .rejected:
            "Rejected"
        }
    }

    var tint: Color {
        switch self {
        case .pending:
            .orange
        case .approved:
            .green
        case .rejected:
            .red
        }
    }
}

extension PhotoModerationStatusFilter {
    var displayName: String {
        switch self {
        case .all:
            "All"
        case .pending:
            "Pending"
        case .approved:
            "Approved"
        case .rejected:
            "Rejected"
        }
    }
}

extension ReportModerationStatus {
    var displayName: String {
        switch self {
        case .open:
            "Open"
        case .resolved:
            "Resolved"
        case .dismissed:
            "Dismissed"
        }
    }

    var tint: Color {
        switch self {
        case .open:
            .red
        case .resolved:
            .green
        case .dismissed:
            .secondary
        }
    }
}

extension ReportModerationStatusFilter {
    var displayName: String {
        switch self {
        case .all:
            "All"
        case .open:
            "Open"
        case .resolved:
            "Resolved"
        case .dismissed:
            "Dismissed"
        }
    }
}

extension ReportModerationReasonFilter {
    var displayName: String {
        switch self {
        case .all:
            "All Reasons"
        case .damaged:
            "Damaged"
        case .missing:
            "Missing"
        case .incorrectInfo:
            "Incorrect Info"
        case .inappropriate:
            "Inappropriate"
        case .other:
            "Other"
        }
    }
}
