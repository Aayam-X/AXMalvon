//
//  AXTabButtonProtocol.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

protocol AXTabButtonDelegate: AnyObject {
    func tabButtonDidSelect(_ tabButton: AXTabButton)
    func tabButtonWillClose(_ tabButton: AXTabButton)
    func tabButtonActiveTitleChanged(
        _ newTitle: String, for tabButton: AXTabButton)

    func tabButtonDeactivatedWebView(_ tabButton: AXTabButton)
}

protocol AXTabButton: AnyObject, NSButton {
    var tab: AXTab! { get set }
    var delegate: AXTabButtonDelegate? { get set }

    var isSelected: Bool { get set }

    var favicon: NSImage? { get set }
    var webTitle: String { get set }

    init(tab: AXTab!)
}

struct AXTabButtonConstants {
    static let defaultFavicon = NSImage(
        systemSymbolName: "square.fill", accessibilityDescription: nil)
    static let defaultFaviconSleep = NSImage(
        systemSymbolName: "moon.fill", accessibilityDescription: nil)
    static let defaultCloseButton = NSImage(
        systemSymbolName: "xmark", accessibilityDescription: nil)
}

extension AXTabButton {
    public func startObserving() {
        guard let webView = tab?.view as? AXWebView else { return }

        createObserver(webView)
    }

    func forceCreateWebview() {
        if let webView = tab.webView {
            createObserver(webView)
        }
    }

    func createObserver(_ webView: AXWebView) {
        mxPrint(#function, "CALLEDDDD 1111")
        tab.startTitleObservation(for: self)
    }
}
