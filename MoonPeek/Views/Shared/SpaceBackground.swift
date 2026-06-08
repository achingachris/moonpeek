//
//  SpaceBackground.swift
//  MoonPeek
//

import SwiftUI

struct SpaceBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                darkSpace
            } else {
                lightSky
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Dark (deep space)

    private var darkSpace: some View {
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

            Starfield(tint: .white, opacityRange: 0.25...0.95)
                .opacity(0.55)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Light (daylight sky)

    private var lightSky: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.96, blue: 1.00),
                    Color(red: 0.89, green: 0.93, blue: 0.99),
                    Color(red: 0.96, green: 0.94, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.blue.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )

            RadialGradient(
                colors: [Color.purple.opacity(0.14), .clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 460
            )

            Starfield(tint: Color.blue.opacity(0.55), opacityRange: 0.15...0.55)
                .opacity(0.6)
                .allowsHitTesting(false)
        }
    }
}

private struct Starfield: View {
    let tint: Color
    let opacityRange: ClosedRange<CGFloat>

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
                        .fill(tint)
                        .frame(width: star.size, height: star.size)
                        .opacity(scaleOpacity(star.opacity))
                        .position(
                            x: proxy.size.width * star.x,
                            y: proxy.size.height * star.y
                        )
                        .blur(radius: star.size > 1.6 ? 0.4 : 0)
                }
            }
        }
    }

    private func scaleOpacity(_ raw: CGFloat) -> CGFloat {
        let lo = opacityRange.lowerBound
        let hi = opacityRange.upperBound
        return lo + (hi - lo) * raw
    }

    private struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: CGFloat
    }
}

#Preview("Dark") {
    SpaceBackground().preferredColorScheme(.dark)
}

#Preview("Light") {
    SpaceBackground().preferredColorScheme(.light)
}
