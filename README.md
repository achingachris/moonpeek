# MoonPeek

An iOS app for browsing NASA Artemis II mission photography. Browse high-resolution mission images, save favorites, add personal notes, and set any photo as your wallpaper.

## Features

- **Explore** — Searchable gallery of Artemis II mission photos pulled from the NASA Images API
- **Favorites** — Save photos and revisit them in a dedicated filtered view
- **Notes** — Attach personal notes to any photo; browse all annotated photos in one place
- **Wallpaper** — Preview and export any photo as a lock screen or home screen wallpaper at full resolution (1170×2532)
- **Share** — Share photos, notes, or a combined photo+note card (rendered at 1080×1350)
- **Offline caching** — Images are cached to memory and disk so previously viewed photos load instantly

## Requirements

- Xcode 15+
- iOS 18+
- No external dependencies — uses Swift, SwiftUI, SwiftData, and Photos frameworks only

## Getting Started

1. Clone the repo
2. Open `MoonPeek.xcodeproj` in Xcode
3. Select a simulator or device running iOS 18+
4. Build and run (`⌘R`)

No package installation or setup steps required.

## Architecture

The app uses a SwiftUI + SwiftData stack with an actor-based image caching layer.

- `MoonPeekApp` — configures the `ModelContainer` and passes it to all tabs
- `PhotoService` — fetches photos from the NASA Images API; falls back to bundled sample data when offline
- `ImageLoader` — Swift actor managing a two-tier cache (in-memory `NSCache` + disk)
- `Photo` — the single SwiftData model; mutable fields are `isFavorite`, `note`, and `localFilename`
- Views use `@Query` with predicates to filter data (favorites, notes); edits go through `@Bindable`

See [CLAUDE.md](CLAUDE.md) for a deeper architecture reference.

## Permissions

- **Photo Library** (`NSPhotoLibraryAddUsageDescription`) — required to save wallpapers and downloaded images to the Photos app
