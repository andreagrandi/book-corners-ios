//
//  AdminDashboardStatusComponents.swift
//  BookCorners
//

import SwiftUI

struct AdminStatusCard: View {
    let isLoading: Bool
    let errorMessage: String?
    let hasSummary: Bool

    private var apiStatus: (value: String, tint: Color) {
        if isLoading {
            return ("Loading", .orange)
        }
        if errorMessage != nil {
            return ("Needs attention", .red)
        }
        if hasSummary {
            return ("Connected", .green)
        }
        return ("Waiting", .secondary)
    }

    var body: some View {
        VStack(spacing: 0) {
            AdminStatusRow(title: "Staff session", value: "Active", tint: .green)
            Divider()
                .padding(.leading, 16)
            AdminStatusRow(title: "Moderation APIs", value: apiStatus.value, tint: apiStatus.tint)
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

struct AdminSummaryItem: Identifiable {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    let badge: String?

    var id: String {
        title
    }
}
