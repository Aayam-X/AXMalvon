//
//  AXProfileManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-01.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import Foundation

var AX_profiles: [AXBrowserProfile] = []

class AXProfileManager {
    weak var appProperties: AXAppProperties!
    
    init(_ appProperties: AXAppProperties!) {
        self.appProperties = appProperties
    }
    
    func initializeProfile() {
//        appProperties.currentProfile = AX_profiles[0]
//
//        appProperties.currentProfile.retriveProperties()
//        appProperties.webViewConfiguration = appProperties.currentProfile.webViewConfiguration
//        appProperties.currentProfile.retriveTabs()
    }
    
    func switchProfiles(to: Int) {
//        updateValuesForCurrentProfile()
//
//        let profile = AX_profiles[safe: to]
//        guard var profile = profile else { return }
//        profile.retriveProperties()
//        appProperties.webViewConfiguration = profile.webViewConfiguration
//        profile.retriveTabs()
//
//        appProperties.AX_currentProfile = to
//        appProperties.currentTab = profile.currentTab
//        appProperties.tabs = profile.tabs
//        appProperties.previousTab = profile.previousTab
    }
    
    func updateValuesForCurrentProfile() {
//        let profile = AX_profiles[safe: appProperties.AX_currentProfile]
//        guard var profile = profile else { return }
//
//        profile.currentTab = appProperties.currentTab
//        profile.previousTab = appProperties.previousTab
//        profile.tabs = appProperties.tabs
//        profile.webViewConfiguration = appProperties.webViewConfiguration
//
//        profile.saveProperties()
    }
}
