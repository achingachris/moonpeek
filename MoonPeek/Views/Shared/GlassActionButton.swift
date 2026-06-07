//
//  GlassActionButton.swift
//  MoonPeek
//

import SwiftUI

/// A circular Liquid Glass icon button used in floating toolbars.
struct GlassActionButton: View {
    let systemImage: String
    var label: String
    var tint: Color = .white
    var isProminent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(isProminent ? .white : tint)
                .contentShape(Circle())
        }
        .buttonStyle(GlassIconButtonStyle(isProminent: isProminent))
        .accessibilityLabel(label)
    }
}

private struct GlassIconButtonStyle: ButtonStyle {
    let isProminent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Group {
                    if isProminent {
                        Circle().fill(Color.accentColor)
                    }
                }
            )
            .glassEffect(isProminent ? .regular : .clear, in: Circle())
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        SpaceBackground()
        HStack(spacing: 14) {
            GlassActionButton(systemImage: "heart", label: "Favorite") {}
            GlassActionButton(systemImage: "square.and.arrow.down", label: "Save") {}
            GlassActionButton(systemImage: "square.and.arrow.up", label: "Share", isProminent: true) {}
        }
    }
}
