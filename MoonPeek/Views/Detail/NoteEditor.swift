//
//  NoteEditor.swift
//  MoonPeek
//
//  Hosts NoteEditorSheet — a glass bottom sheet for adding/editing a note.
//

import SwiftUI

struct NoteEditorSheet: View {
    @Bindable var photo: Photo
    @Environment(\.dismiss) private var dismiss

    var onSave: () -> Void
    var onShareWithNote: () -> Void

    @State private var draft: String = ""
    @FocusState private var isEditing: Bool

    var body: some View {
        ZStack {
            SpaceBackground()

            VStack(spacing: 16) {
                Capsule()
                    .fill(.white.opacity(0.25))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)

                HStack(spacing: 12) {
                    RemoteImageView(urlString: photo.remoteURL, contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(photo.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        if let date = photo.dateTaken {
                            Text(date, format: .dateTime.month(.wide).day().year())
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)

                TextField(
                    "Write a note about this photo…",
                    text: $draft,
                    axis: .vertical
                )
                .focused($isEditing)
                .font(.body)
                .foregroundStyle(.white)
                .tint(.white)
                .lineLimit(4...10)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 18)

                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Button {
                        save()
                        dismiss()
                    } label: {
                        Label("Save Note", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)

                    Button {
                        save()
                        onShareWithNote()
                    } label: {
                        Label("Share Photo + Note", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glass)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 22)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .onAppear {
            draft = photo.note
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isEditing = true
            }
        }
    }

    private func save() {
        photo.note = draft
        onSave()
    }
}
