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

    // Tab Group related functions
    var currentTabGroupIndex = 0 {
        didSet {
            currentTabGroup = tabGroups[currentTabGroupIndex]
        }
    }

    private let fileName: String

    init(name: String) {
        self.name = name
        fileName = "TabGroups-\(name).json"
        self.currentTabGroup = .init(name: "Default")

        // WebView configuration
        self.configuration = WKWebViewConfiguration()

        let defaults = UserDefaults.standard

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
            self.currentTabGroupIndex = defaults.integer(
                forKey: "\(name)-selectedTabGroup")
        #endif

        addOtherConfigs()

        loadTabGroups()
        print(fileURL)
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
            source: script, injectionTime: .atDocumentStart,
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
        ) { [weak self] contentRuleList, error in
            // Switch back to the main thread for UI updates
            DispatchQueue.main.async {
                if let error = error {
                    print(
                        "Failed to compile content rule list: \(error)"
                    )
                    return
                }

                guard let contentRuleList = contentRuleList,
                    let self = self
                else { return }

                // Apply the content rule list to the web view configuration
                self.configuration.userContentController.add(
                    contentRuleList)
            }
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

        return directoryURL.appendingPathComponent(fileName)
    }

    func saveTabGroups() {
        UserDefaults.standard.set(
            currentTabGroupIndex, forKey: "\(name)-selectedTabGroup")

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

    func addOtherConfigs() {
        for config in AX_DEFAULT_WEBVIEW_CONFIGURATIONS {
            configuration.preferences.setValue(true, forKey: config)
        }

        configuration.preferences.setValue(
            false, forKey: "backspaceKeyNavigationEnabled")
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

let script = """
    (function(){let ytInitialPlayerResponse=null;Object.defineProperty(window,"ytInitialPlayerResponse",{get:()=>ytInitialPlayerResponse,set:(data)=>{if(data)data.adPlacements=[];ytInitialPlayerResponse=data},configurable:true})})();(function(){const originalFetch=window.fetch;window.fetch=async(...args)=>{const response=await originalFetch(...args);if(response.url.includes("/youtubei/v1/player")){const originalText=response.text.bind(response);response.text=()=>originalText().then((data)=>data.replace(/"adPlacements"/g,'"odPlacements"'))}return response}})();(function(){const skipAds=()=>{const skipButton=document.querySelector(".videoAdUiSkipButton, .ytp-ad-skip-button");if(skipButton)skipButton.click();const adOverlay=document.querySelector(".ad-showing");if(adOverlay){const video=document.querySelector("video");if(video)video.playbackRate=10}};const removeInlineAds=()=>{const adContainer=document.querySelector("#player-ads");if(adContainer)adContainer.remove()};const adBlockerInterval=setInterval(()=>{skipAds();removeInlineAds()},300);window.addEventListener("unload",()=>clearInterval(adBlockerInterval))})();
    """
