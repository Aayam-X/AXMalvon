//
//  AXTabGroup.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

/// Runtime tab-group: an ordered list of ``AXTab`` plus presentation state
/// (name, color, SF Symbol icon). Persistence happens via
/// ``AXProfile/saveTabGroups()``, which writes a snapshot into SwiftData.
@MainActor
final class AXTabGroup {
    var name: String
    var selectedIndex: Int = -1

    var tabs: [AXTab] = []

    var color: NSColor
    var icon: String = "square.3.layers.3d"

    init(name: String) {
        self.name = name
        self.color = .textBackgroundColor.withAlphaComponent(0.8)
    }
}
