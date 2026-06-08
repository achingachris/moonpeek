//
//  PhotoThumbnail.swift
//  MoonPeek
//
//  Hosts PhotoGridItem — used in Explore, Favorites, and Notes.
//

import SwiftUI

struct PhotoGridItem: View {
    let photo: Photo
    var aspectRatio: CGFloat = 4.0 / 5.0

    var body: some View {
        // A Color base layer locks the card to the requested aspect ratio inside
        // the grid cell. The image is overlaid on top and clipped to those bounds.
        Color.black
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                RemoteImageView(urlString: photo.remoteURL, contentMode: .fill)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.black.opacity(0.7), .black.opacity(0.0)],
                    startPoint: .bottom,
                    endPoint: .center
                )
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomLeading) {
                captionPill.padding(10)
            }
            .overlay(alignment: .topTrailing) {
                indicators.padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
    }

    private var captionPill: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(photo.title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .foregroundStyle(.white)
            if let date = photo.dateTaken {
                Text(date, format: .dateTime.month(.abbreviated).year())
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var indicators: some View {
        HStack(spacing: 6) {
            if photo.localFilename != nil {
                indicator(systemImage: "arrow.down.circle.fill", tint: .green)
            }
            if photo.isFavorite {
                indicator(systemImage: "heart.fill", tint: .pink)
            }
        }
    }

    private func indicator(systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 26, height: 26)
            .glassEffect(.clear, in: Circle())
    }
}
