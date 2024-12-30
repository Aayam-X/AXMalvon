//
//  AXWindow+SearchBar.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
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
    }

    func searchBarUpdatesCurrentTab(with url: URL) {
        // Change current webview's url to new url
        self.containerView.currentWebView?.load(URLRequest(url: url))

        makeFirstResponder(self.containerView.currentWebView)
    }

    func searchBarCurrentWebsiteURL() -> String {
        // Returns the current web view's url
        self.containerView.currentWebView?.url?.absoluteString ?? ""
    }

    func sidebarSearchButtonSearchesFor(_ url: URL) {
        searchBarUpdatesCurrentTab(with: url)
    }

    func lockClicked() {
        guard let webView = containerView.currentWebView,
            let serverTrust = webView.serverTrust
        else { return }

        SFCertificateTrustPanel.shared().beginSheet(
            for: self, modalDelegate: nil, didEnd: nil, contextInfo: nil,
            trust: serverTrust, message: "TLS Certificate Details")
    }

    func sidebarSearchButtonRequestsHistoryManager() -> AXHistoryManager {
        activeProfile.historyManager
    }
}
