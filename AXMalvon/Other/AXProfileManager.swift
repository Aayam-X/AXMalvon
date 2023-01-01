//
//  AXProfileManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-01.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import Foundation

var AX_profiles: [AXBrowserProfile] = []
var AX_currentProfile = 0

class AXProfileManager {
    weak var appProperties: AXAppProperties!
    
    func switchProfiles(to: Int) {
        updateValuesForCurrentProfile()
        
        let profile = AX_profiles[safe: to]
        guard let profile = profile else { return }
        
        AX_currentProfile = to
        appProperties.currentTab = profile.currentTab
        appProperties.tabs = profile.tabs
        appProperties.previousTab = profile.previousTab
        AXMalvon_WebViewConfiguration = profile.webViewConfiguration
    }
    
    func updateValuesForCurrentProfile() {
        let profile = AX_profiles[safe: AX_currentProfile]
        guard var profile = profile else { return }
        
        profile.currentTab = appProperties.currentTab
        profile.previousTab = appProperties.previousTab
        profile.tabs = appProperties.tabs
    }
}
