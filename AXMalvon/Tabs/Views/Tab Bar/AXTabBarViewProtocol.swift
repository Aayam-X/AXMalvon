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

    var selectedTabIndex: Int
    var tabStackView: NSStackView { get set }

    init()
    
    func addTabButton()
    func removeTabButton(at index: Int)
    func switchToTab(at index: Int)
    
    func updateButton(title: String, at index: Int)
    func updateButton(icon: NSImage, at index: Int)
}

//extension AXTabBarViewTemplate {
//    // Similar to NSTableView.reload() function
//    // Gets rid of all the tabs, and replaces them with new ones
//    // I did this so that rather than having 5 different tabViews in the user's memory, there is only a single tabView.
//    // And I believe this approach is a really nice one as it helps with battery life and low memory consumption.
//    func updateTabGroup(_ newTabGroup: AXTabGroup) {
//        newTabGroup.tabBarView = self
//
//        for button in self.tabStackView.arrangedSubviews {
//            button.removeFromSuperview()
//        }
//
//        self.tabGroup = newTabGroup
//
//        for (index, tab) in newTabGroup.tabs.enumerated() {
//            addTabButtonInBackground(for: tab, index: index)
//        }
//        let selectedIndex = newTabGroup.selectedIndex
//
//        // Update Tab Selection as long as the tab index is not -1
//        if selectedIndex != -1 {
//            let arragedSubviews = tabStackView.arrangedSubviews
//            let arrangedSubviewsCount = arragedSubviews.count
//
//            guard arrangedSubviewsCount > selectedIndex,
//                let newButton = arragedSubviews[selectedIndex] as? AXTabButton
//            else { return }
//            newButton.isSelected = true
//        }
//
//        delegate?.tabBarSwitchedTo(tabAt: selectedIndex)
//    }
//}
