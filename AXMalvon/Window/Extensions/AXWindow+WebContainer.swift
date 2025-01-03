//
//  AXWindow+WebContainer.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import SwiftUI
import WebKit

extension AXWindow: AXWebContainerViewDelegate {
    func webContainerViewDidSwitchToStartPage() {
        makeFirstResponder(layoutManager.searchButton.addressField)
    }

    func webContainerViewRequestsCurrentTab(_ url: URL?) -> AXTab {
        let currentTabGroup = currentTabGroup

        if currentTabGroup.tabs.isEmpty {
            return currentTabGroup.addTab(url: url!, currentConfiguration)
        }

        return currentTabGroup.tabs[currentTabGroup.selectedIndex]
    }

    func webContainerViewChangedURL(to url: URL) {
        layoutManager.searchButton.fullAddress = url
    }

    func webContainerViewCloses() {
        currentTabGroup.removeCurrentTab()
    }

    func webContainerViewRequestsSidebar() -> NSView? {
        return layoutManager.layoutView
    }

    func webContainerViewCreatesPopupWebView(config: WKWebViewConfiguration)
        -> WKWebView
    {
        let newWebView = AXWebView(frame: .zero, configuration: config)
        let tab = AXTab(
            title: newWebView.title ?? "Untitled Popup", webView: newWebView)

        currentTabGroup.addTab(tab)

        return newWebView
    }

    func webContainerViewFinishedLoading(webView: WKWebView) {
        layoutManager.searchButton.fullAddress =
            layoutManager.containerView.currentPageAddress

        if let historyManager = activeProfile.historyManager,
            let title = webView.title, let url = webView.url
        {
            let newItem = AXHistoryItem(
                title: title, address: url.absoluteString)

            historyManager.insert(item: newItem)
        }
    }
}
