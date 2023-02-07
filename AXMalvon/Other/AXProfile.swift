//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-01.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXPrivateBrowserProfile: AXBrowserProfile {
    init() {
        super.init(name: "Private")
        
        webViewConfiguration = .init()
        webViewConfiguration.websiteDataStore = .nonPersistent()
        webViewConfiguration.processPool = .init()
    }
    
    override func retriveProperties() {}
    override func saveProperties() {}
}

class AXBrowserProfile {
    var name: String // User default string
    var index: Int
    var webViewConfiguration: WKWebViewConfiguration
    var urls: [URL] = []
    var previouslyClosedTabs: [URL] = []
    var history: AXHistory
    
    // Configuration
    var icon: String // SF Symbols
    
    lazy var tabStackView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 1.08
        stackView.detachesHiddenViews = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    var currentTab = 0 {
        willSet {
            previousTab = currentTab
        }
    }
    
    var previousTab = -1
    
    init(name: String) {
        self.name = name
        self.history = AXHistory(profileName: name)
        
        // Create the configuration
        self.webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.websiteDataStore = .nonPersistent()
        
        index = UserDefaults.standard.integer(forKey: "\(name)-Index")
        icon = UserDefaults.standard.string(forKey: "\(name)-Icon") ?? "star"
        
        retriveProperties()
    }
    
    init(name: String, _ index: Int) {
        self.name = name
        self.history = AXHistory(profileName: name)
        
        // Create the configuration
        self.webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.websiteDataStore = .nonPersistent()
        
        self.index = index
        UserDefaults.standard.set(index, forKey: "\(name)-Index")
        
        
        self.icon = "star"
        UserDefaults.standard.set(icon, forKey: "\(name)-Icon")
        
        retriveProperties()
    }
    
    func retriveProperties() {
        // Retrive the pool
        if let pool = getDataPool(key: "\(name)-WKProcessPool") {
            webViewConfiguration.processPool = pool
        } else {
            webViewConfiguration.processPool = .init()
            setData(webViewConfiguration.processPool, key: "\(name)-WKProcessPool")
        }
        
        // Retrive the cookies
        if let cookies: [HTTPCookie] = getData(key: "\(name)-HTTPCookie") {
            for cookie in cookies {
                self.webViewConfiguration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
    }
    
    func retriveTabs() {
        // Retrive the tabs
        if let urls = UserDefaults.standard.array(forKey: "\(name)-URLs") as? [URL] {
            self.urls = urls
            currentTab = UserDefaults.standard.integer(forKey: "\(name)-CurrentTab")
        }
    }
    
    func quickSaveProperties() {
        // Save cookies
        webViewConfiguration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            setData(cookies, key: "\(self.name)-HTTPCookie")
        }
    }
    
    func saveProperties() {
        // Save current tab & Index
        UserDefaults.standard.set(currentTab, forKey: "\(name)-CurrentTab")
        UserDefaults.standard.set(index, forKey: "\(name)-Index")
        UserDefaults.standard.set(icon, forKey: "\(name)-Icon")
        
        // Save tabs
        UserDefaults.standard.set(urls, forKey: "\(name)-URLs")
        
        // Save cookies
        webViewConfiguration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            setData(cookies, key: "\(self.name)-HTTPCookie")
        }
    }
}

fileprivate func setData(_ value: Any, key: String) {
    let ud = UserDefaults.standard
    let archivedPool = NSKeyedArchiver.archivedData(withRootObject: value)
    ud.set(archivedPool, forKey: key)
}

fileprivate func getDataPool(key: String) -> WKProcessPool? {
    let ud = UserDefaults.standard
    if let val = ud.value(forKey: key) as? Data,
       let obj = try! NSKeyedUnarchiver.unarchivedObject(ofClass: WKProcessPool.self, from: val) {
        return obj
    }
    
    return nil
}

fileprivate func getData(key: String) -> [HTTPCookie]? {
    let ud = UserDefaults.standard
    if let val = ud.value(forKey: key) as? Data,
       let obj = NSKeyedUnarchiver.unarchiveObject(with: val) as? [HTTPCookie] {
        return obj
    }
    
    return nil
}
