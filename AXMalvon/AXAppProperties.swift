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
    // Tabs
    var tabs = [[AXTabItem]]()
    
    var currentTabs = [AXTabItem]()
    
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
    
    // Other
    let tabManager: AXTabManager
    var profileManager: AXProfileManager?
    var privateBrowsingProfile: AXPrivateBrowserProfile?
    var webViewConfiguration: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        
        return config
    }()
    
    // State Variables
    var isFullScreen: Bool = false
    var searchFieldShown: Bool = false
    var sidebarToggled: Bool = true
    var windowFrame: NSRect
    var sidebarWidth: CGFloat
    
    // Variables
    var isPrivate: Bool
    
    var currentProfileIndex: Int = 0
    var currentProfile: AXBrowserProfile {
        get {
           AXGlobalProperties.shared.profiles[currentProfileIndex]
        }
    }
    
    var currentTab: AXTabItem!
    var currentTabButton: AXSidebarTabButton!
    
    deinit {
        progressBar.removeFromSuperview()
        popOver.removeFromSuperview()
    }
    
    init(isPrivate: Bool = false, restoresTab: Bool = true) {
        sidebarWidth = (UserDefaults.standard.object(forKey: "sidebarWidth") as? CGFloat) ?? 225.0
        
        if isPrivate {
            privateBrowsingProfile = AXPrivateBrowserProfile()
            webViewConfiguration = privateBrowsingProfile!.webViewConfiguration
        } else {
            self.webViewConfiguration = AXGlobalProperties.shared.profiles[currentProfileIndex].webViewConfiguration
            
            let profiles = AXGlobalProperties.shared.profiles
            
            for profile in profiles {
                let configuration = profile.webViewConfiguration
                
                let profileTabs: [AXTabItem]!
                
                if !profile.urls.isEmpty {
                    profileTabs = profile.urls.map { url in
                        let webView = AXWebView(frame: .zero, configuration: configuration)
                        webView.addConfigurations()
                        webView.load(URLRequest(url: url))
                        
                        let tabItem = AXTabItem(view: webView)
                        tabItem.url = url
                        
                        return tabItem
                    }
                } else {
                    let webView = AXWebView(frame: .zero, configuration: configuration)
                    webView.addConfigurations()
                    webView.loadFileURL(newtabURL!, allowingReadAccessTo: newtabURL!)
                    profileTabs = [
                        .init(view: webView)
                    ]
                }
                
                tabs.append(profileTabs)
            }
            
            // I want this to be a reference
            currentTabs = tabs[0]
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
