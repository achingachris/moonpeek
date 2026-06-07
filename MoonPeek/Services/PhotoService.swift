//
//  PhotoService.swift
//  MoonPeek
//

import Foundation
import SwiftData

nonisolated struct NASAImagesResponse: Decodable, Sendable {
    let collection: Collection
    struct Collection: Decodable, Sendable {
        let items: [Item]
    }
    struct Item: Decodable, Sendable {
        let data: [PhotoData]?
        let links: [Link]?
    }
    struct PhotoData: Decodable, Sendable {
        let nasa_id: String?
        let title: String?
        let description: String?
        let date_created: String?
    }
    struct Link: Decodable, Sendable {
        let href: String
        let rel: String?
        let render: String?
    }
}

enum PhotoServiceError: Error {
    case invalidURL
}

enum PhotoService {
    static func fetchPhotos(query: String = "Artemis II") async throws -> [Photo] {
        var components = URLComponents(string: "https://images-api.nasa.gov/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "media_type", value: "image")
        ]
        guard let url = components?.url else { throw PhotoServiceError.invalidURL }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(NASAImagesResponse.self, from: data)
        let isoFormatter = ISO8601DateFormatter()

        return decoded.collection.items.compactMap { item -> Photo? in
            guard
                let info = item.data?.first,
                let nasaID = info.nasa_id,
                let imageURL = item.links?.first?.href,
                !imageURL.isEmpty
            else { return nil }
            return Photo(
                remoteID: nasaID,
                remoteURL: imageURL,
                title: info.title ?? "Untitled",
                caption: info.description ?? "",
                dateTaken: info.date_created.flatMap { isoFormatter.date(from: $0) }
            )
        }
    }
}

@MainActor
enum PhotoCatalog {
    static func refresh(modelContext: ModelContext) async {
        do {
            let fresh = try await PhotoService.fetchPhotos()
            let existing = try modelContext.fetch(FetchDescriptor<Photo>())
            let existingIDs = Set(existing.map { $0.remoteID })
            for photo in fresh where !existingIDs.contains(photo.remoteID) {
                modelContext.insert(photo)
            }
            try modelContext.save()
        } catch {
            seedSamplesIfEmpty(modelContext: modelContext)
        }
    }

    static func seedSamplesIfEmpty(modelContext: ModelContext) {
        let existing = (try? modelContext.fetch(FetchDescriptor<Photo>())) ?? []
        guard existing.isEmpty else { return }
        for photo in Photo.sampleSeed {
            modelContext.insert(photo)
        }
        try? modelContext.save()
    }
}
