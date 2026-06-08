//
//  FavoritesSnapshot.swift
//  MoonPeek (shared with MoonPeekWidget and MoonPeekWatch targets)
//
//  Add this file to the Target Membership of:
//    • MoonPeek (the iOS app)            — writer side
//    • MoonPeekWidget (Widget Extension) — reader, via App Group
//    • MoonPeekWatch  (watchOS app)      — reader, via WatchConnectivity
//
//  Replace `appGroupID` with your real App Group identifier once you've
//  added it in Signing & Capabilities on both the iOS app and the widget.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

// MARK: - Model

struct FavoriteEntry: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let note: String
    let dateTaken: Date?
    let thumbnailData: Data?

    var hasNote: Bool { !note.isEmpty }
}

struct FavoritesSnapshot: Codable, Hashable {
    let entries: [FavoriteEntry]
    let updatedAt: Date

    static let empty = FavoritesSnapshot(entries: [], updatedAt: .distantPast)
}

// MARK: - Storage (App Group container shared with the widget)

enum FavoritesSnapshotStore {
    /// ⚠️ Replace with your App Group identifier (e.g. "group.com.yourcompany.moonpeek").
    /// Must be enabled in Signing & Capabilities for BOTH the app and the widget targets.
    static let appGroupID = "group.com.chrisachinga.moonpeek"

    static let snapshotFilename = "favorites.json"

    static var snapshotURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(snapshotFilename)
    }

    static func read() -> FavoritesSnapshot {
        guard
            let url = snapshotURL,
            let data = try? Data(contentsOf: url),
            let snapshot = try? JSONDecoder().decode(FavoritesSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    @discardableResult
    static func write(_ snapshot: FavoritesSnapshot) -> Bool {
        guard let url = snapshotURL else {
            #if DEBUG
            print("[FavoritesSnapshotStore] no App Group container — set up App Group '\(appGroupID)' in Signing & Capabilities")
            #endif
            return false
        }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            #if DEBUG
            print("[FavoritesSnapshotStore] write failed: \(error.localizedDescription)")
            #endif
            return false
        }
    }
}

// MARK: - iOS-only: build snapshot from SwiftData + push everywhere

#if canImport(SwiftData) && os(iOS)
import SwiftData

@MainActor
enum FavoritesSnapshotSync {
    /// Re-snapshots all favorited photos, writes to the App Group, reloads widgets,
    /// and pushes to the paired watch (if any).
    static func refresh(modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<Photo>(predicate: #Predicate { $0.isFavorite == true })
        let favorites = (try? modelContext.fetch(descriptor)) ?? []

        var entries: [FavoriteEntry] = []
        entries.reserveCapacity(favorites.count)
        for photo in favorites {
            let thumb = await thumbnailJPEG(for: photo, maxSide: 240)
            entries.append(FavoriteEntry(
                id: photo.remoteID,
                title: photo.title,
                note: photo.note,
                dateTaken: photo.dateTaken,
                thumbnailData: thumb
            ))
        }

        let snapshot = FavoritesSnapshot(entries: entries, updatedAt: Date())
        FavoritesSnapshotStore.write(snapshot)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif

        WatchPusher.shared.send(snapshot)
    }

    private static func thumbnailJPEG(for photo: Photo, maxSide: CGFloat) async -> Data? {
        guard let img = await ImageLoader.shared.image(for: photo.remoteURL) else { return nil }
        let aspect = img.size.width / max(img.size.height, 1)
        let target: CGSize = aspect >= 1
            ? CGSize(width: maxSide, height: maxSide / aspect)
            : CGSize(width: maxSide * aspect, height: maxSide)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let rendered = renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - WatchConnectivity push (iOS side)

final class WatchPusher: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchPusher()

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        if session.activationState != .activated {
            session.activate()
        }
    }

    func send(_ snapshot: FavoritesSnapshot) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled else { return }
        do {
            let data = try JSONEncoder().encode(snapshot)
            try session.updateApplicationContext(["snapshot": data])
        } catch {
            #if DEBUG
            print("[WatchPusher] updateApplicationContext failed: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - WCSessionDelegate (no-ops on iOS side beyond activation)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
#endif
