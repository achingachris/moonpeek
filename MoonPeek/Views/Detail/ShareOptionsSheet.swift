//
//  ShareOptionsSheet.swift
//  MoonPeek
//

import SwiftUI

enum ShareKind: String, CaseIterable, Identifiable {
    case photo, note, combined

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photo: return "Share Photo"
        case .note: return "Share Note"
        case .combined: return "Share Photo + Note"
        }
    }

    var subtitle: String {
        switch self {
        case .photo: return "The Artemis II image only."
        case .note: return "Your written note only."
        case .combined: return "A composed card with image + your note."
        }
    }

    var systemImage: String {
        switch self {
        case .photo: return "photo"
        case .note: return "text.alignleft"
        case .combined: return "rectangle.on.rectangle"
        }
    }
}

struct ShareOptionsSheet: View {
    let photo: Photo
    let uiImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    @State private var renderedCard: UIImage?

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 18) {
                Capsule()
                    .fill(.white.opacity(0.25))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)

                Text("Share")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                VStack(spacing: 12) {
                    ForEach(ShareKind.allCases) { kind in
                        shareRow(kind)
                    }
                }
                .padding(.horizontal, 18)

                Spacer(minLength: 0)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .task { await renderCardIfNeeded() }
    }

    @ViewBuilder
    private func shareRow(_ kind: ShareKind) -> some View {
        switch kind {
        case .photo:
            if let uiImage {
                ShareLink(
                    item: PhotoSharePayload(
                        image: Image(uiImage: uiImage),
                        uiImage: uiImage,
                        caption: photo.title,
                        title: photo.title
                    ),
                    preview: SharePreview(photo.title, image: Image(uiImage: uiImage))
                ) {
                    shareCard(for: kind, enabled: true)
                }
                .buttonStyle(.plain)
            } else {
                shareCard(for: kind, enabled: false)
            }

        case .note:
            ShareLink(item: noteString) {
                shareCard(for: kind, enabled: !photo.note.isEmpty)
            }
            .disabled(photo.note.isEmpty)
            .buttonStyle(.plain)

        case .combined:
            if let renderedCard {
                ShareLink(
                    item: PhotoSharePayload(
                        image: Image(uiImage: renderedCard),
                        uiImage: renderedCard,
                        caption: noteString,
                        title: photo.title
                    ),
                    preview: SharePreview(photo.title, image: Image(uiImage: renderedCard))
                ) {
                    shareCard(for: kind, enabled: !photo.note.isEmpty)
                }
                .disabled(photo.note.isEmpty)
                .buttonStyle(.plain)
            } else {
                shareCard(for: kind, enabled: false)
            }
        }
    }

    private func shareCard(for kind: ShareKind, enabled: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: kind.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .glassEffect(.clear, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(kind.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(kind.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(enabled ? 1.0 : 0.4)
    }

    private var noteString: String {
        var parts: [String] = []
        if !photo.title.isEmpty { parts.append(photo.title) }
        if !photo.note.isEmpty { parts.append(photo.note) }
        parts.append("— Shared from MoonPeek · Artemis II")
        return parts.joined(separator: "\n\n")
    }

    @MainActor
    private func renderCardIfNeeded() async {
        guard let uiImage, !photo.note.isEmpty, renderedCard == nil else { return }
        let card = ShareCardView(title: photo.title, note: photo.note, image: uiImage)
            .frame(width: 1080, height: 1350)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1.0
        renderedCard = renderer.uiImage
    }
}

/// Composed card layout used when sharing photo + note.
struct ShareCardView: View {
    let title: String
    let note: String
    let image: UIImage

    var body: some View {
        ZStack {
            Color.black

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 1080, height: 1350)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.85)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 18) {
                Spacer()

                Text(title)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(note)
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(6)

                HStack(spacing: 10) {
                    Image(systemName: "moonphase.first.quarter")
                        .font(.system(size: 22, weight: .semibold))
                    Text("MoonPeek · Artemis II")
                        .font(.system(size: 24, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 6)
            }
            .padding(56)
            .frame(width: 1080, height: 1350, alignment: .bottomLeading)
        }
        .frame(width: 1080, height: 1350)
    }
}
