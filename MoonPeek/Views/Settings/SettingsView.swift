//
//  SettingsView.swift
//  MoonPeek
//

import SwiftUI
import SwiftData

enum DownloadQuality: String, CaseIterable, Identifiable {
    case optimized, original

    var id: String { rawValue }
    var label: String { self == .optimized ? "Optimized" : "Original" }
    var description: String {
        self == .optimized
        ? "Smaller files for fast sharing."
        : "Full-resolution NASA imagery."
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var photos: [Photo]

    @AppStorage("downloadQuality") private var downloadQuality: DownloadQuality = .optimized
    @AppStorage("themeMode") private var themeMode: ThemeMode = .dark
    @AppStorage("userNickname") private var nickname: String = ""

    @State private var cacheSize: Int64 = 0
    @State private var toast: ToastMessage?

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(spacing: 18) {
                    panel(title: "You", systemImage: "person.crop.circle") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nickname")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            TextField("Your nickname", text: $nickname)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .padding(12)
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }

                    panel(title: "Appearance", systemImage: "paintbrush") {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("Theme", selection: $themeMode) {
                                ForEach(ThemeMode.allCases) { mode in
                                    Label(mode.label, systemImage: mode.icon).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    panel(title: "Downloads", systemImage: "arrow.down.circle") {
                        VStack(alignment: .leading, spacing: 14) {
                            Picker("Download quality", selection: $downloadQuality) {
                                ForEach(DownloadQuality.allCases) { quality in
                                    Text(quality.label).tag(quality)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text(downloadQuality.description)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    panel(title: "Storage", systemImage: "internaldrive") {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Image cache")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(formattedSize(cacheSize))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }

                            Button(role: .destructive, action: clearCache) {
                                Label("Clear Cache", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)

                            Button(role: .destructive, action: clearSaved) {
                                Label("Forget Saved Photos", systemImage: "rectangle.stack.badge.minus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                        }
                    }

                    panel(title: "About", systemImage: "info.circle") {
                        VStack(alignment: .leading, spacing: 12) {
                            row("Imagery", value: "NASA Images Library")
                            row("Mission", value: "Artemis II")
                            row("Version", value: appVersion)

                            Text("MoonPeek does not collect personal data. Photos and notes are stored on-device only.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.top, 6)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
        .navigationTitle("Settings")
        .task { await refreshCacheSize() }
        .downloadToast($toast)
    }

    // MARK: - Components

    @ViewBuilder
    private func panel<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.primary)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func refreshCacheSize() async {
        cacheSize = await ImageLoader.shared.diskCacheSize()
    }

    private func clearCache() {
        Task {
            let freed = await ImageLoader.shared.clearCache()
            await refreshCacheSize()
            toast = ToastMessage(
                title: "Cleared \(formattedSize(freed))",
                icon: "checkmark.circle.fill"
            )
            try? await Task.sleep(for: .seconds(2.4))
            toast = nil
        }
    }

    private func clearSaved() {
        for photo in photos where photo.localFilename != nil {
            photo.localFilename = nil
        }
        try? modelContext.save()
        toast = ToastMessage(title: "Saved photos forgotten", icon: "checkmark.circle.fill")
        Task {
            try? await Task.sleep(for: .seconds(2.4))
            toast = nil
        }
    }

    private func formattedSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(for: Photo.self, inMemory: true)
}
