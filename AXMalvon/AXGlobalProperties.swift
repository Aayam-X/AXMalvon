//
//  AXGlobalProperties.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-07.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import Foundation

// TODO: Add names to global
class AXGlobalProperties {
    static let shared = AXGlobalProperties()
    
    // User account
    var userEmail: String
    var userPassword: String
    var hasPaid: Bool = false
    
    // Browser Profiles
    var profiles: [AXBrowserProfile] = []
    
    init() {
        userEmail = UserDefaults.standard.string(forKey: "UserEmail") ?? ""
        userPassword = UserDefaults.standard.string(forKey: "UserPassword") ?? ""
        
        if let profileNames = UserDefaults.standard.stringArray(forKey: "Profiles") {
            profiles = profileNames.map { AXBrowserProfile(name: $0) }
        } else {
            profiles = [
                .init(name: "Default", 0),
                .init(name: "Secondary", 1)
            ]
            
            let names = ["Default", "Secondary"]
            UserDefaults.standard.set(names, forKey: "Profiles")
        }
    }
    
    func save() {
        UserDefaults.standard.set(userEmail, forKey: "UserEmail")
        UserDefaults.standard.set(userPassword, forKey: "UserPassword")
    }
}
