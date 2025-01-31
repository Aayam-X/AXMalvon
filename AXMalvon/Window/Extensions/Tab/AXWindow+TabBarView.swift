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

        layoutManager.searchButton.fullAddress = nil

        if tabAt == -1 {
            layoutManager.containerView.removeAllWebViews()
        } else {
            layoutManager.containerView.updateView(tabAt: tabAt)
        }
    }

    func tabBarActiveTabTitleChanged(to title: String) {
        layoutManager.containerView.websiteTitleLabel.stringValue = title
    }
}
