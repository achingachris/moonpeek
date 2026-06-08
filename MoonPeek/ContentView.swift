//
//  ContentView.swift
//  MoonPeek
//

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case explore, favorites, notes, settings
}

struct ContentView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var selectedTab: AppTab = .explore

    var body: some View {
        Group {
            if hasOnboarded {
                mainTabs
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Explore", systemImage: "sparkles", value: AppTab.explore) {
                NavigationStack {
                    ExploreView()
                        .navigationDestination(for: Photo.self) { PhotoDetailView(photo: $0) }
                }
            }

            Tab("Favorites", systemImage: "heart", value: AppTab.favorites) {
                NavigationStack {
                    FavoritesView()
                        .navigationDestination(for: Photo.self) { PhotoDetailView(photo: $0) }
                }
            }

            Tab("Notes", systemImage: "square.and.pencil", value: AppTab.notes) {
                NavigationStack {
                    NotesView()
                        .navigationDestination(for: Photo.self) { PhotoDetailView(photo: $0) }
                }
            }

            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Photo.self, inMemory: true)
}
