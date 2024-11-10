//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

class AXWindow: NSWindow, NSWindowDelegate {
    var sessionProperties = AXSessionProperties()
    private let splitView = AXSplitView()
    
    init() {
        super.init(
            contentRect: sessionProperties.windowFrame,
            styleMask: [.closable, .titled, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        // Window Configurations
        self.titlebarAppearsTransparent = true
        self.updateTrafficLights()
        self.delegate = self
        backgroundColor = .textBackgroundColor // NSWindow has hidden NSVisualEffectView, to remove we must use this code
        
        // Other Configurations
        sessionProperties.window = self
        
        splitView.addArrangedSubview(sessionProperties.sidebarView)
        splitView.addArrangedSubview(sessionProperties.containerView)
        
        self.contentView = splitView
        sessionProperties.sidebarView.frame.size.width = 180
    }
    
    func toggleTabSidebar() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25 // Adjust duration as needed
            context.allowsImplicitAnimation = true
            
            if splitView.subviews.count == 2 {
                splitView.arrangedSubviews[0].removeFromSuperview()
                hideTrafficLights(true)
            } else {
                splitView.insertArrangedSubview(sessionProperties.sidebarView, at: 0)
                hideTrafficLights(false)
            }
            
            splitView.layoutSubtreeIfNeeded()
        }
    }

    
    // MARK: Window Events
    func windowDidResize(_ notification: Notification) {
        updateTrafficLights()
    }
    
    override func mouseUp(with event: NSEvent) {
        // Double-click in title bar
        if event.clickCount >= 2 && isPointInTitleBar(point: event.locationInWindow) {
            self.performZoom(nil)
        }
        super.mouseUp(with: event)
    }

    fileprivate func isPointInTitleBar(point: CGPoint) -> Bool {
        if let windowFrame = self.contentView?.frame {
            let titleBarRect = NSRect(x: self.contentLayoutRect.origin.x, y: self.contentLayoutRect.origin.y+self.contentLayoutRect.height, width: self.contentLayoutRect.width, height: windowFrame.height-self.contentLayoutRect.height)
            return titleBarRect.contains(point)
        }
        return false
    }
    
    // MARK: Traffic Light Functions
    fileprivate func hideTrafficLights(_ b: Bool) {
        standardWindowButton(.closeButton)?.isHidden = b
        standardWindowButton(.miniaturizeButton)!.isHidden = b
        standardWindowButton(.zoomButton)!.isHidden = b
    }
    
    
    fileprivate func updateTrafficLights() {
        let closeButton = standardWindowButton(.closeButton)!
        closeButton.frame.origin.x = 13.0
        closeButton.frame.origin.y = 0
        closeButton.layer?.cornerRadius = 8
        closeButton.layer?.borderWidth = 0.2
        closeButton.layer?.borderColor = .white
        
        let miniaturizeButton = standardWindowButton(.miniaturizeButton)!
        miniaturizeButton.frame.origin.x = 33.0
        miniaturizeButton.frame.origin.y = 0
        miniaturizeButton.layer?.cornerRadius = 8
        miniaturizeButton.layer?.borderWidth = 0.2
        miniaturizeButton.layer?.borderColor = .white
        
        let zoomButton = standardWindowButton(.zoomButton)!
        zoomButton.frame.origin.x = 53.0
        zoomButton.frame.origin.y = 0
        zoomButton.layer?.cornerRadius = 8
        zoomButton.layer?.borderWidth = 0.2
        zoomButton.layer?.borderColor = .white
    }
}

private class AXSplitView: NSSplitView, NSSplitViewDelegate {
    init() {
        super.init(frame: .zero)
        
        delegate = self
        isVertical = true
        dividerStyle = .thin
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 160
    }
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 500
    }
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        return view.tag == 0x01 ? false : true
    }
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }
}

extension AXWindow {
    // MARK: - Menu Bar Item Actions
    @IBAction func toggleSearchField(_ sender: Any) {
        sessionProperties.searchBarWindow.showCurrentURL()
    }
    
    @IBAction func closeWindow(_ sender: Any) {
        self.close()
    }
    
    @IBAction func createNewTab(_ sender: Any) {
        sessionProperties.searchBarWindow.show()
    }
    
    @IBAction func createNewWindow(_ sender: Any) {
        let window = AXWindow()
        
        // Create new window and create blank window
//        window.sessionProperties.profiles.forEach { $0.retriveTabs() }
        
        window.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func closeTab(_ sender: Any) {
        sessionProperties.tabManager.currentTabGroup.removeTab()
    }
    
    @IBAction func showSidebar(_ sender: Any) {
        print("HELLO WORLD")
        toggleTabSidebar()
    }

    override var acceptsFirstResponder: Bool {
        true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.keyCode {
            case 18: // '1' key
                switchToTab(index: 0)
            case 19: // '2' key
                switchToTab(index: 1)
            case 20: // '3' key
                switchToTab(index: 2)
            case 21: // '4' key
                switchToTab(index: 3)
            case 22: // '5' key
                switchToTab(index: 4)
            case 23: // '6' key
                switchToTab(index: 5)
            case 26: // '7' key
                switchToTab(index: 6)
            default:
                break
            }
        } else {
            super.keyDown(with: event)
        }
    }
    
    func switchToTab(index: Int) {
        // Check if the tab index is valid
        if index < sessionProperties.tabManager.currentTabGroup.tabs.count {
            // Hide all tabs
            sessionProperties.tabManager.currentTabGroup.switchTab(to: index)
        } else {
            guard sessionProperties.tabManager.currentTabGroup.tabs.count > 0 else { return }
            // Switch to the last tab if the index is out of range
            sessionProperties.tabManager.currentTabGroup.switchTab(to: sessionProperties.tabManager.currentTabGroup.tabs.count - 1)
        }
    }
}
