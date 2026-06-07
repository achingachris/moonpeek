//
//  RemoteImageView.swift
//  MoonPeek
//

import SwiftUI

struct RemoteImageView: View {
    let urlString: String
    var contentMode: ContentMode = .fill

    @State private var uiImage: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Rectangle()
                    .fill(.ultraThinMaterial)
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task(id: urlString) {
            isLoading = true
            uiImage = await ImageLoader.shared.image(for: urlString)
            isLoading = false
        }
    }

    var loadedImage: UIImage? { uiImage }
}
