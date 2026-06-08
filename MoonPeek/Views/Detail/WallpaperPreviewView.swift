//
//  WallpaperPreviewView.swift
//  MoonPeek
//

import SwiftUI

struct WallpaperPreviewView: View {
    let uiImage: UIImage
    let title: String
    var onSaved: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var dim: Double = 0.15
    @State private var useBlur: Bool = false
    @State private var screenMode: ScreenMode = .lock
    @State private var isSaving: Bool = false

    enum ScreenMode: String, CaseIterable, Identifiable {
        case lock, home
        var id: String { rawValue }
        var title: String { self == .lock ? "Lock Screen" : "Home Screen" }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()

                VStack(spacing: 16) {
                    Picker("Screen", selection: $screenMode) {
                        ForEach(ScreenMode.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                    GeometryReader { proxy in
                        let frameWidth = proxy.size.width - 64
                        let frameHeight = frameWidth * 1.85
                        wallpaperPreview(width: frameWidth, height: frameHeight)
                            .frame(width: proxy.size.width)
                            .frame(maxHeight: .infinity)
                    }

                    controls
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                }
            }
            .navigationTitle("Prepare Wallpaper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Save").bold()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Preview

    private func wallpaperPreview(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            renderableLayer
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))

            chrome
                .frame(width: width, height: height)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 22, x: 0, y: 12)
    }

    private var renderableLayer: some View {
        ZStack {
            Color.black
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .scaleEffect(scale)
                .blur(radius: useBlur ? 28 : 0)
                .clipped()

            Color.black.opacity(dim)
        }
    }

    private var chrome: some View {
        VStack {
            if screenMode == .lock {
                VStack(spacing: 4) {
                    Text(Date(), format: .dateTime.weekday(.wide).month().day())
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.95))
                    Text(Date(), format: .dateTime.hour().minute())
                        .font(.system(size: 84, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                .padding(.top, 44)

                Spacer()

                HStack(spacing: 30) {
                    Image(systemName: "flashlight.off.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .glassEffect(.clear, in: Circle())
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .glassEffect(.clear, in: Circle())
                }
                .foregroundStyle(.white)
                .padding(.bottom, 24)
            } else {
                Spacer()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 4), spacing: 18) {
                    ForEach(0..<8, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white.opacity(0.18))
                            .frame(height: 48)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 70)

                Capsule()
                    .fill(.white.opacity(0.7))
                    .frame(width: 120, height: 4)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Zoom", systemImage: "plus.magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Slider(value: $scale, in: 0.6...2.2)
                    .tint(.accentColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Dim", systemImage: "circle.lefthalf.filled")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Slider(value: $dim, in: 0...0.6)
                    .tint(.accentColor)
            }

            Toggle(isOn: $useBlur) {
                Label("Blur background", systemImage: "drop.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .tint(.accentColor)

            Text("After saving, open Photos → Share → Use as Wallpaper to set it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Save

    @MainActor
    private func save() {
        isSaving = true
        let render = WallpaperRenderable(
            uiImage: uiImage,
            scale: scale,
            dim: dim,
            useBlur: useBlur
        )
        let renderer = ImageRenderer(content: render.frame(width: 1170, height: 2532))
        renderer.scale = 1.0
        guard let prepared = renderer.uiImage else {
            isSaving = false
            return
        }
        Task {
            do {
                try await PhotoLibraryService.save(prepared)
                isSaving = false
                onSaved("Wallpaper saved to Photos")
                dismiss()
            } catch {
                isSaving = false
                onSaved(error.localizedDescription)
            }
        }
    }
}

private struct WallpaperRenderable: View {
    let uiImage: UIImage
    let scale: CGFloat
    let dim: Double
    let useBlur: Bool

    var body: some View {
        ZStack {
            Color.black
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .scaleEffect(scale)
                .blur(radius: useBlur ? 60 : 0)
                .clipped()
            Color.black.opacity(dim)
        }
    }
}
