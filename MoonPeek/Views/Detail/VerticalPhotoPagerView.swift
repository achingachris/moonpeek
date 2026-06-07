//
//  VerticalPhotoPagerView.swift
//  MoonPeek
//
//  Reels-style vertical pager for full-screen Artemis II photos.
//

import SwiftUI

struct VerticalPhotoPagerView: View {
    let photos: [Photo]
    @Binding var currentID: String?
    let onTap: () -> Void
    let onImageLoaded: (String, UIImage) -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(photos) { photo in
                        FullScreenPhotoPage(
                            photo: photo,
                            onTap: onTap,
                            onImageLoaded: { onImageLoaded(photo.remoteID, $0) }
                        )
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .id(photo.remoteID)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentID)
        }
    }
}

/// A single full-screen page: blurred backdrop + scaled-to-fit photo + zoom/tap gestures.
private struct FullScreenPhotoPage: View {
    let photo: Photo
    let onTap: () -> Void
    let onImageLoaded: (UIImage) -> Void

    @State private var uiImage: UIImage?
    @State private var zoomScale: CGFloat = 1.0
    @State private var liveZoom: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black

            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 44)
                    .clipped()
                    .overlay(Color.black.opacity(0.45))
                    .allowsHitTesting(false)

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(zoomScale * liveZoom)
                    .simultaneousGesture(
                        MagnifyGesture()
                            .onChanged { value in liveZoom = value.magnification }
                            .onEnded { value in
                                zoomScale = max(1.0, min(zoomScale * value.magnification, 4.0))
                                liveZoom = 1.0
                            }
                    )
            } else {
                ProgressView()
                    .tint(.white)
                    .controlSize(.large)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                zoomScale = zoomScale > 1.0 ? 1.0 : 2.0
            }
        }
        .onTapGesture { onTap() }
        .task(id: photo.remoteURL) {
            let loaded = await ImageLoader.shared.image(for: photo.remoteURL)
            await MainActor.run {
                uiImage = loaded
                if let loaded { onImageLoaded(loaded) }
            }
        }
        .onDisappear {
            zoomScale = 1.0
            liveZoom = 1.0
        }
    }
}
