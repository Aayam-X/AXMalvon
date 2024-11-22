//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-17.
//

import WebKit

class AXProfile {
    var name: String
    var configuration: WKWebViewConfiguration

    var tabGroups: [AXTabGroup] = []
    var currentTabGroup: AXTabGroup

    var currentTabGroupIndex = 0 {
        didSet {
            currentTabGroup = tabGroups[currentTabGroupIndex]
        }
    }

    init(name: String) {
        self.name = name
        self.currentTabGroup = .init(name: "Default")

        // WebView configuration
        let defaults = UserDefaults.standard

        // Search for config in UserDefaults; if not create a new one.
        if let configID = defaults.string(forKey: "configurationID-\(name)") {
            let uuid = UUID(uuidString: configID)!
            self.configuration = WKWebViewConfiguration()
            self.configuration.websiteDataStore = .init(forIdentifier: uuid)
        } else {
            let newID = UUID()
            defaults.set(newID.uuidString, forKey: "configurationID-\(name)")

            self.configuration = WKWebViewConfiguration()
            self.configuration.websiteDataStore = .init(forIdentifier: newID)
        }

        #if !DEBUG
            // Debug and Release have different tabs
            // This would cause a crash
            self.currentTabGroupIndex = defaults.integer(
                forKey: "\(name)-selectedTabGroup")
        #endif

        addOtherConfigs()

        loadTabGroups()
    }

    // MARK: - Configuration Features
    func addOtherConfigs() {
        for config in AX_DEFAULT_WEBVIEW_CONFIGURATIONS {
            configuration.preferences.setValue(true, forKey: config)
        }

        configuration.preferences.setValue(
            false, forKey: "backspaceKeyNavigationEnabled")
    }

    func enableContentBlockers() {
        let extensionLoader = AXExtensionsLoader.shared

        // Simple Filter
        extensionLoader.getContentBlockerURLPath { blockerListURL in
            guard let blockerListURL else { return }

            DispatchQueue.global(qos: .userInitiated).async {
                try? self.loadContentBlocker(at: blockerListURL)
            }
        }
    }

    func enableYouTubeAdBlocker() {
        let userScript = WKUserScript(
            source: AX_DEFAULT_YOUTUBE_BLOCKER_SCRIPT,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
    }

    func loadContentBlocker(at url: URL) throws {
        // Load the data from the URL
        let blockerListData = try Data(contentsOf: url)

        // Convert the data to a string (UTF-8 decoding)
        guard
            let blockerListString = String(
                data: blockerListData, encoding: .utf8)
        else {
            print("Failed to decode blocker list data.")
            return
        }

        // Compile the content rule list on the same background thread
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "ContentBlocker",
            encodedContentRuleList: blockerListString
        ) { contentRuleList, error in
            guard let contentRuleList else { return }
            // Switch back to the main thread for UI updates
            // Apply the content rule list to the web view configuration
            self.configuration.userContentController.add(
                contentRuleList)
        }
    }

    // MARK: - User Defaults
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

        // Ensure the directory exists
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(
                at: directoryURL, withIntermediateDirectories: true,
                attributes: nil)
        }

        return directoryURL.appendingPathComponent("TabGroups-\(name).json")
    }

    func saveTabGroups() {
        #if !DEBUG
            UserDefaults.standard.set(
                currentTabGroupIndex, forKey: "\(name)-selectedTabGroup")
        #endif

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(tabGroups)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save tab groups: \(error)")
        }
    }

    func loadTabGroups() {
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
}

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

let AX_DEFAULT_YOUTUBE_BLOCKER_SCRIPT = """
    (function(){let ytInitialPlayerResponse=null;Object.defineProperty(window,"ytInitialPlayerResponse",{get:()=>ytInitialPlayerResponse,set:(data)=>{if(data)data.adPlacements=[];ytInitialPlayerResponse=data},configurable:true})})();(function(){const originalFetch=window.fetch;window.fetch=async(...args)=>{const response=await originalFetch(...args);if(response.url.includes("/youtubei/v1/player")){const originalText=response.text.bind(response);response.text=()=>originalText().then((data)=>data.replace(/"adPlacements"/g,'"odPlacements"'))}return response}})();(function(){const skipAds=()=>{const skipButton=document.querySelector(".videoAdUiSkipButton, .ytp-ad-skip-button");if(skipButton)skipButton.click();const adOverlay=document.querySelector(".ad-showing");if(adOverlay){const video=document.querySelector("video");if(video){video.playbackRate=10;video.isMuted=1}}};const removeInlineAds=()=>{const adContainer=document.querySelector("#player-ads");if(adContainer)adContainer.remove()};const adBlockerInterval=setInterval(()=>{skipAds();removeInlineAds()},300);window.addEventListener("unload",()=>clearInterval(adBlockerInterval))})();
    """
