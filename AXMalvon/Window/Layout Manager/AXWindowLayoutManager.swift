//
//  AXWindowLayoutManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-29.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import SwiftUI

// Protocol defining common interface for tab layout management
protocol AXWindowLayoutManaging {
    var containerView: AXWebContainerView { get }
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
    var containerView: AXWebContainerView
    let tabBarView: any AXTabBarViewTemplate
    var searchButton: AXSidebarSearchButton
    var tabGroupInfoView: AXTabGroupInfoView
    weak var tabHostingDelegate: (any AXTabHostingViewDelegate)?
    var layoutView: NSView? { nil }

    init(tabBarView: any AXTabBarViewTemplate) {
        self.tabBarView = tabBarView
        self.searchButton = AXSidebarSearchButton()
        self.tabGroupInfoView = AXTabGroupInfoView()
        self.containerView = AXWebContainerView(isVertical: false)

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

    func displayNewTabPage(in window: AXWindow) {

    }

    func removeNewTabPage(in window: AXWindow) {

    }
}

// Horizontal layout manager using NSToolbar
class AXHorizontalLayoutManager: AXBaseLayoutManager {
    private lazy var toolbar: MainWindowToolbar = {
        self.searchButton = AXToolbarSearchButton()
        let toolbar = MainWindowToolbar(
            tabBarView: tabBarView, searchButton: searchButton,
            tabGroupInfoView: tabGroupInfoView)
        toolbar.tabHostingDelegate = tabHostingDelegate
        return toolbar
    }()

    override func setupLayout(in window: AXWindow) {
        window.toolbar = toolbar
        window.titlebarAppearsTransparent = true

        window.contentView = containerView
    }
}

// Vertical layout manager using NSView
class AXVerticalLayoutManager: AXBaseLayoutManager {
    private lazy var splitView: AXVerticalTabBarSplitView = {
        let splitView = AXVerticalTabBarSplitView()
        splitView.isVertical = true
        return splitView
    }()

    private lazy var verticalHostingView: AXVerticalTabHostingView = {
        let view = AXVerticalTabHostingView(
            tabBarView: tabBarView, searchButton: searchButton,
            tabGroupInfoView: tabGroupInfoView)
        view.tabHostingDelegate = tabHostingDelegate

        return view
    }()

    override var layoutView: NSView? {
        verticalHostingView
    }

    override func setupLayout(in window: AXWindow) {
        window.styleMask.insert(.fullSizeContentView)

        containerView.isVertical = true

        window.contentView = splitView

        // verticalHostingView.translatesAutoresizingMaskIntoConstraints = false
        // containerView.translatesAutoresizingMaskIntoConstraints = false

        verticalHostingView.widthAnchor.constraint(
            greaterThanOrEqualToConstant: 210
        ).isActive = true
        splitView.addArrangedSubview(verticalHostingView)
        splitView.addArrangedSubview(containerView)

        // Configure traffic lights for vertical layout
        window.trafficLightsHide()
        window.titlebarAppearsTransparent = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            window.configureTrafficLights()
        }
    }

    func toggleTabSidebar(in window: AXWindow) {
        guard let verticalTabHostingView = layoutView else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25  // Adjust duration as needed
            context.allowsImplicitAnimation = true

            let sideBarWillCollapsed = splitView.subviews.count == 2
            if sideBarWillCollapsed {
                window.hiddenSidebarView = true
                splitView.removeArrangedSubview(verticalTabHostingView)
                containerView.websiteTitleLabel.isHidden = true
            } else {
                window.hiddenSidebarView = false
                splitView.insertArrangedSubview(verticalTabHostingView, at: 0)
                containerView.websiteTitleLabel.isHidden = false
            }

            containerView.sidebarCollapsed(
                sideBarWillCollapsed,
                isFullScreen: window.styleMask.contains(.fullScreen))
            splitView.layoutSubtreeIfNeeded()
        }
    }
}

class AXVerticalTabBarSplitView: NSSplitView {
    func splitView(
        _ splitView: NSSplitView,
        constrainMinCoordinate proposedMinimumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        return 160
    }

    func splitView(
        _ splitView: NSSplitView,
        constrainMaxCoordinate proposedMaximumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        return 500
    }

    func splitView(
        _ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView
    ) -> Bool {
        return view.tag != 0x01
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView)
        -> Bool
    {
        return false
    }

    override func drawDivider(in rect: NSRect) {
        // Empty Divider
    }
}
