//
//  NotesView.swift
//  MoonPeek
//

import SwiftUI
import SwiftData

struct NotesView: View {
    @Query(
        filter: #Predicate<Photo> { $0.note != "" },
        sort: \Photo.addedAt,
        order: .reverse
    ) private var notedPhotos: [Photo]

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(notedPhotos) { photo in
                        NavigationLink(value: photo) {
                            NoteRow(photo: photo)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)

            if notedPhotos.isEmpty {
                EmptyStateView(
                    title: "No Notes Yet",
                    message: "Open a photo and add a note. It will appear here.",
                    systemImage: "square.and.pencil"
                )
            }
        }
        .navigationTitle("Notes")
    }
}

private struct NoteRow: View {
    let photo: Photo

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RemoteImageView(urlString: photo.remoteURL, contentMode: .fill)
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(photo.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(photo.note)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(3)

                Spacer(minLength: 0)

                Text(photo.addedAt, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
