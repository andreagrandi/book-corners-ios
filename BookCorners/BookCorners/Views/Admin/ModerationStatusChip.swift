//
//  ModerationStatusChip.swift
//  BookCorners
//

import SwiftUI

struct ModerationStatusChip: View {
    let status: LibraryModerationStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.tint.opacity(0.12), in: Capsule())
            .accessibilityLabel("Status: \(status.displayName)")
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
