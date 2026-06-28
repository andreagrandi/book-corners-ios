//
//  LibraryModerationThumbnail.swift
//  BookCorners
//

import SwiftUI

struct LibraryModerationThumbnail: View {
    let library: ModerationLibrary
    let size: CGFloat

    private var imageURL: URL? {
        library.fullThumbnailUrl ?? library.fullPhotoUrl
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
        .clipShape(.rect(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.gray.opacity(0.12))

            Image(systemName: "books.vertical")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
