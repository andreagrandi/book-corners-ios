//
//  PhotoModerationThumbnail.swift
//  BookCorners
//

import SwiftUI

struct PhotoModerationThumbnail: View {
    let photo: ModerationPhoto
    let size: CGFloat

    private var imageURL: URL? {
        photo.fullThumbnailUrl ?? photo.fullPhotoUrl
    }

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            Rectangle()
                .fill(.gray.opacity(0.12))

            Image(systemName: "photo")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}
