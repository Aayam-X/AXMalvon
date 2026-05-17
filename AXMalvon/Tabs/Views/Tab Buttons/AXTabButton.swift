//
//  AXTabButtonProtocol.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

@MainActor
protocol AXTabButtonDelegate: AnyObject {
    /// Called when the user selects (clicks) a tab button
    func tabButtonDidSelect(_ tabButton: AXTabButton)

    /// Called when the user presses the close button on a tab
    func tabButtonDidRequestClose(_ tabButton: AXTabButton)
}

protocol AXTabButton: AnyObject, NSButton {
    /// Conformers MUST declare this property as `weak` — the delegate is
    /// the tab bar that owns the button.
    var delegate: AXTabButtonDelegate? { get set }

    var favicon: NSImage? { get set }
    var webTitle: String { get set }

    var isSelected: Bool { get set }

    /// Tab-group accent. Used to tint the selection-state glass highlight.
    /// Nil falls back to a default system glass appearance.
    var accentColor: NSColor? { get set }

    init()
}

struct AXTabButtonConstants {
    static let defaultFavicon = NSImage(
        systemSymbolName: "square.fill", accessibilityDescription: nil)
    static let defaultFaviconSleep = NSImage(
        systemSymbolName: "moon.fill", accessibilityDescription: nil)
    static let defaultCloseButton = NSImage(
        systemSymbolName: "xmark", accessibilityDescription: nil)
}
