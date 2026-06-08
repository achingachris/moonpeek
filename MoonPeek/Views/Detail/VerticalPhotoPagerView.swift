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
    let onDoubleTap: (Photo) -> Void
    let onImageLoaded: (String, UIImage) -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(photos) { photo in
                        FullScreenPhotoPage(
                            photo: photo,
                            onTap: onTap,
                            onDoubleTap: { onDoubleTap(photo) },
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
    let onDoubleTap: () -> Void
    let onImageLoaded: (UIImage) -> Void

    @State private var uiImage: UIImage?
    @State private var zoomScale: CGFloat = 1.0
    @State private var liveZoom: CGFloat = 1.0

    // Heart-burst animation state.
    @State private var heartScale: CGFloat = 0.4
    @State private var heartOpacity: CGFloat = 0.0
    @State private var heartTrigger: Int = 0

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

            // Instagram-style heart pop overlay.
            Image(systemName: "heart.fill")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.55), radius: 22)
                .scaleEffect(heartScale)
                .opacity(heartOpacity)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { triggerHeart() }
        .onTapGesture { onTap() }
        .sensoryFeedback(.success, trigger: heartTrigger)
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
            heartScale = 0.4
            heartOpacity = 0.0
        }
    }

    private func triggerHeart() {
        heartTrigger &+= 1
        onDoubleTap()

        // Reset, then spring in.
        heartScale = 0.4
        heartOpacity = 0.0
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            heartScale = 1.0
            heartOpacity = 1.0
        }
        // Linger briefly, then fade-out + scale-up.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.easeOut(duration: 0.4)) {
                heartScale = 1.18
                heartOpacity = 0.0
            }
        }
    }
}
