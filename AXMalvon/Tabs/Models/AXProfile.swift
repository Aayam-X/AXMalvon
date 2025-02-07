//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

struct AXProfileData: Codable {
    var configID: String
    var selectedTabGroupIndex: Int

    // Convert to dictionary for UserDefaults storage
    func toDictionary() -> [String: Any] {
        return [
            "id": configID,
            "i": selectedTabGroupIndex,
        ]
    }

    // Create from a dictionary loaded from UserDefaults
    static func fromDictionary(_ dictionary: [String: Any]) -> AXProfileData? {
        guard let configID = dictionary["id"] as? String,
            let selectedTabGroupIndex = dictionary["i"] as? Int
        else { return nil }

        return AXProfileData(
            configID: configID, selectedTabGroupIndex: selectedTabGroupIndex)
    }
}

class AXProfile {
    var name: String
    var baseConfiguration: WKWebViewConfiguration
    var tabGroups: [AXTabGroup] = []
    weak var currentTabGroup: AXTabGroup!

    var historyManager: AXHistoryManager?

    var hasLoadedTabs: Bool = false

    var currentTabGroupIndex = 0 {
        didSet {
            currentTabGroup = tabGroups[currentTabGroupIndex]
        }
    }

    convenience init(name: String) {
        // Check if the profile already exists
        if let profileData = AXProfile.loadProfile(name: name) {
            let config = AXProfile.createConfig(with: profileData.configID)

            self.init(
                name: name, config: config, loadsDefaultData: true,
                configID: profileData.configID)

            mxPrint(
                "Current Tab Group Index: \(profileData.selectedTabGroupIndex)")

            #if !DEBUG
                self.currentTabGroupIndex = profileData.selectedTabGroupIndex
            #endif
        } else {
            let newProfile = AXProfile.createNewProfile(name: name)
            self.init(
                name: name, config: newProfile.config, loadsDefaultData: true,
                configID: newProfile.id)
        }
    }

    init(
        name: String, config: WKWebViewConfiguration, loadsDefaultData: Bool,
        configID: String? = nil, usingTabGroup: AXTabGroup? = nil
    ) {
        self.name = name
        self.baseConfiguration = config
        self.tabGroups = []

        if let configID {
            self.historyManager = AXHistoryManager(fileName: configID)
        }

        config.enableDefaultMalvonPreferences()

        if loadsDefaultData, usingTabGroup == nil {
            loadTabGroups()
            self.currentTabGroup = tabGroups[currentTabGroupIndex]
        } else {
            self.tabGroups = [usingTabGroup ?? AXTabGroup(name: "NULL")]
            self.currentTabGroup = tabGroups[0]
        }
    }

    // MARK: - Profile Defaults
    class private func createNewProfile(name: String) -> (
        id: String, config: WKWebViewConfiguration
    ) {
        let defaults = UserDefaults.standard
        var profiles =
            defaults.dictionary(forKey: "Profiles") as? [String: [String: Any]]
            ?? [:]

        // Create new profile data
        let newProfileData = AXProfileData(
            configID: UUID().uuidString, selectedTabGroupIndex: 0)

        // Save the new profile data as a dictionary
        profiles[name] = newProfileData.toDictionary()
        defaults.set(profiles, forKey: "Profiles")

        // Create a new WKWebView configuration
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore(forIdentifier: UUID())
        return (newProfileData.configID, config)
    }

    class func loadProfile(name: String) -> AXProfileData? {
        let defaults = UserDefaults.standard
        let profiles =
            defaults.dictionary(forKey: "Profiles") as? [String: [String: Any]]
            ?? [:]

        // Load and convert back to AXProfileData
        if let profileDict = profiles[name] {
            return AXProfileData.fromDictionary(profileDict)
        }

        return nil
    }

    class func createConfig(with id: String) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        if let uuid = UUID(uuidString: id) {
            config.websiteDataStore = WKWebsiteDataStore(forIdentifier: uuid)
        }
        return config
    }

    // MARK: - Tab Groups JSON
    private var fileURL: URL {
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!

        #if DEBUG
            let directoryURL = appSupportDirectory.appendingPathComponent(
                "Malvon-Debug", isDirectory: true)
        #else
            let directoryURL = appSupportDirectory.appendingPathComponent(
                "Malvon", isDirectory: true)
        #endif

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(
                at: directoryURL, withIntermediateDirectories: true,
                attributes: nil)
        }

        return directoryURL.appendingPathComponent("\(name)-TabGroups.json")
    }

    func saveTabGroups() {
        guard hasLoadedTabs else { return }
        hasLoadedTabs = false

        #if !DEBUG
            let defaults = UserDefaults.standard

            var profiles =
                defaults.dictionary(forKey: "Profiles")
                as? [String: [String: Any]] ?? [:]
            profiles[name, default: [:]]["i"] = currentTabGroupIndex
            defaults.set(profiles, forKey: "Profiles")
        #endif

        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(tabGroups)
            try data.write(to: fileURL)
        } catch {
            mxPrint("Failed to save tab groups: \(error)")
        }
    }

    func loadTabGroups() {
        hasLoadedTabs = true

        let decoder = JSONDecoder()
        decoder.userInfo[.webviewConfiguration] = self.baseConfiguration

        do {
            let data = try Data(contentsOf: fileURL)
            tabGroups = try decoder.decode([AXTabGroup].self, from: data)
        } catch {
            mxPrint(
                "Failed to load tab groups or file does not exist: \(error)")
            tabGroups = [AXTabGroup(name: "Untitled Tab Group")]
        }
    }
}

class AXPrivateProfile: AXProfile {
    //  override var tabGroups: [AXTabGroup] = [.init(name: "Private Tab Group")]

    init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()

        let privateTabGroup = AXTabGroup(name: "Private Tab Group")
        privateTabGroup.color = .black

        super.init(
            name: "Private", config: config, loadsDefaultData: false,
            usingTabGroup: privateTabGroup)
    }

    override func saveTabGroups() {
        // Do nothing
    }

    override func loadTabGroups() {
        // Do nothing
    }
}

// Experimental Features

//        let experimentalFeatures = WKPreferences.value(forKey: "experimentalFeatures")
// i have to call - (void)_setEnabled:(BOOL)value forFeature:(_WKFeature *)feature WK_API_AVAILABLE(macos(10.12), ios(10.0));
//        // experimentalFeatures is an array of [_WKFeature]
//        // how do i do this? i want to set true for all of them
//        print(experimentalFeatures)

//        let preferences = configuration.preferences
//
//        if let experimentalFeatures = WKPreferences.value(forKey: "experimentalFeatures") as? [AnyObject] {
//            for feature in experimentalFeatures {
//                // Call the private API method _setEnabled:forFeature: using Objective-C runtime
//                if let feature = feature as? NSObject {
//                    let selector = NSSelectorFromString("_setEnabled:forFeature:")
//                    if preferences.responds(to: selector) {
//                        preferences.perform(selector, with: false as NSNumber, with: feature)
//                    }
//                }
//            }
//        } else {
//            print("Unable to access experimentalFeatures.")
//        }
