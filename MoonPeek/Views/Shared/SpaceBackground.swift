//
//  SpaceBackground.swift
//  MoonPeek
//

import SwiftUI

struct SpaceBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.08),
                    Color(red: 0.05, green: 0.06, blue: 0.14),
                    Color(red: 0.01, green: 0.01, blue: 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.indigo.opacity(0.35), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .blendMode(.plusLighter)

            RadialGradient(
                colors: [Color.purple.opacity(0.22), .clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 460
            )
            .blendMode(.plusLighter)

            Starfield()
                .opacity(0.55)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

private struct Starfield: View {
    private let seeds: [Star] = (0..<70).map { _ in
        Star(
            x: .random(in: 0...1),
            y: .random(in: 0...1),
            size: .random(in: 0.6...2.2),
            opacity: .random(in: 0.25...0.95)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(seeds) { star in
                    Circle()
                        .fill(.white)
                        .frame(width: star.size, height: star.size)
                        .opacity(star.opacity)
                        .position(
                            x: proxy.size.width * star.x,
                            y: proxy.size.height * star.y
                        )
                        .blur(radius: star.size > 1.6 ? 0.4 : 0)
                }
            }
        }
    }

    private struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: CGFloat
    }
}

#Preview {
    SpaceBackground()
}
