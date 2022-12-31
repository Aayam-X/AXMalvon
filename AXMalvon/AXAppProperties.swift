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
    weak var window: AXWindow! = nil
    
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
    var previouslyClosedTabs: [URL] = []
    
    var currentTab = -1 {
        willSet {
            previousTab = currentTab
        }
    }
    
    var previousTab = -1
    
    var isPrivate: Bool
    
    deinit {
        progressBar.removeFromSuperview()
        popOver.removeFromSuperview()
    }
    
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
        
        if isPrivate {
            AXMalvon_WebViewConfiguration.processPool = .init()
        } else {
            // Retrive the pool
            if let pool = self.getDataPool(key: "pool") {
                AXMalvon_WebViewConfiguration.processPool = pool
            } else {
                AXMalvon_WebViewConfiguration.processPool = WKProcessPool()
                self.setData(AXMalvon_WebViewConfiguration.processPool, key: "pool")
            }
            
            // Retrive the cookies
            if let cookies: [HTTPCookie] = self.getData(key: "AXMalvon-Cookies") {
                for cookie in cookies {
                    AXMalvon_WebViewConfiguration.websiteDataStore.httpCookieStore.setCookie(cookie)
                }
            }
            
            // Restore the tabs
            if restoresTab {
                if let data = UserDefaults.standard.data(forKey: "tabs") {
                    do {
                        let decoder = JSONDecoder()
                        self.tabs = try decoder.decode([AXTabItem].self, from: data)
                    } catch {
                        print("Unable to Decode Tabs (\(error.localizedDescription))")
                    }
                }
            }
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
        
        if !isPrivate {
            saveCookies()
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(tabs)
                UserDefaults.standard.set(data, forKey: "tabs")
            } catch {
                print("Unable to Encode Tabs (\(error.localizedDescription))")
            }
        }
    }
    
    
    // Save webView cookies
    private func saveCookies() {
        if !isPrivate {
            AXMalvon_WebViewConfiguration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                self.setData(cookies, key: "AXMalvon-Cookies")
            }
        }
    }
    
    func setData(_ value: Any, key: String) {
        let ud = UserDefaults.standard
        let archivedPool = NSKeyedArchiver.archivedData(withRootObject: value)
        ud.set(archivedPool, forKey: key)
    }
    
    func getDataPool(key: String) -> WKProcessPool? {
        let ud = UserDefaults.standard
        if let val = ud.value(forKey: key) as? Data,
           let obj = try! NSKeyedUnarchiver.unarchivedObject(ofClass: WKProcessPool.self, from: val) {
            return obj
        }
        
        return nil
    }
    
    func getData(key: String) -> [HTTPCookie]? {
        let ud = UserDefaults.standard
        if let val = ud.value(forKey: key) as? Data,
           let obj = NSKeyedUnarchiver.unarchiveObject(with: val) as? [HTTPCookie] {
            return obj
        }
        
        return nil
    }
}
