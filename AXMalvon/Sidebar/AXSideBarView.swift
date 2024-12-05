//
//  AXSidebarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Cocoa
import WebKit

protocol AXSideBarViewDelegate: AnyObject {
    func sidebarView(didSelectTabGroup tabGroupAt: Int)
    func sidebarViewactiveTitle(changed to: String)
    func sidebarSwitchedTab(at: Int)

    func deactivatedTab() -> WKWebViewConfiguration?
}

class AXSidebarView: NSView {
    private var hasDrawn: Bool = false
    weak var delegate: AXSideBarViewDelegate?
    var currentTabGroup: AXTabGroup?

    var gestureView = AXGestureView()
    private weak var tabBarView: AXTabBarView?
    var mouseExitedTrackingArea: NSTrackingArea!

    override var tag: Int {
        return 0x01
    }

    private lazy var bottomLine: NSBox = {
        let line = NSBox()
        line.boxType = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }()

    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }

        // Gesture View
        gestureView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gestureView)
        NSLayoutConstraint.activate([
            gestureView.topAnchor.constraint(equalTo: topAnchor),
            gestureView.leftAnchor.constraint(equalTo: leftAnchor),
            gestureView.rightAnchor.constraint(
                equalTo: rightAnchor, constant: 3),
            gestureView.heightAnchor.constraint(equalToConstant: 80),
        ])

        // Divider between Search Bar and Tab
        addSubview(bottomLine)
        NSLayoutConstraint.activate([
            bottomLine.topAnchor.constraint(
                equalTo: gestureView.bottomAnchor, constant: 5),
            bottomLine.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
            bottomLine.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -10),
            bottomLine.heightAnchor.constraint(equalToConstant: 1),
        ])

        // Mouse Tracking Area
        mouseExitedTrackingArea = NSTrackingArea(
            rect: .init(
                x: bounds.origin.x + 1, y: bounds.origin.y,
                width: bounds.size.width + 100, height: bounds.size.height),
            options: [.activeAlways, .mouseEnteredAndExited], owner: self)
        addTrackingArea(mouseExitedTrackingArea)

        // Update tab bar
        if let window = self.window as? AXWindow {
            self.changeShownTabBarGroup(window.currentTabGroup)
        }
    }

    // MARK: - Tab Bar Functions
    func changeShownTabBarGroup(_ tabGroup: AXTabGroup) {
        currentTabGroup = tabGroup

        tabGroup.initializeTabBarView()
        updateTabBarView(tabBar: tabGroup.tabBarView!)

        // Update the webview
        if let tabs = currentTabGroup?.tabs {
            let window = self.window as! AXWindow
            gestureView.tabGroupInformationView.profileLabel.stringValue =
                window.defaultProfile.name
            gestureView.tabGroupInformationView.tabGroupLabel.stringValue =
                tabGroup.name

            let tabAt = tabGroup.selectedIndex

            if tabAt == -1 || tabGroup.tabs.count <= tabAt {
                tabGroup.selectedIndex = -1
                window.containerView.createEmptyView()
            } else {
                window.containerView.updateView(webView: tabs[tabAt].webView)
            }
        }
    }

    private func updateTabBarView(tabBar: AXTabBarView) {
        tabBarView?.removeFromSuperview()

        self.tabBarView = tabBar
        self.tabBarView?.translatesAutoresizingMaskIntoConstraints = false
        self.tabBarView?.delegate = self

        addSubview(tabBarView!)

        NSLayoutConstraint.activate([
            tabBarView!.topAnchor.constraint(
                equalTo: bottomLine.bottomAnchor, constant: 5),
            tabBarView!.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBarView!.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabBarView!.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Mouse Functions
    override func mouseExited(with event: NSEvent) {
        guard let window = self.window as? AXWindow, window.hiddenSidebarView
        else { return }

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.1
                self.animator().frame.origin.x = -bounds.width
            },
            completionHandler: {
                self.layer?.backgroundColor = .none
                self.removeFromSuperview()
            })
    }

    override func viewDidEndLiveResize() {
        removeTrackingArea(mouseExitedTrackingArea)
        mouseExitedTrackingArea = NSTrackingArea(
            rect: .init(
                x: bounds.origin.x - 100, y: bounds.origin.y,
                width: bounds.size.width + 100, height: bounds.size.height),
            options: [.activeAlways, .mouseEnteredAndExited], owner: self)
        addTrackingArea(mouseExitedTrackingArea)
    }
}

// MARK: - Tab Bar Delegate
extension AXSidebarView: AXTabBarViewDelegate {
    func deactivatedTab() -> WKWebViewConfiguration? {
        delegate?.deactivatedTab()
    }

    func activeTabTitleChanged(to: String) {
        delegate?.sidebarViewactiveTitle(changed: to)
    }

    func tabBarSwitchedTo(tabAt: Int) {
        delegate?.sidebarSwitchedTab(at: tabAt)
        mxPrint("Switched to tab at \(tabAt).")
    }
}
