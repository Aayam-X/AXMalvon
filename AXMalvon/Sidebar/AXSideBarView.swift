//
//  AXSidebarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
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

    var gestureView = AXGestureView()
    private weak var tabBarView: AXTabBarView?

    private lazy var visualEffectView: NSVisualEffectView = {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .sidebar
        visualEffectView.wantsLayer = true
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        return visualEffectView
    }()

    var currentTabGroup: AXTabGroup?

    var mouseExitedTrackingArea: NSTrackingArea!

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

        //self.layer?.backgroundColor = NSColor.systemIndigo.withAlphaComponent(0.3).cgColor

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

    func setUpVisualEffectView() {
        addSubview(visualEffectView)
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(
                equalTo: topAnchor, constant: 39),
            visualEffectView.leftAnchor.constraint(equalTo: leftAnchor),
            visualEffectView.rightAnchor.constraint(equalTo: rightAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Add a tint overlay
        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor =
            NSColor.systemRed.withAlphaComponent(0.2).cgColor  // Adjust alpha as needed

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

    func faviconDetected(image: NSImage?) {
        guard
            let button = tabBarView?.tabStackView.arrangedSubviews[
                currentTabGroup!.selectedIndex] as? AXTabButton
        else { return }

        button.favicon = image
    }
}

extension AXSidebarView: AXTabBarViewDelegate {
    func activeTabTitleChanged(to: String) {
        delegate?.sidebarViewactiveTitle(changed: to)
    }

    func tabBarSwitchedTo(tabAt: Int) {
        delegate?.sidebarSwitchedTab(at: tabAt)
        print("Switched to tab at \(tabAt).")
    }
}
