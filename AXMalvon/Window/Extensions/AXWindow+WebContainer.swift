//
//  AXWindow+WebContainer.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit
import SwiftUI

extension AXWindow: AXWebContainerViewDelegate {
    func webContainerSwitchedToEmptyWebView() {
        // TODO: Display Bookmarks View
        self.makeFirstResponder(layoutManager.searchButton.addressField)
        self.containerView.removeFromSuperview()

        var newTabView = AXNewTabView()
        newTabView.delegate = self
        let hostingView = NSHostingView(rootView: newTabView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // Set the hosting view directly as the content view
        self.contentView = hostingView

        // Add constraints to make the hosting view fill the window
        if let contentView = self.contentView {
            NSLayoutConstraint.activate([
                hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
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

    func webContainerViewCreatesPopupWebView(config: WKWebViewConfiguration) -> WKWebView {
        let newWebView = AXWebView(frame: .zero, configuration: config)
        let tab = AXTab(
            title: newWebView.title ?? "Untitled Popup", webView: newWebView)

        currentTabGroup.addTab(tab)

        return newWebView
    }

    func webContainerViewFinishedLoading(webView: WKWebView) {
        layoutManager.searchButton.fullAddress =
            containerView.currentWebView?.url

        if let historyManager = activeProfile.historyManager, let title = webView.title, let url = webView.url {
            let newItem = AXHistoryItem(
                title: title, address: url.absoluteString)

            historyManager.insert(item: newItem)
        }
    }
}

extension AXWindow: AXNewTabViewDelegate {
    func didClickVisitedSite(_ site: URL) {
        self.searchBarUpdatesCurrentTab(with: site)
        self.contentView = containerView
    }

    func didSearchFor(_ query: String) {
        mxPrint("Not supported yet")
    }
}
