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
    func tabBarWillDelete(tab: AXTab) {
        if let url = tab.url {
            activeProfile.historyManager?.recentlyClosedTabs.append(url)
        }
    }

    func tabBarSwitchedTo(tabAt: Int) {
        if tabAt == -1 {
            layoutManager.containerView.removeAllWebViews()
            layoutManager.searchButton.fullAddress = nil
        } else {
            let tab = currentTabGroup.tabs[tabAt]
            layoutManager.searchButton.fullAddress = tab.url ?? nil
            layoutManager.containerView.selectTabViewItem(at: tabAt)
        }
    }

    func tabBarActiveTabTitleChanged(to title: String) {
        //layoutManager.containerView.websiteTitleLabel.stringValue = title
    }
}
