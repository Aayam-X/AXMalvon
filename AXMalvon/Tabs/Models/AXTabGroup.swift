//
//  AXTabGroup.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//

import AppKit
import WebKit

class AXTabGroup: Codable {
    // Essentials
    var name: String
    var tabs: [AXTab] = []
    var selectedIndex: Int = -1

    var tabBarView: AXTabBarViewTemplate?

    // Customization
    var color: NSColor

    var icon: String = "square.3.layers.3d"

    init(name: String) {
        self.name = name
        self.color = .textBackgroundColor.withAlphaComponent(0.8)
    }

    // MARK: - Tab Functions
    func addTab(_ tab: AXTab) {
        tabs.append(tab)
        tabBarView?.addTabButton(for: tab)  // Add button to tab bar view
    }

    func addEmptyTab(configuration: WKWebViewConfiguration) {
        let tab = AXTab(
            title: "New Tab",
            webView: AXWebView(frame: .zero, configuration: configuration))
        addTab(tab)
    }

    func switchTab(to: Int) {
        guard selectedIndex != to else { return }

        let previousIndex = selectedIndex
        self.selectedIndex = to

        switchTab(from: previousIndex, to: to)
    }

    func switchTab(from: Int, to: Int) {
        // Logic for switching tabs
        selectedIndex = to
        tabBarView?.updateTabSelection(from: from, to: to)  // Notify view
    }

    func removeTab(_ at: Int) {
        tabs.remove(at: at)
        tabBarView?.removeTabButton(at: at)
    }

    func removeCurrentTab() {
        removeTab(selectedIndex)
    }

    // MARK: - Codeable Functions
    enum CodingKeys: String, CodingKey {
        case name, tabs, selectedIndex, color, icon
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try container.decode(String.self, forKey: .name)
        self.tabs = try container.decode([AXTab].self, forKey: .tabs)
        self.selectedIndex = try container.decode(
            Int.self, forKey: .selectedIndex)
        self.icon =
            (try? container.decode(String.self, forKey: .icon))
            ?? "square.3.layers.3d"

        // Decode `color` as hex string and convert to `NSColor`
        if let colorHex = try container.decodeIfPresent(
            String.self, forKey: .color)
        {
            self.color = NSColor(hex: colorHex)
        } else {
            self.color = .systemMint.withAlphaComponent(0.8)
        }

        mxPrint("DECODED TAB VIEW WITH \(tabs.count)")
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(tabs, forKey: .tabs)
        try container.encode(selectedIndex, forKey: .selectedIndex)
        try container.encode(icon, forKey: .icon)

        // Encode `color` as hex string
        try container.encode(color.toHex(), forKey: .color)
    }
}

// Define a custom key for userInfo.
extension CodingUserInfoKey {
    static let webConfiguration = CodingUserInfoKey(
        rawValue: "webConfiguration")!
}

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
}
