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
            // Always-present background so the view fills whatever frame the
            // parent proposes, even before/while the network image loads.
            Rectangle()
                .fill(Color.white.opacity(0.04))

            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: urlString) {
            isLoading = true
            uiImage = await ImageLoader.shared.image(for: urlString)
            isLoading = false
        }
    }

    var loadedImage: UIImage? { uiImage }
}
