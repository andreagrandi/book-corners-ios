//
//  EmptyStateView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 18/03/26.
//

import SwiftUI

struct EmptyStateView: View {
    let message: String
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    EmptyStateView(
        message: "No book corners found nearby.",
        title: "No Libraries Found",
        icon: "books.vertical",
    )
}
