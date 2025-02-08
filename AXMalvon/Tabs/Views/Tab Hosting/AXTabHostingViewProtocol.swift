//
//  AXTabHostingViewProtocol.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

protocol AXTabHostingViewDelegate: AnyObject {
    // Tab Functionality
    func tabHostingViewCreatedNewTab()
    func tabHostingViewWillRemoveTab(tab: AXTab)
    
    // Tab Functionality From AXTabBarViewDelegate
    func tabBarSwitchedTo(_ tabButton: AXTabButton)
    func tabBarShouldClose(_ tabButton: AXTabButton) -> Bool
    func tabBarDidClose(_ tabAt: Int)
    
    
    // WebView Navigation Functions
    func tabHostingViewReloadCurrentPage()
    func tabHostingViewNavigateForward()
    func tabHostingViewNavigateBackwards()

    // Browsing Functions
    func tabHostingViewDisplaysTabGroupCustomizationPanel(_ sender: NSView)
    func tabHostingViewDisplaysWorkspaceSwapperPanel(_ sender: NSView)
}

protocol AXTabHostingViewProtocol: AnyObject {
    var tabHostingDelegate: AXTabHostingViewDelegate? { get set }
    
    var tabGroupInfoView: AXTabGroupInfoView { get }
    var searchButton: AXSidebarSearchButton { get }
    var tabBarView: AXTabBarViewTemplate { get }

    init(
        tabBarView: any AXTabBarViewTemplate,
        searchButton: AXSidebarSearchButton,
        tabGroupInfoView: AXTabGroupInfoView)
}
