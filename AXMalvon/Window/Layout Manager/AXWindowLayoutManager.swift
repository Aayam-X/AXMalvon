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

    func updatedTabGroupColor(in window: AXWindow, color: NSColor)
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

    func updatedTabGroupColor(in window: AXWindow, color: NSColor) {
        window.backgroundColor = color.withAlphaComponent(1)
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
    lazy var visualEffectTintView: NSView = {
        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true

        return tintView
    }()

    lazy var visualEffectView: NSVisualEffectView = {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .popover
        visualEffectView.wantsLayer = true

        // Add tint view on top of the visual effect view
        visualEffectView.addSubview(visualEffectTintView)
        NSLayoutConstraint.activate([
            visualEffectTintView.leadingAnchor.constraint(
                equalTo: visualEffectView.leadingAnchor),
            visualEffectTintView.trailingAnchor.constraint(
                equalTo: visualEffectView.trailingAnchor),
            visualEffectTintView.topAnchor.constraint(
                equalTo: visualEffectView.topAnchor),
            visualEffectTintView.bottomAnchor.constraint(
                equalTo: visualEffectView.bottomAnchor),
        ])

        return visualEffectView
    }()

    private lazy var splitView: AXTwoPaneSplitView = {
        let splitView = AXTwoPaneSplitView(
            leftView: verticalHostingView, rightView: containerView)
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

        window.contentView = visualEffectView
        visualEffectView.addSubview(splitView)
        splitView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            splitView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            splitView.leftAnchor.constraint(
                equalTo: visualEffectView.leftAnchor),
            splitView.bottomAnchor.constraint(
                equalTo: visualEffectView.bottomAnchor),
            splitView.rightAnchor.constraint(
                equalTo: visualEffectView.rightAnchor),
        ])

        window.titlebarAppearsTransparent = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            window.configureTrafficLights()
        }
    }

    /// Returns the Boolean if the left view is hidden
    func toggleTabSidebar(in window: AXWindow) -> Bool {
        return splitView.toggleLeftView()
    }

    override func updatedTabGroupColor(in window: AXWindow, color: NSColor) {
        visualEffectTintView.layer?.backgroundColor = color.cgColor
    }
}
