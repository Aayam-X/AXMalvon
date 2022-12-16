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
    let popOver: AXSearchFieldPopoverView
    var window: AXWindow! = nil
    
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
    
    var isPrivate = false {
        didSet {
            // No need to check if true or false cause it's always going to be set to false.
            configuration = WKWebViewConfiguration()
            configuration?.processPool = WKProcessPool()
            configuration?.websiteDataStore = .nonPersistent()
        }
    }
    
    init() {
        sidebarToggled = UserDefaults.standard.bool(forKey: "sidebarToggled")
        sidebarWidth = (UserDefaults.standard.object(forKey: "sidebarWidth") as? CGFloat) ?? 225.0
        
        if let s = UserDefaults.standard.string(forKey: "windowFrame") {
            windowFrame = NSRectFromString(s)
        } else {
            windowFrame = NSMakeRect(100, 100, NSScreen.main!.frame.width/2, NSScreen.main!.frame.height/2)
        }
        
        sidebarView = AXSideBarView()
        splitView = AXSplitView()
        contentView = AXContentView()
        webContainerView = AXWebContainerView()
        tabManager = AXTabManager()
        popOver = AXSearchFieldPopoverView()
        
        sidebarView.appProperties = self
        contentView.appProperties = self
        webContainerView.appProperties = self
        tabManager.appProperties = self
        popOver.appProperties = self
    }
    
    func saveProperties() {
        UserDefaults.standard.set(sidebarToggled, forKey: "sidebarToggled")
        UserDefaults.standard.set(NSStringFromRect(windowFrame), forKey: "windowFrame")
        UserDefaults.standard.set(sidebarWidth, forKey: "sidebarWidth")
    }
    
    // NSApplication Encode Restorable State
    func restore_saveProperties() {
        saveProperties()
        
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
    
    func restore_getProperties() {
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
