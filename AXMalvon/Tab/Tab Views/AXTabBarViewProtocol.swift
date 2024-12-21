//
//  AXTabBarViewProtocol.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-08.
//

import AppKit
import WebKit

protocol AXTabBarViewDelegate: AnyObject {
    func tabBarSwitchedTo(tabAt: Int)
    func tabBarActiveTabTitleChanged(to: String)

    /// Return a WKWebViewConfiguration when the user deactivates a self-created web view
    func tabBarDeactivatedTab() -> WKWebViewConfiguration?
}

protocol AXTabBarViewTemplate: AnyObject, NSView, AXTabButtonDelegate {
    var tabGroup: AXTabGroup! { get set }
    var delegate: AXTabBarViewDelegate? { get set }

    var tabStackView: NSStackView { get set }

    func addTabButton(for tab: AXTab)
    func removeTabButton(at index: Int)
    func addTabButtonInBackground(for tab: AXTab, index: Int)
    func updateIndices(after index: Int)
    func updateTabSelection(from: Int, to: Int)
}

extension AXTabBarViewTemplate {
    func updateTabGroup(_ newTabGroup: AXTabGroup) {
        newTabGroup.tabBarView = self

        for button in self.tabStackView.arrangedSubviews {
            button.removeFromSuperview()
        }

        self.tabGroup = newTabGroup

        for (index, tab) in newTabGroup.tabs.enumerated() {
            addTabButtonInBackground(for: tab, index: index)
        }

        guard newTabGroup.selectedIndex != -1 else { return }
        self.updateTabSelection(from: -1, to: newTabGroup.selectedIndex)
    }
}
