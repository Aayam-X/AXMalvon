//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit

class AXWindow: NSWindow, NSWindowDelegate {
    var appProperties: AXAppProperties
    
    override var title: String {
        didSet {
            updateTrafficLights()
            super.title = title
        }
    }
    
    init(isPrivate: Bool = false, restoresTab: Bool = true) {
        appProperties = AXAppProperties(isPrivate: isPrivate, restoresTab: restoresTab)
        super.init(
            contentRect: appProperties.windowFrame,
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
        appProperties.window = self
        backgroundColor = .textBackgroundColor // NSWindow has hidden NSVisualEffectView, to remove we must use this code
        self.contentView = appProperties.contentView
        updateTrafficLights()
        
        if !appProperties.sidebarToggled {
            hideTrafficLights(true)
        }
        
        if appProperties.isPrivate {
            self.appearance = .init(named: .darkAqua)
        }
    }
    
    // MARK: - Window Functions
    override func makeKey() {
        // Make searchField first responder
        if appProperties.searchFieldShown {
            let window1 = childWindows![0]
            window1.makeKey()
            window1.makeFirstResponder(appProperties.popOver.searchField)
            return
        }
        
        super.makeKey()
    }
    
    func windowDidResize(_ notification: Notification) {
        updateTrafficLights()
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        appProperties.isFullScreen = true
        appProperties.sidebarView.enteredFullScreen()
        appProperties.webContainerView.enteredFullScreen()
        _hideTrafficLights(false)
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        appProperties.isFullScreen = false
        hideTrafficLights(!appProperties.sidebarToggled)
        appProperties.sidebarView.exitedFullScreen()
        appProperties.webContainerView.exitedFullScreen()
    }
    
    override func close() {
        // Save the window
        appProperties.windowFrame = self.frame
        appProperties.saveProperties()
        
        appProperties.sidebarView.tabView.tabStackView.arrangedSubviews.forEach { view in
            (view as! AXSidebarTabButton).stopObserving()
            view.removeFromSuperview()
        }
        
        appProperties.webContainerView.stopObserving()
        appProperties.webContainerView.removeDelegates()
        
        AXGlobalProperties.shared.profiles.forEach { $0.saveProperties() }
        
        super.close()
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
}
