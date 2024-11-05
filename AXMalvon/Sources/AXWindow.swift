//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

class AXWindow: NSWindow, NSWindowDelegate {
    var sessionProperties: AXSessionProperties
    
    override var title: String {
        didSet {
            updateTrafficLights()
            super.title = title
        }
    }
    
    init(isPrivate: Bool = false, restoresTab: Bool = true) {
        sessionProperties = AXSessionProperties(isPrivate: isPrivate, restoresTab: restoresTab)
        super.init(
            contentRect: sessionProperties.windowFrame,
            styleMask: [.closable, .titled, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Window initializers
        self.delegate = self
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        self.minSize = .init(width: 300, height: 300)
        self.isReleasedWhenClosed = false
        sessionProperties.window = self
        backgroundColor = .textBackgroundColor // NSWindow has hidden NSVisualEffectView, to remove we must use this code
        self.contentView = sessionProperties.contentView
        updateTrafficLights()
        
        if !sessionProperties.sidebarToggled {
            hideTrafficLights(true)
        }
        
        if sessionProperties.isPrivate {
            self.appearance = .init(named: .darkAqua)
        }
    }
    
    // MARK: - Window Functions
    override func makeKey() {
        // Make searchField first responder
        if sessionProperties.searchFieldShown {
            let window1 = childWindows![0]
            window1.makeKey()
            window1.makeFirstResponder(sessionProperties.popOver.searchField)
            return
        }
        
        super.makeKey()
    }
    
    func windowDidResize(_ notification: Notification) {
        updateTrafficLights()
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        sessionProperties.isFullScreen = true
        sessionProperties.sidebarView.enteredFullScreen()
        sessionProperties.webContainerView.enteredFullScreen()
        _hideTrafficLights(false)
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        sessionProperties.isFullScreen = false
        hideTrafficLights(!sessionProperties.sidebarToggled)
        sessionProperties.sidebarView.exitedFullScreen()
        sessionProperties.webContainerView.exitedFullScreen()
    }
    
    override func close() {
        // Save the window
        sessionProperties.windowFrame = self.frame
        sessionProperties.saveProperties()
        
        sessionProperties.sidebarView.tabView.tabStackView.arrangedSubviews.forEach { view in
            (view as! AXSidebarTabButton).stopObserving()
            view.removeFromSuperview()
        }
        
        sessionProperties.webContainerView.stopObserving()
        sessionProperties.webContainerView.removeDelegates()
        
        sessionProperties.profiles.forEach { $0.saveProperties(); $0.tabs.removeAll() }
        
        super.close()
    }
    
    override func mouseUp(with event: NSEvent) {
        if event.clickCount >= 2 && isPointInTitleBar(point: event.locationInWindow) { // double-click in title bar
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
    
    // MARK: - Public
    
    public func hideTrafficLights(_ b: Bool) {
        if !sessionProperties.isFullScreen {
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
}
