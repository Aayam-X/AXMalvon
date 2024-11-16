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
    
    // Profile
    var profileIdentifier: UUID
    var name: String
    var configuration: WKWebViewConfiguration
    
    // Tab Groups
    var isCurrent: Bool = false
    var tabGroups: [AXTabGroup]
    var currentTabGroupIndex = 0 {
        didSet {
            tabGroups[oldValue].isCurrentTabGroup = false
            tabGroups[currentTabGroupIndex].isCurrentTabGroup = true
        }
    }
    
    var currentTabGroup: AXTabGroup {
        get { tabGroups[currentTabGroupIndex] }
    }
    
    init(name: String, appProperties: AXSessionProperties?) {
        // Check if we already have a stored profile identifier in UserDefaults
        if let storedUUIDString = UserDefaults.standard.string(forKey: "profileIdentifier-\(name)") {
            // If found, use the stored UUID
            self.profileIdentifier = UUID(uuidString: storedUUIDString)!
        } else {
            // Otherwise, generate a new UUID and save it
            self.profileIdentifier = UUID()
            // Store the UUID string in UserDefaults
            UserDefaults.standard.set(self.profileIdentifier.uuidString, forKey: "profileIdentifier-\(name)")
        }
        
        
        
        self.name = name
        self.appProperties = appProperties
        
        self.configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier: profileIdentifier)
        
        /// Load Tab Groups
        if let data = UserDefaults.standard.data(forKey: "tabGroups_\(profileIdentifier.uuidString)") {
            do {
                let decoder = JSONDecoder()
                decoder.userInfo[.appPropertiesKey] = appProperties
                decoder.userInfo[.webConfigKey] = configuration
                tabGroups = try decoder.decode([AXTabGroup].self, from: data)
                print("Tab groups loaded successfully!")
            } catch {
                print("Failed to load tab groups: \(error)")
                let tabGroup = AXTabGroup(name: "Default", appProperties)
                let tabGroup2 = AXTabGroup(name: "Other", color: .yellow, appProperties)
                tabGroups = [tabGroup, tabGroup2]
                
                tabGroups[0].isCurrentTabGroup = true
            }
        } else {
            let tabGroup = AXTabGroup(name: "Default", appProperties)
            let tabGroup2 = AXTabGroup(name: "Other", color: .yellow, appProperties)
            tabGroups = [tabGroup, tabGroup2]
            
            tabGroups[0].isCurrentTabGroup = true
        }
        
        self.addExtraConfigurations()
    }
    
    func deleteProfile() async {
        do {
            try await WKWebsiteDataStore.remove(forIdentifier: profileIdentifier)
            // Remove the UUID from UserDefaults when the profile is deleted
            UserDefaults.standard.removeObject(forKey: "profileIdentifier")
        } catch {
            print("Removing profile failed with error: \(error)")
        }
    }
    
    func saveAllTabGroups() {
        do {
            let data = try JSONEncoder().encode(tabGroups)
            UserDefaults.standard.set(data, forKey: "tabGroups_\(profileIdentifier.uuidString)")
            print("Tab groups saved successfully!")
        } catch {
            print("Failed to save tab groups: \(error)")
        }
    }
    
    func loadTabGroups() {
        if let data = UserDefaults.standard.data(forKey: "tabGroups_\(profileIdentifier.uuidString)") {
            do {
                let decoder = JSONDecoder()
                decoder.userInfo[.appPropertiesKey] = appProperties
                tabGroups = try decoder.decode([AXTabGroup].self, from: data)
                print("Tab groups loaded successfully!")
            } catch {
                print("Failed to load tab groups: \(error)")
            }
        }
    }
    
    func addExtraConfigurations() {
        configuration.preferences.setValue(true, forKey: "offlineApplicationCacheIsEnabled")
        configuration.preferences.setValue(true, forKey: "fullScreenEnabled")
        configuration.preferences.setValue(true, forKey: "allowsPictureInPictureMediaPlayback")
        configuration.preferences.setValue(true, forKey: "acceleratedDrawingEnabled")
        configuration.preferences.setValue(true, forKey: "largeImageAsyncDecodingEnabled")
        configuration.preferences.setValue(true, forKey: "animatedImageAsyncDecodingEnabled")
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        configuration.preferences.setValue(true, forKey: "loadsImagesAutomatically")
        configuration.preferences.setValue(true, forKey: "acceleratedCompositingEnabled")
        configuration.preferences.setValue(true, forKey: "canvasUsesAcceleratedDrawing")
        configuration.preferences.setValue(true, forKey: "localFileContentSniffingEnabled")
        configuration.preferences.setValue(true, forKey: "usesPageCache")
        configuration.preferences.setValue(true, forKey: "aggressiveTileRetentionEnabled")
        configuration.preferences.setValue(true, forKey: "appNapEnabled")
        configuration.preferences.setValue(true, forKey: "aggressiveTileRetentionEnabled")
        configuration.preferences.setValue(false, forKey: "backspaceKeyNavigationEnabled")
    }
}

extension CodingUserInfoKey {
    static let webConfigKey = CodingUserInfoKey(rawValue: "webConfigKey")!
}

