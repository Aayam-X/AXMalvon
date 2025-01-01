//
//  AXWindow+TabBarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

extension AXWindow: AXTabBarViewDelegate {
    func tabBarSwitchedTo(tabAt: Int) {
        let tabGroup = currentTabGroup
        let tabs = tabGroup.tabs

        layoutManager.searchButton.addressField.stringValue = ""

        if tabAt == -1 {
            containerView.removeAllWebViews()
        } else {
            containerView.updateView(webView: tabs[tabAt].webView)
        }
    }

    func tabBarActiveTabTitleChanged(to title: String) {
        containerView.websiteTitleLabel.stringValue = title
    }

    func tabBarDeactivatedTab() -> WKWebViewConfiguration? {
        return activeProfile.configuration
    }
}
