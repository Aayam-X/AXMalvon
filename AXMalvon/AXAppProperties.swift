//
//  AXAppProperties.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-05.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

// Every AXWindow will have one instance of this
class AXAppProperties {
    // Views
    let contentView: AXContentView
    let sidebarView: AXSideBarView
    let webContainerView: AXWebContainerView
    weak var window: AXWindow! = nil
    let splitView: AXSplitView
    
    // Other Views
    let popOver: AXSearchFieldPopoverView
    var profileList: AXProfileListView?
    let progressBar: AXRectangularProgressIndicator
    let findBar: AXWebViewFindView
    
    // Other
    let tabManager: AXTabManager
    var profileManager: AXProfileManager?
    var webViewConfiguration: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        
        return config
    }()
    
    // State Variables
    var isFullScreen: Bool = false
    var searchFieldShown: Bool = false
    var sidebarToggled: Bool
    var windowFrame: NSRect
    var sidebarWidth: CGFloat
    
    // Variables
    var AX_currentProfile = 0
    var isPrivate: Bool
    
    var currentTab = -1 { willSet { previousTab = currentTab } }
    var previousTab = -1
    var tabs: [AXTabItem] = []
    var previouslyClosedTabs: [URL] = []
    
    init(isPrivate: Bool = false, restoresTab: Bool = true) {
        // Get UserDefaults
        sidebarToggled = UserDefaults.standard.bool(forKey: "sidebarToggled")
        sidebarWidth = (UserDefaults.standard.object(forKey: "sidebarWidth") as? CGFloat) ?? 225.0
        
        if let s = UserDefaults.standard.string(forKey: "windowFrame") {
            windowFrame = NSRectFromString(s)
        } else {
            windowFrame = NSMakeRect(100, 100, NSScreen.main!.frame.width/2, NSScreen.main!.frame.height/2)
        }
        
        // Initialize Views
        sidebarView = AXSideBarView()
        splitView = AXSplitView()
        contentView = AXContentView()
        webContainerView = AXWebContainerView()
        tabManager = AXTabManager()
        popOver = AXSearchFieldPopoverView()
        progressBar = AXRectangularProgressIndicator()
        findBar = AXWebViewFindView()
        self.isPrivate = isPrivate
        
        if !isPrivate {
            profileManager = AXProfileManager(self)
            profileList = AXProfileListView(self)
            profileManager!.initializeProfile()
        } else {
            webViewConfiguration.processPool = .init()
        }
        
        sidebarView.appProperties = self
        contentView.appProperties = self
        webContainerView.appProperties = self
        tabManager.appProperties = self
        popOver.appProperties = self
        findBar.appProperties = self
    }
    
    func saveProperties() {
        UserDefaults.standard.set(sidebarToggled, forKey: "sidebarToggled")
        UserDefaults.standard.set(NSStringFromRect(windowFrame), forKey: "windowFrame")
        UserDefaults.standard.set(sidebarWidth, forKey: "sidebarWidth")
    }
}
