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
        
        updateTrafficLights()
        
        
        updateTrackingAreas(true)
        
        shouldEnableButtons(false)
        
        if !appProperties.sidebarToggled {
            hideTrafficLights(true)
        }
        
        self.contentView = appProperties.contentView
        appProperties.window = self
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
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        appProperties.isFullScreen = false
        shouldEnableButtons(false)
        hideTrafficLights(!appProperties.sidebarToggled)
        appProperties.sidebarView.exitedFullScreen()
        appProperties.webContainerView.exitedFullScreen()
    }
    
    // MARK: - Public
    
    public func hideTrafficLights(_ b: Bool) {
        if !appProperties.isFullScreen {
            standardWindowButton(.closeButton)?.isHidden = b
            standardWindowButton(.miniaturizeButton)!.isHidden = b
            standardWindowButton(.zoomButton)!.isHidden = b
        }
    }
    
    // MARK: - Private
    
    /// Update the position of the window buttons
    fileprivate func updateTrafficLights() {
        func offset(_ x: NSButton) {
            x.frame.origin.x += 6.0
            x.frame.origin.y -= 6.0
            
            // x.frame.size.width = 14.5
            // x.frame.size.height = 16.5
        }
        
        offset(standardWindowButton(.closeButton)!)
        offset(standardWindowButton(.miniaturizeButton)!)
        offset(standardWindowButton(.zoomButton)!)
    }
    
    fileprivate func shouldEnableButtons(_ b: Bool) {
        standardWindowButton(.closeButton)!.isEnabled = b
        standardWindowButton(.miniaturizeButton)!.isEnabled = b
        standardWindowButton(.zoomButton)!.isEnabled = b
    }
}
