//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXWindow: NSWindow, NSWindowDelegate {
    var trackingTag: NSView.TrackingRectTag?
    
    var appProperties = AXAppProperties()
    
    override var title: String {
        didSet {
            updateTrafficLights()
            super.title = title
        }
    }
    
    init() {
        super.init(
            contentRect: appProperties.windowFrame,
            styleMask: [.closable, .titled, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        delegate = self
        
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        self.minSize = .init(width: 300, height: 300)
        
        // NSWindow has a hidden NSVisualEffectView that changes the window's tint based on the wallpaper and position
        // We do not want to have two NSVisualEffectViews as it effects the performance
        // Which is why we must set the background color
        backgroundColor = .textColor
        
        updateTrackingAreas(true)
        
        shouldEnableButtons(false)
        
        if !appProperties.sidebarToggled {
            hideTrafficLights(true)
        }
        
        self.contentView = appProperties.contentView
        appProperties.window = self
        
        updateTrafficLights()
    }
    
    
    // MARK: - Mouse Tracking Functions
    override func mouseEntered(with theEvent: NSEvent) {
        if trackingTag == theEvent.trackingNumber {
            shouldEnableButtons(true)
        }
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        if trackingTag == theEvent.trackingNumber {
            shouldEnableButtons(false)
        }
    }
    
    func updateTrackingAreas(_ establish : Bool) {
        if let tag = trackingTag {
            standardWindowButton(.closeButton)!.removeTrackingRect(tag)
        }
        
        if establish, let closeButton = standardWindowButton(.closeButton) {
            let newBounds = NSRect(x: 0, y: 0, width: 55, height: 14.5)
            trackingTag = closeButton.addTrackingRect(newBounds, owner: self, userData: nil, assumeInside: false)
        }
    }
    
    // MARK: - Window Functions
    
    func windowDidResize(_ notification: Notification) {
        updateTrafficLights()
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        appProperties.isFullScreen = true
        appProperties.sidebarView.enteredFullScreen()
        appProperties.webContainerView.enteredFullScreen()
        _hideTrafficLights(false)
        shouldEnableButtons(true)
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        appProperties.isFullScreen = false
        shouldEnableButtons(false)
        hideTrafficLights(!appProperties.sidebarToggled)
        appProperties.sidebarView.exitedFullScreen()
        appProperties.webContainerView.exitedFullScreen()
    }
    
    func windowWillClose(_ notification: Notification) {
        appProperties.tabs.forEach { tab in
            tab.view.removeFromSuperview()
        }
        
        appProperties.sidebarView.stackView.arrangedSubviews.forEach { view in
            (view as? AXSidebarTabButton)?.stopObserving()
        }
        
        appProperties.webContainerView.stopObserving()
        
        appProperties.tabs.removeAll()
    }
    
    // MARK: - Public
    
    public func hideTrafficLights(_ b: Bool) {
        if !appProperties.isFullScreen {
            _hideTrafficLights(b)
        }
    }
    
    // MARK: - Private
    
    private func _hideTrafficLights(_ b: Bool) {
        standardWindowButton(.closeButton)?.isHidden = b
        standardWindowButton(.miniaturizeButton)!.isHidden = b
        standardWindowButton(.zoomButton)!.isHidden = b
    }
    
    /// Update the position of the window buttons
    fileprivate func updateTrafficLights() {
        // func offset(_ x: NSButton) {
        // print(x, x.frame.origin)
        // x.frame.origin.x += 6.0
        // x.frame.origin.y -= 6.0
        //
        // x.frame.size.width = 14.5
        // x.frame.size.height = 16.5
        // }
        
        let closeButton = standardWindowButton(.closeButton)!
        closeButton.frame.origin.x = 13.0
        closeButton.frame.origin.y = 0
        
        let miniaturizeButton = standardWindowButton(.miniaturizeButton)!
        miniaturizeButton.frame.origin.x = 33.0
        miniaturizeButton.frame.origin.y = 0
        
        let zoomButton = standardWindowButton(.zoomButton)!
        zoomButton.frame.origin.x = 53.0
        zoomButton.frame.origin.y = 0
    }
    
    fileprivate func shouldEnableButtons(_ b: Bool) {
        standardWindowButton(.closeButton)!.isEnabled = b
        standardWindowButton(.miniaturizeButton)!.isEnabled = b
        standardWindowButton(.zoomButton)!.isEnabled = b
    }
}
