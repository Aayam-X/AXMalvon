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
    func webContainerViewCreatesTabWithZeroTabs(with url: URL) -> AXTab {
        let tab = AXTab(
            url: url, title: "New Tab",
            dataStore: activeProfile.websiteDataStore,
            processPool: activeProfile.websiteProcessPool)
        currentTabGroup.addTab(tab)

        return tab
    }

    func webContainerViewDidSwitchToStartPage() {
        makeFirstResponder(layoutManager.searchButton.addressField)
    }

    func webContainerUserDidClickStartPageItem(_ tab: AXTab) {
        // Start button observation
        if let button = tabBarView.tabStackView.arrangedSubviews[
            currentTabGroup.selectedIndex] as? any AXTabButton
        {
            tab.startTitleObservation(for: button)
        }
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
        let tab = AXTab(createdPopupTab: config)
        currentTabGroup.addTab(tab)

        return tab.view! as! WKWebView
    }

    func webContainerViewFinishedLoading(webView: WKWebView) {
        // Update the search field address
        layoutManager.searchButton.fullAddress =
            layoutManager.containerView.currentPageAddress

        // Save to history
        if let historyManager = activeProfile.historyManager,
            let title = webView.title, let url = webView.url
        {
            let newItem = AXHistoryItem(
                title: title, address: url.absoluteString)

            historyManager.insert(item: newItem)
        }
    }
}
