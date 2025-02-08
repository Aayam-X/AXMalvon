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

    func removeLayout(in window: AXWindow)

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
        self.containerView = AXWebContainerView()
        // self.containerView = AXWebContainerView(isVertical: false)

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

    func removeLayout(in window: AXWindow) {
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
        let newColor = color.systemAppearanceAdjustedColor()
        window.backgroundColor = newColor.withAlphaComponent(1)
    }
}

//// Horizontal layout manager using NSToolbar
//class AXHorizontalLayoutManager: AXBaseLayoutManager {
//    private lazy var toolbar: MainWindowToolbar = {
//        self.searchButton = AXToolbarSearchButton()
//        let toolbar = MainWindowToolbar(
//            tabBarView: tabBarView, searchButton: searchButton,
//            tabGroupInfoView: tabGroupInfoView)
//        toolbar.tabHostingDelegate = tabHostingDelegate
//        return toolbar
//    }()
//
//    override func setupLayout(in window: AXWindow) {
//        window.toolbar = toolbar
//        window.titlebarAppearsTransparent = true
//
//        window.contentView = containerView
//    }
//
//    override func removeLayout(in window: AXWindow) {
//        window.toolbar = nil
//
//        containerView.removeFromSuperview()
//    }
//}

// Vertical layout manager using NSView
class AXVerticalLayoutManager: AXBaseLayoutManager {
    var splitViewResizeObserver: NSKeyValueObservation?

    private lazy var splitViewController: NSSplitViewController = {
        let splitVC = NSSplitViewController()
        splitVC.splitView.isVertical = true

        // Sidebar Split View Item
        let sidebarItem = NSSplitViewItem(
            sidebarWithViewController: sidebarViewController)
        sidebarItem.canCollapse = true
        sidebarItem.minimumThickness = 200
        sidebarItem.maximumThickness = 300

        // Main Content Split View Item
        let mainItem = NSSplitViewItem(viewController: mainViewController)
        sidebarItem.canCollapse = false
        mainItem.minimumThickness = 200

        splitVC.addSplitViewItem(sidebarItem)
        splitVC.addSplitViewItem(mainItem)

        return splitVC
    }()

    private lazy var sidebarViewController: NSViewController = {
        let vc = NSViewController()
        vc.view = verticalHostingView
        return vc
    }()

    private lazy var mainViewController: NSViewController = {
        let vc = NSViewController()
        vc.view = containerView
        return vc
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

    override func removeLayout(in window: AXWindow) {
        window.styleMask.remove(.fullSizeContentView)
        window.contentViewController = nil  // Remove splitVC
        splitViewController.splitViewItems.forEach { item in
            splitViewController.removeSplitViewItem(item)
        }
        //containerView.isVertical = false

        splitViewResizeObserver?.invalidate()
        splitViewResizeObserver = nil

        containerView.removeFromSuperview()
        searchButton.removeFromSuperview()
        tabGroupInfoView.removeFromSuperview()
        tabBarView.removeFromSuperview()
        verticalHostingView.removeFromSuperview()
    }

    override func setupLayout(in window: AXWindow) {
        window.styleMask.insert(.fullSizeContentView)

        //containerView.isVertical = true

        window.contentViewController = splitViewController

        mxPrint("Container View \(containerView)")

        window.titlebarAppearsTransparent = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            window.configureTrafficLights()
        }

        splitViewResizeObserver = verticalHostingView.observe(
            \.frame, options: [.new]
        ) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                window.trafficLightsPosition()
            }
        }
    }
    
    override func updatedTabGroupColor(in window: AXWindow, color: NSColor) {
        verticalHostingView.layer?.backgroundColor = color.cgColor
    }
}
