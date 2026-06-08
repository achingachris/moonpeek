//
//  GalleryView.swift
//  MoonPeek
//
//  Hosts ExploreView — the primary tab.
//

import SwiftUI
import SwiftData

struct ExploreView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Photo.addedAt, order: .reverse) private var photos: [Photo]

    @State private var isRefreshing = false
    @State private var hasLoadedOnce = false
    @State private var loadError: String?

    @AppStorage("userNickname") private var nickname: String = ""

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !nickname.isEmpty {
                        greeting
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(photos) { photo in
                            NavigationLink(value: photo) {
                                PhotoGridItem(photo: photo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .refreshable { await refresh() }

            if photos.isEmpty {
                if isRefreshing {
                    ProgressView()
                        .tint(.white)
                } else if let loadError {
                    EmptyStateView(
                        title: "Couldn't Reach the Bucket",
                        message: loadError,
                        systemImage: "exclamationmark.icloud"
                    )
                } else {
                    EmptyStateView(
                        title: "No Photos Yet",
                        message: "Pull down to load the latest Artemis imagery.",
                        systemImage: "moon.stars"
                    )
                }
            }
        }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.large)
        .task {
            guard !hasLoadedOnce else { return }
            hasLoadedOnce = true
            PhotoCatalog.purgeLegacySamples(modelContext: modelContext)
            await refresh()
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Welcome back")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Hey, \(nickname) 👋")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func refresh() async {
        isRefreshing = true
        loadError = nil
        defer { isRefreshing = false }
        do {
            try await PhotoCatalog.refresh(modelContext: modelContext)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
