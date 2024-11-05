//
//  AXPreferenceWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-27.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

class AXPreferenceWindow: NSWindow, NSToolbarDelegate {
    init() {
        super.init(
            contentRect: .init(x: 200, y: 200, width: 800, height: 600),
            styleMask: [.closable, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.center()
        self.contentView = AXPreferenceView()
        
        self.title = "General"
        
        let toolbar = NSToolbar()
        self.toolbar = toolbar
        
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        backgroundColor = .textBackgroundColor // NSWindow stuff
        
        updateTrafficLights()
    }
    
    /// Update the position of the window buttons
    fileprivate func updateTrafficLights() {
        let closeButton = standardWindowButton(.closeButton)!
        closeButton.frame.origin.x = 15.0
        closeButton.frame.origin.y = 2.0
        
        let miniaturizeButton = standardWindowButton(.miniaturizeButton)!
        miniaturizeButton.frame.origin.x = 35.0
        miniaturizeButton.frame.origin.y = 2.0
        
        let zoomButton = standardWindowButton(.zoomButton)!
        zoomButton.frame.origin.x = 55.0
        zoomButton.frame.origin.y = 2.0
    }
}
