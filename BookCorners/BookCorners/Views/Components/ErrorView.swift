//
//  ErrorView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 18/03/26.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button("Retry", action: retryAction)
            }
        }
        .padding()
    }
}

#Preview {
    ErrorView(message: "Something went wrong", retryAction: nil)
}
