# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MoonPeek is an iOS app showcasing NASA Artemis II mission imagery. It uses SwiftUI + SwiftData with no external dependencies — pure Apple frameworks only.

## Build & Run

Open `MoonPeek.xcodeproj` in Xcode 15+ and run on an iOS 18+ simulator or device. There are no build scripts, SPM packages, or CocoaPods — everything uses system frameworks.

To build from the command line:
```
xcodebuild -project MoonPeek.xcodeproj -scheme MoonPeek -destination 'platform=iOS Simulator,name=iPhone 16' build
```

There are no test targets in the project.

## Architecture

**Tab-based SwiftUI app** with four tabs defined in `ContentView.swift`: Explore, Favorites, Notes, Settings. All tabs share a single `ModelContainer` (SwiftData) initialized in `MoonPeekApp.swift`.

**Data flow:**
1. `PhotoService` fetches NASA Images API → decodes into `Photo` SwiftData models
2. `PhotoCatalog` (in PhotoService.swift) manages refresh lifecycle with sample-data fallback
3. Views use `@Query` with predicates for filtering (favorites, notes)
4. `ImageLoader` (an actor) handles async image fetching with dual-tier caching: `NSCache` in memory + disk under `~/Library/Caches/MoonPeekImages`

**Key build settings:**
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all types are implicitly `@MainActor` unless marked otherwise
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`

## Key Patterns

**SwiftData model** (`Photo.swift`): Uses `@Model`, mutations happen via `@Bindable` in views. `isFavorite`, `note`, and `localFilename` are the mutable fields users interact with.

**ImageLoader actor**: Deduplicates in-flight requests. Disk filenames are base64-encoded URLs with `/`, `+`, `=` replaced. Always go through `ImageLoader.shared` for image fetching.

**Glass morphism**: `.glassEffect(_:in:)` modifier and `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` are used throughout for the frosted-glass aesthetic. `SpaceBackground` (starfield + radial gradients) is the standard screen background.

**Sharing/Export**: `PhotoSharePayload` implements `Transferable` for native `ShareLink`. Combined photo+note cards are rendered at 1080×1350 via `ImageRenderer`. Wallpaper exports render at 1170×2532 (2× resolution).

**Toast notifications**: Use `.downloadToast(_:)` view extension (defined in `DownloadToast.swift`) — it overlays a toast at screen bottom.

## Structure

```
MoonPeek/
├── MoonPeekApp.swift          # App entry, ModelContainer setup
├── ContentView.swift          # TabView with 4 tabs
├── Models/                    # SwiftData model + ThemeMode enum
├── Services/                  # API, image caching, photo library, sharing
└── Views/
    ├── Gallery/               # Explore tab — searchable 2-column grid
    ├── Detail/                # Full-screen viewer, zoom, notes, share, wallpaper
    ├── Favorites/             # Favorites grid + Notes list
    ├── Settings/              # Cache management, app info
    └── Shared/                # Reusable components (background, buttons, toast)
```

## Important Notes

- The app enforces dark color scheme globally (`.preferredColorScheme(.dark)` in `MoonPeekApp`).
- `MoonPeek.entitlements` includes CloudKit and push notifications (development) — these are configured but not actively used in current code.
- `Photo.sampleSeed` provides 4 hardcoded NASA photos used as fallback when the API is unavailable.
- `PhotoDetailView` handles complex gesture state: pinch-to-zoom (0.6×–4×) and double-tap toggle (1×/2×) with separate `currentScale` / `finalScale` state vars to avoid gesture conflicts.
