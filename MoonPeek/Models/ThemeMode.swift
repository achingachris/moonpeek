//
//  ThemeMode.swift
//  MoonPeek
//

import SwiftUI

enum ThemeMode: CaseIterable {
    case light, dark, clear, tinted

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .clear: return "rectangle.on.rectangle.angled"
        case .tinted: return "paintpalette.fill"
        }
    }

    var label: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .clear: return "Clear"
        case .tinted: return "Tinted"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        default: return nil
        }
    }
}
