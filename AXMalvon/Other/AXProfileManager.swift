//
//  AXProfileManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-01.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import Foundation

class AXProfileManager {
    weak var appProperties: AXAppProperties!
    
    init(_ appProperties: AXAppProperties!) {
        self.appProperties = appProperties
    }
    
    func switchProfiles(to: Int) {
        // Save the current profile
        appProperties.currentProfile.quickSaveProperties()
        appProperties.tabs[appProperties.currentProfileIndex] = appProperties.currentTabs
        
        // Update the current profile
        appProperties.profileList?.updateSelection(from: appProperties.currentProfileIndex, to: to)
        appProperties.currentProfileIndex = to
        appProperties.currentTabs = appProperties.tabs[to]
        
        appProperties.webViewConfiguration = appProperties.currentProfile.webViewConfiguration
        
        appProperties.sidebarView.switchedProfile()
    }
}
