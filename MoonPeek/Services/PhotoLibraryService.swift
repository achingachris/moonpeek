//
//  PhotoLibraryService.swift
//  MoonPeek
//

import Photos
import UIKit

enum PhotoLibraryError: LocalizedError {
    case accessDenied
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied: return "Photos access denied. Enable it in Settings."
        case .saveFailed: return "Could not save the image to Photos."
        }
    }
}

enum PhotoLibraryService {
    static func save(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.accessDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }
        } catch {
            throw PhotoLibraryError.saveFailed
        }
    }
}
