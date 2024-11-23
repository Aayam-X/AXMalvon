//
//  AXSidebarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import Cocoa

protocol AXSideBarViewDelegate: AnyObject {
    func sidebarView(didSelectTabGroup tabGroupAt: Int)
    func sidebarViewactiveTitle(changed to: String)
    func sidebarSwitchedTab(at: Int)
}

class AXSidebarView: NSView {
    private var hasDrawn: Bool = false
    weak var delegate: AXSideBarViewDelegate?
    var currentTabGroup: AXTabGroup?

    var gestureView = AXGestureView()
    private weak var tabBarView: AXTabBarView?
    private var visualEffectViewTopAnchor: NSLayoutConstraint?
    var mouseExitedTrackingArea: NSTrackingArea!

    private lazy var visualEffectView: NSVisualEffectView = {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .sidebar
        visualEffectView.wantsLayer = true
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        return visualEffectView
    }()

    override var tag: Int {
        return 0x01
    }

    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        setUpVisualEffectView()

        mouseExitedTrackingArea = NSTrackingArea(
            rect: .init(
                x: bounds.origin.x + 1, y: bounds.origin.y,
                width: bounds.size.width + 100, height: bounds.size.height),
            options: [.activeAlways, .mouseEnteredAndExited], owner: self)
        addTrackingArea(mouseExitedTrackingArea)

        gestureView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gestureView)
        NSLayoutConstraint.activate([
            gestureView.topAnchor.constraint(equalTo: topAnchor),
            gestureView.leftAnchor.constraint(equalTo: leftAnchor),
            gestureView.rightAnchor.constraint(equalTo: rightAnchor),
            gestureView.heightAnchor.constraint(equalToConstant: 39),
        ])

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

            if tabAt == -1 {
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
            tabBarView!.topAnchor.constraint(equalTo: topAnchor, constant: 44),
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

        visualEffectViewTopAnchor?.constant = 39

        window.trafficLightManager.hideTrafficLights(true)
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

    func setUpVisualEffectView() {
        addSubview(visualEffectView)
        self.visualEffectViewTopAnchor = visualEffectView.topAnchor.constraint(
            equalTo: topAnchor, constant: 39)
        self.visualEffectViewTopAnchor!.isActive = true

        NSLayoutConstraint.activate([
            visualEffectView.leftAnchor.constraint(equalTo: leftAnchor),
            visualEffectView.rightAnchor.constraint(equalTo: rightAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Add a tint overlay
        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor =
            NSColor.systemRed.withAlphaComponent(0.2).cgColor

        // Add tint view on top of the visual effect view
        visualEffectView.addSubview(tintView)
        NSLayoutConstraint.activate([
            tintView.leadingAnchor.constraint(
                equalTo: visualEffectView.leadingAnchor),
            tintView.trailingAnchor.constraint(
                equalTo: visualEffectView.trailingAnchor),
            tintView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            tintView.bottomAnchor.constraint(
                equalTo: visualEffectView.bottomAnchor),
        ])
    }

    func extendVisualEffectView() {
        visualEffectViewTopAnchor?.constant = 0

        guard let window = self.window as? AXWindow else { return }
        window.trafficLightManager.hideTrafficLights(false)
    }
}

// MARK: - Tab Bar Delegate
extension AXSidebarView: AXTabBarViewDelegate {
    func activeTabTitleChanged(to: String) {
        delegate?.sidebarViewactiveTitle(changed: to)
    }

    func tabBarSwitchedTo(tabAt: Int) {
        delegate?.sidebarSwitchedTab(at: tabAt)
        print("Switched to tab at \(tabAt).")
    }
}
