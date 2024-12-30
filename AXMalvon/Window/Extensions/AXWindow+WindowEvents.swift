//
//  AXWindow+WindowEvents.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//

import AppKit

extension AXWindow: NSWindowDelegate {
    internal func configureWindow() {
        self.animationBehavior = .documentWindow
        // self.titlebarAppearsTransparent = true
        self.backgroundColor = .textBackgroundColor
        self.isReleasedWhenClosed = true
        self.delegate = self

        if usesVerticalTabs {
            configureTrafficLights()
        }
    }

    // MARK: - Content View
    internal func setupComponents() {
        // Visual Effect View
        self.contentView = visualEffectView
        containerView.translatesAutoresizingMaskIntoConstraints = false

        layoutManager =
            usesVerticalTabs
            ? AXVerticalLayoutManager(tabBarView: tabBarView)
            : AXHorizontalLayoutManager(tabBarView: tabBarView)

        layoutManager.tabHostingDelegate = self
        layoutManager.setupLayout(in: self)
        layoutManager.searchButton.delegate = self

        tabBarView.delegate = self
        containerView.delegate = self

        currentTabGroupIndex = 0
        tabBarView.updateTabGroup(currentTabGroup)
        visualEffectTintView.layer?.backgroundColor =
            currentTabGroup.color.cgColor
    }

    // MARK: Window Events
    func windowWillClose(_ notification: Notification) {
        for profile in profiles {
            profile.saveTabGroups()

            for tabGroup in profile.tabGroups {
                tabGroup.tabs.removeAll()
                tabGroup.tabBarView?.removeFromSuperview()
                tabGroup.tabBarView = nil
            }
        }
    }

    func windowDidResize(_ notification: Notification) {
        trafficLightsPosition()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        let frameAsString = NSStringFromRect(self.frame)
        UserDefaults.standard.set(frameAsString, forKey: "windowFrame")
    }

    override func mouseUp(with event: NSEvent) {
        // Double-click in title bar
        if event.clickCount >= 2 && isPointInTitleBar(point: event.locationInWindow) {
            self.zoom(nil)
        }
        super.mouseUp(with: event)
    }

    override func otherMouseDown(with event: NSEvent) {
        let buttonNumber = event.buttonNumber

        // Logitech MX Master 3S mouse keymapping.
        switch buttonNumber {
        case 3:
            tabHostingViewNavigateBackwards()
        case 4:
            tabHostingViewNavigateForward()
        default: break
        }
    }

    fileprivate func isPointInTitleBar(point: CGPoint) -> Bool {
        if let windowFrame = self.contentView?.frame {
            let titleBarRect = NSRect(
                x: self.contentLayoutRect.origin.x,
                y: self.contentLayoutRect.origin.y
                    + self.contentLayoutRect.height,
                width: self.contentLayoutRect.width,
                height: windowFrame.height - self.contentLayoutRect.height)
            return titleBarRect.contains(point)
        }
        return false
    }

    static internal func updateWindowFrame() -> NSRect {
        if let savedFrameString = UserDefaults.standard.string(forKey: "windowFrame") {
            return NSRectFromString(savedFrameString)
        } else {
            if let screenFrame = NSScreen.main?.frame {
                return NSRect(x: 100, y: 100, width: screenFrame.width / 2, height: screenFrame.height / 2)
            } else {
                return NSRect(x: 100, y: 100, width: 800, height: 600)
            }
        }
    }

    // MARK: - Traffic Lights
    func configureTrafficLights() {
        self.trafficLightButtons = [
            self.standardWindowButton(.closeButton)!,
            self.standardWindowButton(.miniaturizeButton)!,
            self.standardWindowButton(.zoomButton)!
        ]

        trafficLightsPosition()
    }

    func trafficLightsPosition() {
        guard let trafficLightButtons else { return }
        // Update positioning
        for (index, button) in trafficLightButtons.enumerated() {
            button.frame.origin = NSPoint(
                x: 13.0 + CGFloat(index) * 20.0, y: -0.5)
        }
    }

    func trafficLightsHide() {
        trafficLightButtons?.forEach { button in
            button.isHidden = true
        }
    }

    func trafficLightsShow() {
        trafficLightButtons?.forEach { button in
            button.isHidden = false
        }
    }
}
