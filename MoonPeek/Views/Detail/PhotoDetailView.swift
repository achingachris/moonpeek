//
//  PhotoDetailView.swift
//  MoonPeek
//

import SwiftUI
import SwiftData

struct PhotoDetailView: View {
    @Bindable var photo: Photo
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Photo.addedAt, order: .reverse) private var photos: [Photo]

    @State private var currentID: String?
    @State private var currentUIImage: UIImage?
    @State private var chromeVisible: Bool = true
    @State private var sheet: DetailSheet?
    @State private var toast: ToastMessage?
    @State private var autoHideTask: Task<Void, Never>?
    @State private var isSaving: Bool = false

    enum DetailSheet: Identifiable {
        case note, share, wallpaper
        var id: String {
            switch self {
            case .note: return "note"
            case .share: return "share"
            case .wallpaper: return "wallpaper"
            }
        }
    }

    init(photo: Photo) {
        self.photo = photo
        self._currentID = State(initialValue: photo.remoteID)
    }

    /// The collection actually shown in the pager. Falls back to the entry photo
    /// when the query hasn't loaded yet.
    private var pagerPhotos: [Photo] {
        photos.isEmpty ? [photo] : photos
    }

    /// The photo currently centered in the pager.
    private var currentPhoto: Photo {
        photos.first { $0.remoteID == currentID } ?? photo
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VerticalPhotoPagerView(
                photos: pagerPhotos,
                currentID: $currentID,
                onTap: toggleChrome,
                onDoubleTap: favoriteOnDoubleTap,
                onImageLoaded: { id, image in
                    if id == currentID { currentUIImage = image }
                }
            )
            .ignoresSafeArea()

            if chromeVisible {
                VStack(spacing: 0) {
                    topBar
                        .padding(.top, 6)
                        .padding(.horizontal, 16)

                    Spacer()

                    VStack(spacing: 12) {
                        PhotoThumbnailFilmstrip(
                            photos: pagerPhotos,
                            currentID: $currentID,
                            onUserInteraction: scheduleAutoHide
                        )
                        bottomBar
                    }
                    .padding(.bottom, 24)
                    .padding(.horizontal, 16)
                }
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(!chromeVisible)
        .downloadToast($toast)
        .onAppear { scheduleAutoHide() }
        .onChange(of: currentID) { _, _ in
            // New page selected; refresh sheet-bound image and reset the auto-hide.
            scheduleAutoHide()
            Task { await loadCurrentImage() }
        }
        .task { await loadCurrentImage() }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .note:
                NoteEditorSheet(
                    photo: currentPhoto,
                    onSave: { try? modelContext.save() },
                    onShareWithNote: { self.sheet = .share }
                )
            case .share:
                ShareOptionsSheet(photo: currentPhoto, uiImage: currentUIImage)
            case .wallpaper:
                if let currentUIImage {
                    WallpaperPreviewView(uiImage: currentUIImage, title: currentPhoto.title) { message in
                        showToast(title: message, icon: "checkmark.circle.fill")
                        dismissToastAfterDelay()
                    }
                }
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .glassEffect(.clear, in: Circle())
                }
                .accessibilityLabel("Back")

                VStack(alignment: .leading, spacing: 0) {
                    Text(currentPhoto.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let date = currentPhoto.dateTaken {
                        Text(date, format: .dateTime.month(.abbreviated).day().year())
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 40)
                .glassEffect(.clear, in: Capsule())

                Spacer()

                Button {
                    currentPhoto.isFavorite.toggle()
                    try? modelContext.save()
                    scheduleAutoHide()
                } label: {
                    Image(systemName: currentPhoto.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(currentPhoto.isFavorite ? .pink : .white)
                        .frame(width: 40, height: 40)
                        .glassEffect(.clear, in: Circle())
                }
                .accessibilityLabel(currentPhoto.isFavorite ? "Unfavorite" : "Favorite")
            }
        }
    }

    // MARK: - Bottom action bar

    private var bottomBar: some View {
        GlassEffectContainer(spacing: 6) {
            HStack(spacing: 6) {
                GlassActionButton(systemImage: "square.and.pencil", label: "Add note") {
                    scheduleAutoHide()
                    sheet = .note
                }
                GlassActionButton(
                    systemImage: currentPhoto.localFilename != nil ? "checkmark.circle.fill" : "arrow.down.to.line",
                    label: "Download"
                ) {
                    scheduleAutoHide()
                    Task { await download() }
                }
                .disabled(currentUIImage == nil || isSaving)

                GlassActionButton(systemImage: "square.and.arrow.up", label: "Share", isProminent: true) {
                    scheduleAutoHide()
                    sheet = .share
                }
                .disabled(currentUIImage == nil)

                GlassActionButton(systemImage: "photo.on.rectangle.angled", label: "Prepare Wallpaper") {
                    scheduleAutoHide()
                    sheet = .wallpaper
                }
                .disabled(currentUIImage == nil)
            }
            .padding(8)
        }
    }

    // MARK: - Chrome / auto-hide

    private func toggleChrome() {
        withAnimation(.easeInOut(duration: 0.25)) {
            chromeVisible.toggle()
        }
        scheduleAutoHide()
    }

    /// Instagram-style: double-tap sets favorite (never un-favorites).
    /// Use the top-bar heart button to un-favorite.
    private func favoriteOnDoubleTap(_ tapped: Photo) {
        guard !tapped.isFavorite else { return }
        tapped.isFavorite = true
        try? modelContext.save()
    }

    private func scheduleAutoHide() {
        autoHideTask?.cancel()
        guard chromeVisible else { return }
        autoHideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                chromeVisible = false
            }
        }
    }

    // MARK: - Image loading for sheet handoff

    private func loadCurrentImage() async {
        let url = currentPhoto.remoteURL
        let loaded = await ImageLoader.shared.image(for: url)
        await MainActor.run {
            if currentPhoto.remoteURL == url { currentUIImage = loaded }
        }
    }

    // MARK: - Actions

    private func download() async {
        guard let image = currentUIImage else { return }
        let target = currentPhoto
        isSaving = true
        defer { isSaving = false }
        showToast(title: "Saving…", icon: "arrow.down.circle", progress: 0.3)
        do {
            try await PhotoLibraryService.save(image)
            target.localFilename = target.remoteID
            try? modelContext.save()
            showToast(title: "Saved to Photos", icon: "checkmark.circle.fill")
        } catch {
            showToast(title: error.localizedDescription, icon: "exclamationmark.triangle.fill")
        }
        dismissToastAfterDelay()
    }

    private func showToast(title: String, icon: String, progress: Double? = nil) {
        toast = ToastMessage(title: title, icon: icon, progress: progress)
    }

    private func dismissToastAfterDelay() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            toast = nil
        }
    }
}

#Preview {
    NavigationStack {
        PhotoDetailView(photo: Photo.sampleSeed[0])
    }
    .modelContainer(for: Photo.self, inMemory: true)
}
