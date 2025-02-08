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
        let tab = AXTab(
            title: "New tab", configuration: activeProfile.baseConfiguration)
        malvonTabManager.addTab(tab)

        tab.url = url
        tab.webView?.load(URLRequest(url: url))
    }

    func searchBarUpdatesCurrentTab(with url: URL) {
        if malvonTabManager.isEmpty {
            malvonTabManager.addEmptyTab(config: activeProfile.baseConfiguration)
        }
        
        // Change current webview's url to new url
        layoutManager.containerView.loadURL(url: url)

        // self.contentView = containerView
        layoutManager.containerView.axWindowFirstResponder(self)
    }

    func searchBarCurrentWebsiteURL() -> String {
        // Returns the current web view's url
        return layoutManager.containerView.currentPageAddress?.absoluteString
            ?? ""
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
