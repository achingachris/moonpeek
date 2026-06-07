//
//  FavoritesView.swift
//  MoonPeek
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(
        filter: #Predicate<Photo> { $0.isFavorite == true },
        sort: \Photo.addedAt,
        order: .reverse
    ) private var favorites: [Photo]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(favorites) { photo in
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

            if favorites.isEmpty {
                EmptyStateView(
                    title: "No Favorites Yet",
                    message: "Tap the heart on any Artemis II photo to save it here.",
                    systemImage: "heart"
                )
            }
        }
        .navigationTitle("Favorites")
    }
}
