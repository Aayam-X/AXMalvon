//
//  AXTabGroup.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXTabGroup: Codable {
    // Essentials
    var name: String
    var selectedIndex: Int = -1

    var tabs: [AXTab] = []
    
    // Customization
    var color: NSColor
    var icon: String = "square.3.layers.3d"

    init(name: String) {
        self.name = name
        self.color = .textBackgroundColor.withAlphaComponent(0.8)
    }

    // MARK: - Codeable Functions
    enum CodingKeys: String, CodingKey {
        case name, tabs, selectedIndex, color, icon
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try container.decode(String.self, forKey: .name)
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

        self.tabs = try container.decode([AXTab].self, forKey: .tabs)

        // Check if selectedIndex is safe or not
        if selectedIndex >= tabs.count {
            selectedIndex = 0
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
    static let webviewConfiguration = CodingUserInfoKey(
        rawValue: "webConfig")!
}
