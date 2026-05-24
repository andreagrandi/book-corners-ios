//
//  PhotoViewerView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 24/05/26.
//

import SwiftUI

struct PhotoViewerView: View {
    let url: URL
    let accessibilityName: String

    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dragDismissOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 4.0
    private let zoomedScale: CGFloat = 2.5
    private let dismissThreshold: CGFloat = 120

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(.white)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(
                            x: offset.width + dragDismissOffset.width,
                            y: offset.height + dragDismissOffset.height,
                        )
                        .gesture(combinedGesture)
                        .onTapGesture(count: 2, perform: handleDoubleTap)
                        .accessibilityLabel("Photo of \(accessibilityName)")
                        .accessibilityHint("Pinch to zoom. Swipe down to close.")
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .accessibilityLabel("Photo failed to load")
                @unknown default:
                    EmptyView()
                }
            }
        }
        .statusBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.black)
        .overlay(alignment: .topLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: .circle)
            }
            .padding()
            .accessibilityLabel("Close photo")
        }
    }

    private var combinedGesture: some Gesture {
        magnifyGesture.simultaneously(with: panGesture)
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let proposed = lastScale * value.magnification
                scale = min(max(proposed, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= minScale {
                    withAnimation(.spring) {
                        scale = minScale
                        offset = .zero
                        lastOffset = .zero
                    }
                    lastScale = minScale
                }
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > minScale {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height,
                    )
                } else {
                    dragDismissOffset = CGSize(width: 0, height: max(0, value.translation.height))
                }
            }
            .onEnded { value in
                if scale > minScale {
                    lastOffset = offset
                } else if value.translation.height > dismissThreshold {
                    dismiss()
                } else {
                    withAnimation(.spring) {
                        dragDismissOffset = .zero
                    }
                }
            }
    }

    private func handleDoubleTap() {
        withAnimation(.spring) {
            if scale > minScale {
                scale = minScale
                lastScale = minScale
                offset = .zero
                lastOffset = .zero
            } else {
                scale = zoomedScale
                lastScale = zoomedScale
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhotoViewerView(
            url: URL(string: "https://picsum.photos/800/1200")!,
            accessibilityName: "Sample Library",
        )
    }
}
