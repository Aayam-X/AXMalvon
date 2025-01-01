//
//  AXWindowLayoutManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-29.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

// Protocol defining common interface for tab layout management
protocol AXWindowLayoutManaging {
    var tabBarView: any AXTabBarViewTemplate { get }
    var searchButton: AXSidebarSearchButton { get }
    var tabGroupInfoView: AXTabGroupInfoView { get }
    var tabHostingDelegate: (any AXTabHostingViewDelegate)? { get set }

    // Optional NSView - will be nil for horizontal toolbar layout
    var layoutView: NSView? { get }

    func setupLayout(in window: AXWindow)
    func updateLayout()
    func handleTabGroupInfoViewLeftDown()
    func handleTabGroupInfoViewRightDown()
}

// Base class implementing common functionality
class AXBaseLayoutManager: AXWindowLayoutManaging {
    let tabBarView: any AXTabBarViewTemplate
    var searchButton: AXSidebarSearchButton
    var tabGroupInfoView: AXTabGroupInfoView
    weak var tabHostingDelegate: (any AXTabHostingViewDelegate)?
    var layoutView: NSView? { nil }

    init(tabBarView: any AXTabBarViewTemplate) {
        self.tabBarView = tabBarView
        self.searchButton = AXSidebarSearchButton()
        self.tabGroupInfoView = AXTabGroupInfoView()

        setupCommonComponents()
    }

    private func setupCommonComponents() {
        tabGroupInfoView.onLeftMouseDown = handleTabGroupInfoViewLeftDown
        tabGroupInfoView.onRightMouseDown = handleTabGroupInfoViewRightDown
    }

    func setupLayout(in window: AXWindow) {
        // Base implementation does nothing
    }

    func updateLayout() {
        // Base implementation does nothing
    }

    func handleTabGroupInfoViewLeftDown() {
        tabHostingDelegate?.tabHostingViewDisplaysWorkspaceSwapperPanel(
            tabGroupInfoView)
    }

    func handleTabGroupInfoViewRightDown() {
        tabHostingDelegate?.tabHostingViewDisplaysTabGroupCustomizationPanel(
            tabGroupInfoView)
    }
}

// Horizontal layout manager using NSToolbar
class AXHorizontalLayoutManager: AXBaseLayoutManager {
    private lazy var toolbar: MainWindowToolbar = {
        let toolbar = MainWindowToolbar(tabBarView: tabBarView)
        toolbar.tabHostingDelegate = tabHostingDelegate
        self.searchButton = toolbar.searchButton
        self.tabGroupInfoView = toolbar.tabGroupInfoView
        return toolbar
    }()

    override func setupLayout(in window: AXWindow) {
        window.toolbar = toolbar
        window.titlebarAppearsTransparent = true

        window.contentView = window.containerView
    }
}

// Vertical layout manager using NSView
class AXVerticalLayoutManager: AXBaseLayoutManager {
    private lazy var verticalHostingView: AXVerticalTabHostingView = {
        let view = AXVerticalTabHostingView(tabBarView: tabBarView)
        view.tabHostingDelegate = tabHostingDelegate
        return view
    }()

    override var layoutView: NSView? {
        verticalHostingView
    }

    override func setupLayout(in window: AXWindow) {
        window.styleMask.insert(.fullSizeContentView)

        // guard let splitView = window.splitView else { return }
        let splitView = window.splitView  // MAKE ME OPTIONAL

        splitView.frame = window.visualEffectView.bounds
        splitView.autoresizingMask = [.height, .width]
        window.visualEffectView.addSubview(splitView)

        splitView.addArrangedSubview(verticalHostingView)
        splitView.addArrangedSubview(window.containerView)

        verticalHostingView.frame.size.width = 180

        // Configure traffic lights for vertical layout
        window.configureTrafficLights()
        window.titlebarAppearsTransparent = true
    }

    func toggleTabSidebar(in window: AXWindow) {
        guard let verticalTabHostingView = layoutView else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25  // Adjust duration as needed
            context.allowsImplicitAnimation = true

            let sideBarWillCollapsed = window.splitView.subviews.count == 2
            if sideBarWillCollapsed {
                window.hiddenSidebarView = true
                window.splitView.removeArrangedSubview(verticalTabHostingView)
                window.containerView.websiteTitleLabel.isHidden = true
            } else {
                window.hiddenSidebarView = false
                window.splitView.insertArrangedSubview(verticalTabHostingView, at: 0)
                window.containerView.websiteTitleLabel.isHidden = false
            }

            window.containerView.sidebarCollapsed(
                sideBarWillCollapsed,
                isFullScreen: window.styleMask.contains(.fullScreen))
            window.splitView.layoutSubtreeIfNeeded()
        }
    }
}
