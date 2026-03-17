//
//  LibraryCardView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 17/03/26.
//

import CoreLocation
import SwiftUI

struct LibraryCardView: View {
    let library: Library
    let distance: CLLocationDistance?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let thumbnailURL = URL(string: library.thumbnailUrl), !library.thumbnailUrl.isEmpty {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .empty:
                        thumbnailPlaceholder
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(.rect(cornerRadius: 8))
                    case .failure:
                        thumbnailPlaceholder
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
            } else {
                thumbnailPlaceholder
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(library.name)
                    .font(.headline)

                Text("\(library.city), \(library.country)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let distance {
                    Text(distance.formattedForDisplay)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.12))

            Image(systemName: "books.vertical")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(width: 60, height: 60)
    }
}
