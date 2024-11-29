//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-17.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Foundation
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
        else {
            return nil
        }
        return AXProfileData(
            configID: configID, selectedTabGroupIndex: selectedTabGroupIndex)
    }
}

class AXProfile {
    let name: String
    var configuration: WKWebViewConfiguration
    var tabGroups: [AXTabGroup] = []
    var currentTabGroup: AXTabGroup

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

            self.init(name: name, config: config, loadsDefaultData: true)
            print(
                "Current Tab Group Index: \(profileData.selectedTabGroupIndex)")
            self.currentTabGroupIndex = profileData.selectedTabGroupIndex
        } else {
            let config = AXProfile.createNewProfile(name: name)
            self.init(name: name, config: config, loadsDefaultData: true)
        }
    }

    init(name: String, config: WKWebViewConfiguration, loadsDefaultData: Bool) {
        self.name = name
        self.configuration = config
        self.tabGroups = [.init(name: "Untitled Tab Group")]
        currentTabGroup = tabGroups[0]

        addOtherConfigs()

        if loadsDefaultData {
            loadTabGroups()
        }
    }

    // MARK: - Profile Defaults
    class private func createNewProfile(name: String) -> WKWebViewConfiguration
    {
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
        return config
    }

    class private func loadProfile(name: String) -> AXProfileData? {
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

    private class func createConfig(with id: String) -> WKWebViewConfiguration {
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
                "AXMalvon", isDirectory: true)
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
            print("Failed to save tab groups: \(error)")
        }
    }

    func loadTabGroups() {
        hasLoadedTabs = true

        let decoder = JSONDecoder()
        decoder.userInfo[.webConfiguration] = self.configuration

        do {
            let data = try Data(contentsOf: fileURL)
            tabGroups = try decoder.decode([AXTabGroup].self, from: data)
        } catch {
            print("Failed to load tab groups or file does not exist: \(error)")
            tabGroups = [AXTabGroup(name: "Untitled Tab Group")]
        }
    }

    // MARK: - Configuration Features
    func addOtherConfigs() {
        let AX_DEFAULT_WEBVIEW_CONFIGURATIONS = [
            "fullScreenEnabled",
            "allowsPictureInPictureMediaPlayback",
            "acceleratedDrawingEnabled",
            "largeImageAsyncDecodingEnabled",
            "animatedImageAsyncDecodingEnabled",
            "developerExtrasEnabled",
            "loadsImagesAutomatically",
            "acceleratedCompositingEnabled",
            "canvasUsesAcceleratedDrawing",
            "localFileContentSniffingEnabled",
            "appNapEnabled",
        ]

        for config in AX_DEFAULT_WEBVIEW_CONFIGURATIONS {
            configuration.preferences.setValue(true, forKey: config)
        }

        configuration.preferences.setValue(
            false, forKey: "backspaceKeyNavigationEnabled")
    }

    func enableContentBlockers() {
        //        let extensionLoader = AX_wBlockExtension()
        //
        //        extensionLoader.getContentBlockerURLPath { blockerListURL in
        //            guard let blockerListURL else { return }
        //
        //            Task(priority: .background) {
        //                try? self.loadContentBlocker(at: blockerListURL)
        //            }
        //        }
    }

    func enableYouTubeAdBlocker() {
        let userScript = WKUserScript(
            source: AX_DEFAULT_YOUTUBE_BLOCKER_SCRIPT,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(userScript)
    }

    func loadContentBlocker(at url: URL) throws {
        let blockerListData = try Data(contentsOf: url)
        guard
            let blockerListString = String(
                data: blockerListData, encoding: .utf8)
        else {
            print("Failed to decode blocker list data.")
            return
        }

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "ContentBlocker",
            encodedContentRuleList: blockerListString
        ) { contentRuleList, error in
            guard let contentRuleList else { return }
            self.configuration.userContentController.add(contentRuleList)
        }
    }

}

class AXPrivateProfile: AXProfile {
    init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        super.init(name: "Private", config: config, loadsDefaultData: false)
    }

    override func saveTabGroups() {
        // Do nothing
    }

    override func loadTabGroups() {
        // Do nothing
    }
}

let AX_DEFAULT_YOUTUBE_BLOCKER_SCRIPT = """
    (function(){let ytInitialPlayerResponse=null;Object.defineProperty(window,"ytInitialPlayerResponse",{get:()=>ytInitialPlayerResponse,set:(data)=>{if(data)data.adPlacements=[];ytInitialPlayerResponse=data},configurable:true})})();(function(){const originalFetch=window.fetch;window.fetch=async(...args)=>{const response=await originalFetch(...args);if(response.url.includes("/youtubei/v1/player")){const originalText=response.text.bind(response);response.text=()=>originalText().then((data)=>data.replace(/"adPlacements"/g,'"odPlacements"'))}return response}})();(function(){const skipAds=()=>{const skipButton=document.querySelector(".videoAdUiSkipButton, .ytp-ad-skip-button");if(skipButton)skipButton.click();const adOverlay=document.querySelector(".ad-showing");if(adOverlay){const video=document.querySelector("video");if(video){video.playbackRate=10;video.isMuted=1}}};const removeInlineAds=()=>{const adContainer=document.querySelector("#player-ads");if(adContainer)adContainer.remove()};const adBlockerInterval=setInterval(()=>{skipAds();removeInlineAds()},300);window.addEventListener("unload",()=>clearInterval(adBlockerInterval))})();
    """
