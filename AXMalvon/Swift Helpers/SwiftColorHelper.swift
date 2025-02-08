//
//  SwiftColorHelper.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-07.
//

import AppKit

// MARK: - NSColor Hex Conversion
extension NSColor {
    convenience init(hex: String) {
        let trimmedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexString =
            trimmedHex.hasPrefix("#")
            ? String(trimmedHex.dropFirst()) : trimmedHex

        guard let hexValue = UInt64(hexString, radix: 16) else {
            self.init(white: 0, alpha: 1)  // Default to black if invalid
            return
        }

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        switch hexString.count {
        case 6:  // #RRGGBB
            red = CGFloat((hexValue >> 16) & 0xFF) / 255.0
            green = CGFloat((hexValue >> 8) & 0xFF) / 255.0
            blue = CGFloat(hexValue & 0xFF) / 255.0
            alpha = 1.0
        case 8:  // #RRGGBBAA
            red = CGFloat((hexValue >> 24) & 0xFF) / 255.0
            green = CGFloat((hexValue >> 16) & 0xFF) / 255.0
            blue = CGFloat((hexValue >> 8) & 0xFF) / 255.0
            alpha = CGFloat(hexValue & 0xFF) / 255.0
        default:
            self.init(white: 0, alpha: 1)  // Default to black if invalid
            return
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    func toHex(includeAlpha: Bool = true) -> String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }

        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)
        let alpha = components.count >= 4 ? Int(components[3] * 255) : 255

        if includeAlpha {
            return String(format: "%02X%02X%02X%02X", red, green, blue, alpha)
        } else {
            return String(format: "%02X%02X%02X", red, green, blue)
        }
    }

    func systemAppearanceAdjustedColor() -> NSColor {
        // Convert color to a color space that supports RGB components.
        guard let rgbColor = self.usingColorSpace(.sRGB) else {
            return self  // Return original color if conversion fails
        }

        // Extract RGB components.
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Check if the color is (almost) white.
        if red >= 0.99 && green >= 0.99 && blue >= 0.99 {
            return NSColor.black.withAlphaComponent(alpha)
        }

        // Check if the color is (almost) black.
        if red <= 0.01 && green <= 0.01 && blue <= 0.01 {
            return NSColor.white.withAlphaComponent(alpha)
        }

        // Determine if the app is in Dark Mode.
        let isDarkMode =
            NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
            == .darkAqua

        if isDarkMode {
            return rgbColor.withAlphaComponent(0.9).shadow(withLevel: 0.1)
                ?? rgbColor
        } else {
            return rgbColor.withAlphaComponent(0.9).highlight(withLevel: 0.1)
                ?? rgbColor
        }
    }
}
