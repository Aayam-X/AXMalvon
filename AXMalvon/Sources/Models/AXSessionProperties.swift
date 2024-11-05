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
    // Views
    var contentView: AXContentView
    let sidebarView: AXSideBarView
    let webContainerView: AXWebContainerView
    weak var window: AXWindow! = nil
    let splitView: AXSplitView
    
    // Other Views
    let popOver: AXSearchFieldPopoverView
    var profileList: AXProfileListView?
    let progressBar: AXRectangularProgressIndicator
    let findBar: AXWebViewFindView
    
    // Profile related
    var profiles: [AXBrowserProfile] = []
    var currentWebViewConfiguration: WKWebViewConfiguration!
    
    // Managers
    let tabManager: AXTabManager
    var profileManager: AXProfileManager?
    
    // State Variables
    var isFullScreen: Bool = false
    var searchFieldShown: Bool = false
    var sidebarToggled: Bool = true
    var windowFrame: NSRect
    var sidebarWidth: CGFloat
    
    // Variables
    var isPrivate: Bool
    
    var currentProfile: AXBrowserProfile!
    var currentProfileIndex: Int = 0
    var currentTab: AXTabItem!
    var currentTabButton: AXSidebarTabButton!
    
    deinit {
        progressBar.removeFromSuperview()
        popOver.removeFromSuperview()
    }
    
    init(isPrivate: Bool = false, restoresTab: Bool = true) {
        sidebarWidth = (UserDefaults.standard.object(forKey: "sidebarWidth") as? CGFloat) ?? 225.0
        
        // Retrive the browser profiles
        if !isPrivate {
            if let profileNames = UserDefaults.standard.stringArray(forKey: "Profiles") {
                self.profiles = profileNames.map { AXBrowserProfile(name: $0) }
            } else {
                self.profiles = [.init(name: "Default", 0), .init(name: "Secondary", 1)]
                UserDefaults.standard.set(["Default", "Secondary"], forKey: "Profiles")
            }
        } else {
            let privateProfile = AXPrivateBrowserProfile()
            
            self.currentWebViewConfiguration = WKWebViewConfiguration()
            self.currentWebViewConfiguration.websiteDataStore = .nonPersistent()
            self.currentWebViewConfiguration.processPool = WKProcessPool()
            
            currentProfile = privateProfile
            profiles.append(privateProfile)
        }
        
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
        
        profileManager = AXProfileManager(self)
        
        if !isPrivate {
            profileList = AXProfileListView(self)
        }
        
        sidebarView.appProperties = self
        contentView.appProperties = self
        webContainerView.appProperties = self
        tabManager.appProperties = self
        popOver.appProperties = self
        findBar.appProperties = self
    }
    
    func saveProperties() {
        UserDefaults.standard.set(NSStringFromRect(windowFrame), forKey: "windowFrame")
        UserDefaults.standard.set(sidebarWidth, forKey: "sidebarWidth")
    }
}
