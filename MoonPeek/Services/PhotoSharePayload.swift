//
//  PhotoSharePayload.swift
//  MoonPeek
//

import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

struct PhotoSharePayload: Transferable {
    let image: Image
    let uiImage: UIImage
    let caption: String
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { payload in
            guard let data = payload.uiImage.jpegData(compressionQuality: 0.9) else {
                throw CocoaError(.fileWriteUnknown)
            }
            return data
        }
        .suggestedFileName { payload in
            let safe = payload.title.replacingOccurrences(of: "/", with: "_")
            return "\(safe.isEmpty ? "MoonPeek" : safe).jpg"
        }

        ProxyRepresentation(exporting: \.caption)
    }
}
