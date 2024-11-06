//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//

import AppKit
import WebKit

class AXWebKitProfile {
    weak var appProperties: AXSessionProperties?
    /// Profile
    var profileIdentifier: UUID
    var name: String
    var configuration: WKWebViewConfiguration
    
    /// Tab Groups
    var isCurrent: Bool = false
    var tabGroups: [AXTabGroup]
    var currentTabGroupIndex = 0
    var currentTabGroup: AXTabGroup {
        get { tabGroups[currentTabGroupIndex] }
    }
    
    init(name: String, appProperties: AXSessionProperties?) {
        // After recieving profile identifier, find the UserDefaults associated with it. And find the name.
        self.profileIdentifier = .init(uuidString: "0a0a0eab-b697-49e8-a9d3-148ead1f42d4")! // TODO: FIX THIS LATER
        self.name = name
        self.appProperties = appProperties
        
        self.configuration = .init()
        configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier: profileIdentifier)
        
        let tabGroup = AXTabGroup(name: "Default", appProperties)
        tabGroups = [tabGroup]
    }
    
    func deleteProfile() async {
        do {
            try await WKWebsiteDataStore.remove(forIdentifier: profileIdentifier)
        } catch {
            print("Removing profile failed with error: \(error)")
        }
    }
}
