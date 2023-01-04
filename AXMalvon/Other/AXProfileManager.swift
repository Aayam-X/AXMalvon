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
    
    func switchProfiles(to: Int) {
        // Save the current profile
        appProperties.currentProfile?.saveProperties()
        
        // Update the current profile
        guard let newProfile = AX_profiles[safe: to] else { return }
        appProperties.currentProfile = newProfile
        
        appProperties.webViewConfiguration = newProfile.webViewConfiguration
        appProperties.sidebarView.switchedProfile()
        
        appProperties.currentProfileIndex = to
    }
}
