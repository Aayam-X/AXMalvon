//
//  AXTabHostingViewProtocol.swift
//  Malvon Debug
//
//  Created by Ashwin Paudel on 2024-12-21.
//

import AppKit

protocol AXTabHostingViewDelegate: AnyObject {
    // WebView Navigation Functions
    func tabHostingViewReloadCurrentPage()
    func tabHostingViewNavigateForward()
    func tabHostingViewNavigateBackwards()

    // Browser Tab Functionality
    func tabHostingViewDisplaysTabGroupCustomizationPanel()
    func tabHostingViewDisplaysWorkspaceSwapperPanel()
    func tabHostingViewDisplayTrustPanel()
}

protocol AXTabHostingViewProtocol: AnyObject, NSView {
    var delegate: AXTabHostingViewDelegate? { get set }
    var tabGroupInfoView: AXTabGroupInfoView { get }
    var searchButton: AXSidebarSearchButton { get set }

    func insertTabBarView(tabBarView: AXTabBarViewTemplate)
}
