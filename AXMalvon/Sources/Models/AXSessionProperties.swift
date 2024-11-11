//
//  AXSessionProperties.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-05.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

// Every AXWindow will have one instance of this
class AXSessionProperties {
    /// Window Properties
    var window: AXWindow!
    var windowFrame: NSRect
    
    /// View Properties
    lazy var contentView = AXContentView(appProperties: self)
    lazy var containerView = AXWebContainerView(appProperties: self)
    lazy var sidebarView = AXSidebarView(appProperties: self)
    lazy var searchBarWindow = AXSearchBarWindow(appProperties: self)
    
    /// Managers
    lazy var tabManager = AXTabManager(appProperties: self)
    
    init() {
        windowFrame = AXSessionProperties.updateWindowFrame()
    }
    
    static private func updateWindowFrame() -> NSRect {
        if let savedFrameString = UserDefaults.standard.string(forKey: "windowFrame") {
            return NSRectFromString(savedFrameString)
        } else {
            guard let screenFrame = NSScreen.main?.frame else {
                return NSMakeRect(100, 100, 800, 600) // Default size
            }
            return NSMakeRect(100, 100, screenFrame.width / 2, screenFrame.height / 2)
        }
    }
    
    func updateColor(newColor: NSColor) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5 // Adjust duration as needed
            context.allowsImplicitAnimation = true
            
            containerView.layer?.backgroundColor = newColor.withAlphaComponent(0.3).cgColor
            sidebarView.layer?.backgroundColor = newColor.withAlphaComponent(0.3).cgColor
            sidebarView.gestureView.backgroundColor = newColor.withAlphaComponent(0.3)
        }
    }
}
