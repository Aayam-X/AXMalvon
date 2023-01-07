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
    
    var userEmail: String
    var userPassword: String
    var hasPaid: Bool = false
    
    init() {
        userEmail = UserDefaults.standard.string(forKey: "UserEmail") ?? ""
        userPassword = UserDefaults.standard.string(forKey: "UserPassword") ?? ""
    }
    
    func save() {
        UserDefaults.standard.set(userEmail, forKey: "UserEmail")
        UserDefaults.standard.set(userPassword, forKey: "UserPassword")
    }
}
