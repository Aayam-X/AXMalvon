//
//  AXTabButtonProtocol.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
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

extension AXTabButton {
    public func startObserving() {
        guard let webView = tab._webView else { return }

        createObserver(webView)
    }

    func forceCreateWebview() {
        let webView = tab.webView
        createObserver(webView)
    }

    func createObserver(_ webView: AXWebView) {
        tab.startTitleObservation(for: self)
    }
}
