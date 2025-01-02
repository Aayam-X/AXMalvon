//
//  AXWindow+SearchBar.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import SecurityInterface

extension AXWindow: AXSidebarSearchButtonDelegate {
    func searchBarCreatesNewTab(with url: URL) {
        let webView = AXWebView(
            frame: .zero, configuration: currentConfiguration)
        webView.load(URLRequest(url: url))

        currentTabGroup.addTab(
            .init(title: webView.title ?? "Untitled Tab", webView: webView))

        // self.contentView = containerView
    }

    func searchBarUpdatesCurrentTab(with url: URL) {
        // Change current webview's url to new url
        layoutManager.containerView.loadURL(url: url)

        // self.contentView = containerView
        layoutManager.containerView.axWindowFirstResponder(self)
    }

    func searchBarCurrentWebsiteURL() -> String {
        // Returns the current web view's url
        return layoutManager.containerView.currentPageAddress?.absoluteString ?? ""
    }

    func sidebarSearchButtonSearchesFor(_ url: URL) {
        searchBarUpdatesCurrentTab(with: url)
    }

    func lockClicked() {
//        guard let webView = layoutManager.containerView.currentWebView,
//            let serverTrust = webView.serverTrust
//        else { return }
//
//        SFCertificateTrustPanel.shared().beginSheet(
//            for: self, modalDelegate: nil, didEnd: nil, contextInfo: nil,
//            trust: serverTrust, message: "TLS Certificate Details")
    }

    func sidebarSearchButtonRequestsHistoryManager() -> AXHistoryManager? {
        activeProfile.historyManager
    }
}
