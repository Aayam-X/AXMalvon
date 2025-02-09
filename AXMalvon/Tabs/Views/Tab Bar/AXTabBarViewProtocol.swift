//
//  AXTabBarViewProtocol.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-08.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

protocol AXTabBarViewDelegate: AnyObject {
    /// Called when the user presses on a tab
    func tabBarSwitchedTo(_ tabButton: AXTabButton)
    
    /// Called when the user presses (clicks) on the close button within the tab.
    func tabBarShouldClose(_ tabButton: AXTabButton) -> Bool
    
    /// Called when the tab at a specified index is closed.
    func tabBarDidClose(_ tabAt: Int)
}

extension AXTabBarViewDelegate {
    func tabBarShouldClose(_ tabButton: AXTabButton) -> Bool {
        true
    }
    
    func tabBarDidClose(_ tabAt: Int) {}
}

protocol AXTabBarViewTemplate: AnyObject, NSView, AXTabButtonDelegate {
    var delegate: AXTabBarViewDelegate? { get set }

    /// This value represents the currently highlighted tab item.
    var selectedTabIndex: Int { get set }
    var tabStackView: NSStackView { get }

    init()
    
    @discardableResult
    func addTabButton() -> AXTabButton
    func removeTabButton(at index: Int)
    
    func tabButton(at index: Int) -> AXTabButton
}

extension AXTabBarViewTemplate {
    // Gets rid of all the tabs, and replaces them with new ones
    // I did this so that rather than having 5 different tabViews in the user's memory, there is only a single tabView.
    // And I believe this approach is a really nice one as it helps with battery life and low memory consumption.
    
    /// Similar to NSTableView.reload()
    func updateTabGroup(_ newTabGroup: AXTabGroup) {
        for button in self.tabStackView.arrangedSubviews {
            button.removeFromSuperview()
        }

        for _ in newTabGroup.tabs {
            addTabButton()
        }
        
        if !newTabGroup.tabs.isEmpty {
            let button = tabStackView.arrangedSubviews[newTabGroup.selectedIndex] as! AXTabButton
            button.isSelected = true
        }
    }
}
