//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-01.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

struct AXBrowserProfile: Codable {
    var name: String // User default string
    var webViewConfiguration: WKWebViewConfiguration
    var tabs: [AXTabItem] = []
    var previouslyClosedTabs: [URL] = []
    
    var currentTab = -1 {
        willSet {
            previousTab = currentTab
        }
    }
    
    var previousTab = -1
    
    enum CodingKeys: CodingKey {
        case name
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try values.decode(String.self, forKey: .name)
        
        // Create the configuration
        self.webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.websiteDataStore = .nonPersistent()
        
        retriveProperties()
        retriveTabs()
    }
    
    init(name: String) {
        self.name = name
        
        // Create the configuration
        self.webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.websiteDataStore = .nonPersistent()
        
        retriveProperties()
    }
    
    mutating func retriveProperties() {
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
        
        // Retrive the currentTab
        currentTab = UserDefaults.standard.integer(forKey: "\(name)-CurrentTab")
    }
    
    mutating func retriveTabs() {
        // Retrive the tabs
        if let data = UserDefaults.standard.data(forKey: "\(name)-AXTabItem") {
            do {
                let decoder = JSONDecoder()
                self.tabs = try decoder.decode([AXTabItem].self, from: data)
            } catch {
                print("Unable to Decode Tabs (\(error))")
            }
        }
    }
    
    func saveProperties() {
        // Save current tab
        UserDefaults.standard.set(currentTab, forKey: "\(name)-CurrentTab")
        
        // Save tabs
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(tabs)
            UserDefaults.standard.set(data, forKey: "\(name)-AXTabItem")
        } catch {
            print("Unable to Encode Tabs (\(error.localizedDescription))")
        }
        
        // Save cookies
        webViewConfiguration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            setData(cookies, key: "\(name)-HTTPCookie")
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
