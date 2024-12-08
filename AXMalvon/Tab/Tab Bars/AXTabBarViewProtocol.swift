//
//  AXTabBarViewProtocol.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-08.
//

import Cocoa
import WebKit

//protocol AXTabBarViewDelegate: AnyObject {
//    func tabBarSwitchedTo(tabAt: Int)
//    func activeTabTitleChanged(to: String)
//
//    /// Return a WKWebViewConfiguration when the user deactivates a self-created web view
//    func deactivatedTab() -> WKWebViewConfiguration?
//}
//
//class AXTabBarViewGeneric: NSView, AXTabButtonDelegate {
//    weak var tabGroup: AXTabGroup!
//    weak var delegate: AXTabBarViewDelegate?
//
//    func addTabButton(for tab: AXTab) {}
//
//    func removeTabButton(at index: Int) {}
//
//    func addTabButtonInBackground(for tab: AXTab, index: Int) {}
//
//    func updateIndicies(after: Int) {}
//
//    func updateTabSelection(from: Int, to: Int) {}
//
//    private func addButtonToTabView(_ button: NSView) {}
//
//    private func addButtonToTabViewWithoutAnimation(_ button: NSView) {}
//
//    private func reorderTabs(from: Int, to: Int) {}
//
//    func updateTabGroup(_ newTabGroup: AXTabGroup) {}
//
//    // MARK: - Tab Button Delegate
//    func tabButtonDidSelect(_ tabButton: AXTabButton) {}
//
//    func tabButtonWillClose(_ tabButton: AXTabButton) {}
//
//    func tabButtonActiveTitleChanged(_ newTitle: String, for tabButton: AXTabButton) {}
//
//    func tabButtonDeactivatedWebView(_ tabButton: AXTabButton) {}
//}
//

protocol AXTabBarViewDelegate: AnyObject {
    func tabBarSwitchedTo(tabAt: Int)
    func activeTabTitleChanged(to: String)

    /// Return a WKWebViewConfiguration when the user deactivates a self-created web view
    func deactivatedTab() -> WKWebViewConfiguration?
}

protocol AXTabBarViewTemplate: AnyObject, NSView, AXTabButtonDelegate {
    var tabGroup: AXTabGroup! { get set }
    var delegate: AXTabBarViewDelegate? { get set }

    func addTabButton(for tab: AXTab)
    func removeTabButton(at index: Int)
    func addTabButtonInBackground(for tab: AXTab, index: Int)
    func updateIndices(after index: Int)
    func updateTabSelection(from: Int, to: Int)

    func updateTabGroup(_ newTabGroup: AXTabGroup)
}
