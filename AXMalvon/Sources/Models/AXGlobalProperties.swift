//
//  AXGlobalProperties.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-07.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import Foundation
import WebKit

// TODO: Add names to global
class AXGlobalProperties {
    static let shared = AXGlobalProperties()
    
    var userEmail: String
    var userPassword: String
    var hasPaid: Bool = false
    
    var profiles: [AXGlobalBrowserProfile]
    
    init() {
        userEmail = UserDefaults.standard.string(forKey: "UserEmail") ?? ""
        userPassword = UserDefaults.standard.string(forKey: "UserPassword") ?? ""
        
        // Initialize the profiles
        if let profiles = UserDefaults.standard.stringArray(forKey: "Profiles") {
            self.profiles = profiles.map { AXGlobalBrowserProfile(name: $0) }
        } else {
            self.profiles = [
                .init(name: "Default"),
                .init(name: "Secondary")
            ]
            
            // Save profile names
            UserDefaults.standard.set(["Default", "Secondary"], forKey: "Profiles")
        }
    }
    
    func save() {
        profiles.forEach { $0.saveProperties() }
    }
    
    // Save the credentials
    func saveCreds() {
        UserDefaults.standard.set(userEmail, forKey: "UserEmail")
        UserDefaults.standard.set(userPassword, forKey: "UserPassword")
    }
}


class AXGlobalBrowserProfile {
    let name: String
    let configuration: WKWebViewConfiguration
    
    init(name: String) {
        self.name = name
        
        // Create the configuration
        self.configuration = WKWebViewConfiguration()
        self.configuration.processPool = WKProcessPool()
        self.configuration.websiteDataStore = .nonPersistent()
        
        // Retrive the cookies
        retriveProperties()
    }
    
    func retriveProperties() {
        guard let udCookieProperties = UserDefaults.standard.array(forKey: "\(self.name)-BrowserCookies") as? [[HTTPCookiePropertyKey: Any]?] else { return }
        
        for properties in udCookieProperties {
            if let properties = properties {
                if let cookie = HTTPCookie(properties: properties) {
                    self.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                }
            }
        }
    }
    
    func saveProperties() {
        // Save the cookies
        configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let cookieProperties = cookies.map { $0.properties }
            UserDefaults.standard.set(cookieProperties, forKey: "\(self.name)-BrowserCookies")
        }
    }
}
