//
//  Photo.swift
//  MoonPeek
//

import Foundation
import SwiftData

@Model
final class Photo {
    var remoteID: String = ""
    var remoteURL: String = ""
    var title: String = ""
    var caption: String = ""
    var dateTaken: Date?
    var mission: String = "Artemis II"
    var isFavorite: Bool = false
    var localFilename: String?
    var note: String = ""
    var addedAt: Date = Date()

    init(
        remoteID: String,
        remoteURL: String,
        title: String,
        caption: String = "",
        dateTaken: Date? = nil,
        mission: String = "Artemis II",
        isFavorite: Bool = false,
        localFilename: String? = nil,
        note: String = ""
    ) {
        self.remoteID = remoteID
        self.remoteURL = remoteURL
        self.title = title
        self.caption = caption
        self.dateTaken = dateTaken
        self.mission = mission
        self.isFavorite = isFavorite
        self.localFilename = localFilename
        self.note = note
        self.addedAt = Date()
    }
}

extension Photo {
    static let sampleSeed: [Photo] = [
        Photo(
            remoteID: "sample-orion-1",
            remoteURL: "https://images-assets.nasa.gov/image/KSC-20221116-PH-KLS01_0086/KSC-20221116-PH-KLS01_0086~large.jpg",
            title: "Orion at Launch",
            caption: "Artemis I lifts off from Launch Complex 39B, paving the way for Artemis II.",
            dateTaken: ISO8601DateFormatter().date(from: "2022-11-16T00:00:00Z")
        ),
        Photo(
            remoteID: "sample-orion-2",
            remoteURL: "https://images-assets.nasa.gov/image/iss068e027836/iss068e027836~large.jpg",
            title: "Orion in Cislunar Space",
            caption: "Orion captures a view of the Moon and Earth during its mission."
        ),
        Photo(
            remoteID: "sample-orion-3",
            remoteURL: "https://images-assets.nasa.gov/image/KSC-20231103-PH-KLS01-0001/KSC-20231103-PH-KLS01-0001~large.jpg",
            title: "Artemis II Crew",
            caption: "The Artemis II crew prepares for humanity's return to the Moon."
        ),
        Photo(
            remoteID: "sample-orion-4",
            remoteURL: "https://images-assets.nasa.gov/image/KSC-20240403-PH-KLS01-0002/KSC-20240403-PH-KLS01-0002~large.jpg",
            title: "SLS Rocket Stacking",
            caption: "Space Launch System components arrive for Artemis II assembly."
        )
    ]
}
