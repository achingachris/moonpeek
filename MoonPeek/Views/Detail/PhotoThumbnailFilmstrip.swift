//
//  PhotoThumbnailFilmstrip.swift
//  MoonPeek
//
//  Tap-to-reveal horizontal photo selector for the immersive viewer.
//

import SwiftUI

struct PhotoThumbnailFilmstrip: View {
    let photos: [Photo]
    @Binding var currentID: String?
    var onUserInteraction: () -> Void = {}

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(photos) { photo in
                        FilmstripCell(photo: photo, isSelected: photo.remoteID == currentID)
                            .id(photo.remoteID)
                            .onTapGesture {
                                onUserInteraction()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentID = photo.remoteID
                                }
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .frame(height: 80)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .onChange(of: currentID) { _, newID in
                guard let newID else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newID, anchor: .center)
                }
            }
            .onAppear {
                if let currentID {
                    proxy.scrollTo(currentID, anchor: .center)
                }
            }
        }
    }
}

private struct FilmstripCell: View {
    let photo: Photo
    let isSelected: Bool

    var body: some View {
        RemoteImageView(urlString: photo.remoteURL, contentMode: .fill)
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.white : Color.white.opacity(0.12),
                                  lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .shadow(color: isSelected ? .white.opacity(0.25) : .clear, radius: 8)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: isSelected)
            .accessibilityLabel(photo.title)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
