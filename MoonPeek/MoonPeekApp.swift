//
//  MoonPeekApp.swift
//  MoonPeek
//

import SwiftUI
import SwiftData

@main
struct MoonPeekApp: App {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .dark

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Photo.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeMode.colorScheme)
                .task {
                    WatchPusher.shared.activate()
                    await FavoritesSnapshotSync.refresh(modelContext: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
