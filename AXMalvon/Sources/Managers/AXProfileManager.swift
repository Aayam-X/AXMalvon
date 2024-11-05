//
//  AXProfileManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-01.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import Foundation

class AXProfileManager {
    weak var appProperties: AXAppProperties!
    
    init(_ appProperties: AXAppProperties!) {
        self.appProperties = appProperties
        
        // Ignore when appProperties is private
        if appProperties.isPrivate { return }
        
        
        // Update the current profile
        guard let profile = appProperties.profiles[safe: appProperties.currentProfileIndex] else { return }
        
        let configuration = AXGlobalProperties.shared.profiles[appProperties.currentProfileIndex].configuration
        
        appProperties.currentProfile = profile
        appProperties.currentWebViewConfiguration = configuration
    }
    
    func switchProfiles(to: Int) {
        // Save the current profile
        appProperties.currentProfile?.saveProperties()
        
        // Update the current profile
        guard let newProfile = appProperties.profiles[safe: to] else { return }
        appProperties.currentProfile = newProfile
        
        let newConfiguration = AXGlobalProperties.shared.profiles[to].configuration
        
        appProperties.currentWebViewConfiguration = newConfiguration
        appProperties.profileList?.updateSelection(from: appProperties.currentProfileIndex, to: to)
        
        appProperties.currentProfileIndex = to
        appProperties.sidebarView.switchedProfile()
    }
}
