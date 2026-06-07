//
//  DownloadToast.swift
//  MoonPeek
//

import SwiftUI

struct ToastMessage: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    var progress: Double?
}

struct DownloadToast: View {
    let message: ToastMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            Text(message.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            if let progress = message.progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(width: 80)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: Capsule())
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 6)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

extension View {
    /// Anchored toast overlay used by the photo detail and settings screens.
    func downloadToast(_ binding: Binding<ToastMessage?>) -> some View {
        overlay(alignment: .bottom) {
            if let message = binding.wrappedValue {
                DownloadToast(message: message)
                    .padding(.bottom, 110)
                    .padding(.horizontal, 24)
                    .id(message.id)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: binding.wrappedValue)
    }
}
