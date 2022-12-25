//
//  AXAppProperties.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-05.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

// Every AXWindow will have one instance of this
class AXAppProperties {
    // Views
    let sidebarView: AXSideBarView
    let splitView: AXSplitView
    let contentView: AXContentView
    let webContainerView: AXWebContainerView
    var window: AXWindow! = nil
    
    // Other Views
    let popOver: AXSearchFieldPopoverView
    let progressBar: AXRectangularProgressIndicator
    let findBar: AXWebViewFindView
    
    // Other
    let tabManager: AXTabManager
    
    // State Variables
    var isFullScreen: Bool = false
    var searchFieldShown: Bool = false
    var sidebarToggled: Bool
    var windowFrame: NSRect
    var sidebarWidth: CGFloat
    
    // Variables
    var tabs: [AXTabItem] = []
    var currentTab = -1
    
    // Private Browsing
    var configuration: WKWebViewConfiguration?
    
    var isPrivate: Bool
    
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
        
        if !isPrivate {
            if restoresTab {
                if let data = UserDefaults.standard.data(forKey: "tabs") {
                    do {
                        let decoder = JSONDecoder()
                        let tabs = try decoder.decode([AXTabItem].self, from: data)
                        self.tabs = tabs
                    } catch {
                        print("Unable to Decode Tabs (\(error.localizedDescription))")
                    }
                }
            }
        }
        
        self.isPrivate = isPrivate
        
        sidebarView.appProperties = self
        contentView.appProperties = self
        webContainerView.appProperties = self
        tabManager.appProperties = self
        popOver.appProperties = self
        findBar.appProperties = self
        
        if isPrivate {
            configuration = WKWebViewConfiguration()
            configuration?.processPool = WKProcessPool()
            configuration?.websiteDataStore = .nonPersistent()
        }
    }
    
    func saveProperties() {
        UserDefaults.standard.set(sidebarToggled, forKey: "sidebarToggled")
        UserDefaults.standard.set(NSStringFromRect(windowFrame), forKey: "windowFrame")
        UserDefaults.standard.set(sidebarWidth, forKey: "sidebarWidth")
        
        if !isPrivate {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(tabs)
                UserDefaults.standard.set(data, forKey: "tabs")
            } catch {
                print("Unable to Encode Tabs (\(error.localizedDescription))")
            }
        }
    }
}
