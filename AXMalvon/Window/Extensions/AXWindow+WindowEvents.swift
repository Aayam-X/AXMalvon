//
//  AXWindow+WindowEvents.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

extension AXWindow: NSWindowDelegate {
    internal func configureWindow() {
        self.animationBehavior = .documentWindow
        self.titlebarAppearsTransparent = true
        self.backgroundColor = .textBackgroundColor
        self.delegate = self

        if usesVerticalTabs {
            configureTrafficLights()
        }
    }

    // MARK: - Content View
    internal func setupComponents() {
        layoutManager =
            usesVerticalTabs
            ? AXVerticalLayoutManager(tabBarView: tabBarView)
            : AXHorizontalLayoutManager(tabBarView: tabBarView)

        layoutManager.tabHostingDelegate = self
        layoutManager.setupLayout(in: self)
        layoutManager.searchButton.delegate = self

        tabBarView.delegate = self
        layoutManager.containerView.delegate = self

        currentTabGroupIndex = 0
        self.switchToTabGroup(currentTabGroup)
    }

    // MARK: Window Events
    func windowWillClose(_ notification: Notification) {
        mxPrint("Testing")

        if profiles.count == 1 {
            for profile in self.profiles {
                for tabGroup in profile.tabGroups {
                    for tab in tabGroup.tabs {
                        tab.stopTitleObservation()
                    }
                    // tabGroup.tabs.removeAll()
                }
            }

            return
        }

        for profile in profiles {
            profile.saveTabGroups()
            profile.historyManager?.flushAndClose()

            for tabGroup in profile.tabGroups {
                tabGroup.tabs.forEach { tab in
                    tab.stopTitleObservation()
                }
                tabGroup.tabContentView.tabViewItems.removeAll()
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
        if event.clickCount >= 2
            && isPointInTitleBar(point: event.locationInWindow)
        {
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
        if let savedFrameString = UserDefaults.standard.string(
            forKey: "windowFrame")
        {
            return NSRectFromString(savedFrameString)
        } else {
            if let screenFrame = NSScreen.main?.frame {
                return NSRect(
                    x: 100, y: 100, width: screenFrame.width / 2,
                    height: screenFrame.height / 2)
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
            self.standardWindowButton(.zoomButton)!,
        ]

        trafficLightsPosition()
    }

    func trafficLightsPosition() {
        guard let trafficLightButtons else { return }
        // Update positioning
        for (index, button) in trafficLightButtons.enumerated() {
            button.frame.origin = NSPoint(
                x: 13.0 + CGFloat(index) * 20.0, y: -3.3)

            button.alphaValue = 1
        }
    }

    func trafficLightsPositionCompact() {
        guard let trafficLightButtons else { return }
        // Update positioning
        for (index, button) in trafficLightButtons.enumerated() {
            button.frame.origin = NSPoint(
                x: 6.0 + CGFloat(index) * 20.0, y: 9)

            button.alphaValue = 0.2
        }
    }
}
