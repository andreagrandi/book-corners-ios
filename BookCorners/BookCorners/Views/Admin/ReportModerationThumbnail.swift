//
//  ReportModerationThumbnail.swift
//  BookCorners
//

import SwiftUI

struct ReportModerationThumbnail: View {
    let report: ModerationReport
    let size: CGFloat

    private var imageURL: URL? {
        report.fullPhotoUrl
    }

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        placeholder(systemImage: "photo")
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder(systemImage: "photo")
                    @unknown default:
                        placeholder(systemImage: "photo")
                    }
                }
            } else {
                placeholder(systemImage: "flag")
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }

    private func placeholder(systemImage: String) -> some View {
        ZStack {
            Rectangle()
                .fill(.red.opacity(0.12))

            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.red)
        }
    }
}
