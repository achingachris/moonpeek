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
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var filteredPhotos: [Photo] {
        guard !searchText.isEmpty else { return photos }
        let needle = searchText.lowercased()
        return photos.filter {
            $0.title.lowercased().contains(needle)
            || $0.caption.lowercased().contains(needle)
        }
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredPhotos) { photo in
                        NavigationLink(value: photo) {
                            PhotoGridItem(photo: photo)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .refreshable { await refresh() }

            if photos.isEmpty {
                if isRefreshing {
                    ProgressView()
                        .tint(.white)
                } else {
                    EmptyStateView(
                        title: "No Photos Yet",
                        message: "Pull down to load the latest Artemis II imagery from NASA.",
                        systemImage: "moon.stars"
                    )
                }
            }
        }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search Artemis II")
        .task {
            guard !hasLoadedOnce else { return }
            hasLoadedOnce = true
            await refresh()
        }
    }

    private func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await PhotoCatalog.refresh(modelContext: modelContext)
        PhotoCatalog.seedSamplesIfEmpty(modelContext: modelContext)
    }
}
