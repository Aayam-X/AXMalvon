//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
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
            "i": selectedTabGroupIndex
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

let youtubeAdblockingUserScript = WKUserScript(
    source: jsYoutubeAdBlockScript,
    injectionTime: .atDocumentStart,
    forMainFrameOnly: true
)

class AXProfile {
    var name: String
    var configuration: WKWebViewConfiguration
    var tabGroups: [AXTabGroup] = []
    weak var currentTabGroup: AXTabGroup!

    var historyManager: AXHistoryManager!

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
                configurationID: profileData.configID)

            mxPrint(
                "Current Tab Group Index: \(profileData.selectedTabGroupIndex)")

            #if !DEBUG
                self.currentTabGroupIndex = profileData.selectedTabGroupIndex
            #endif
        } else {
            let newProfile = AXProfile.createNewProfile(name: name)
            self.init(
                name: name, config: newProfile.config, loadsDefaultData: true,
                configurationID: newProfile.id)
        }
    }

    init(
        name: String, config: WKWebViewConfiguration, loadsDefaultData: Bool,
        configurationID: String? = nil
    ) {
        self.name = name
        self.configuration = config
        self.tabGroups = []

        if let configurationID {
            self.historyManager = AXHistoryManager(fileName: configurationID)
        }

        addOtherConfigs()

        if loadsDefaultData {
            loadTabGroups()
        }

        enableContentBlockers()

        self.currentTabGroup = tabGroups[currentTabGroupIndex]
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
            mxPrint("Failed to save tab groups: \(error)")
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
            mxPrint(
                "Failed to load tab groups or file does not exist: \(error)")
            tabGroups = [AXTabGroup(name: "Untitled Tab Group")]
        }
    }

    // MARK: - Configuration Features
    func addOtherConfigs() {
        for config in jsAXWebViewConfigurations {
            configuration.preferences.setValue(true, forKey: config)
        }

        configuration.preferences.isElementFullscreenEnabled = true

        configuration.preferences.setValue(
            false, forKey: "backspaceKeyNavigationEnabled")

        // Usage
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

    }

    func enableContentBlockers() {
        AXContentBlockerLoader.shared.enableAdblock(for: configuration)

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
        configuration.userContentController.addUserScript(
            youtubeAdblockingUserScript)
    }

    func disableYouTubeAdBlocker() {
        configuration.userContentController.removeAllUserScripts()
    }

}

class AXPrivateProfile: AXProfile {
    init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        super.init(name: "Private", config: config, loadsDefaultData: false)

        let privateTabGroup = AXTabGroup(name: "Private Tab Group")
        privateTabGroup.color = .black

        self.tabGroups.append(privateTabGroup)
    }

    override func saveTabGroups() {
        // Do nothing
    }

    override func loadTabGroups() {
        // Do nothing
    }
}

// swiftlint:disable line_length
let jsYoutubeAdBlockScript = """
    (function(){let ytInitialPlayerResponse=null;Object.defineProperty(window,"ytInitialPlayerResponse",{get:()=>ytInitialPlayerResponse,set:(data)=>{if(data)data.adPlacements=[];ytInitialPlayerResponse=data},configurable:true})})();(function(){const originalFetch=window.fetch;window.fetch=async(...args)=>{const response=await originalFetch(...args);if(response.url.includes("/youtubei/v1/player")){const originalText=response.text.bind(response);response.text=()=>originalText().then((data)=>data.replace(/"adPlacements"/g,'"odPlacements"'))}return response}})();(function(){const skipAds=()=>{const skipButton=document.querySelector(".videoAdUiSkipButton, .ytp-ad-skip-button");if(skipButton)skipButton.click();const adOverlay=document.querySelector(".ad-showing");if(adOverlay){const video=document.querySelector("video");if(video){video.playbackRate=10;video.isMuted=1}}};const removeInlineAds=()=>{const adContainer=document.querySelector("#player-ads");if(adContainer)adContainer.remove()};const adBlockerInterval=setInterval(()=>{skipAds();removeInlineAds()},300);window.addEventListener("unload",()=>clearInterval(adBlockerInterval))})();
    """
// swiftlint:enable line_length

private let jsAXWebViewConfigurations = [
    "allowsPictureInPictureMediaPlayback",
    "appNapEnabled",
    "acceleratedCompositingEnabled",
    "webGLEnabled",
    "largeImageAsyncDecodingEnabled",
    "mediaSourceEnabled",
    "acceleratedDrawingEnabled",
    "animatedImageAsyncDecodingEnabled",
    "developerExtrasEnabled",
    "canvasUsesAcceleratedDrawing"
]
