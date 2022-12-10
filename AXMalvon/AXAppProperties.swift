//
//  AXAppProperties.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-05.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

// Every AXWindow will have one instance of this
class AXAppProperties {
    // Views
    let sidebarView: AXSideBarView
    let splitView: AXSplitView
    let contentView: AXContentView
    let webContainerView: AXWebContainerView
    
    // State Variables
    var isFullScreen: Bool = false
    var sidebarToggled: Bool
    var windowFrame: NSRect
    
    // Variables
    var tabs = [AXTabItem]()
    var currentTab = 0
    
    init() {
        sidebarToggled = (UserDefaults.standard.object(forKey: "sidebarToggled") as? Bool) ?? true
        
        if let s = UserDefaults.standard.string(forKey: "windowFrame") {
            windowFrame = NSRectFromString(s)
        } else {
            windowFrame = NSMakeRect(100, 100, NSScreen.main!.frame.width/2, NSScreen.main!.frame.height/2)
        }
        
        sidebarView = AXSideBarView()
        splitView = AXSplitView()
        contentView = AXContentView()
        webContainerView = AXWebContainerView()
        
        sidebarView.appProperties = self
        contentView.appProperties = self
        webContainerView.appProperties = self
    }
    
    func saveProperties() {
        UserDefaults.standard.set(sidebarToggled, forKey: "sidebarToggled")
        UserDefaults.standard.set(NSStringFromRect(windowFrame), forKey: "windowFrame")
    }
}
