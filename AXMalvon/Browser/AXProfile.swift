//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-17.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Foundation
import WebKit

class AXProfile {
    let name: String
    var configuration: WKWebViewConfiguration
    var tabGroups: [AXTabGroup] = []
    var currentTabGroup: AXTabGroup

    var currentTabGroupIndex = 0 {
        didSet {
            currentTabGroup = tabGroups[currentTabGroupIndex]
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

    convenience init(name: String) {
        let defaults = UserDefaults.standard
        let config: WKWebViewConfiguration

        if let configID = defaults.string(forKey: "configurationID-\(name)"),
            let uuid = UUID(uuidString: configID)
        {
            config = WKWebViewConfiguration()
            config.websiteDataStore = WKWebsiteDataStore(forIdentifier: uuid)
        } else {
            let newID = UUID()
            defaults.set(newID.uuidString, forKey: "configurationID-\(name)")
            config = WKWebViewConfiguration()
            config.websiteDataStore = WKWebsiteDataStore(forIdentifier: newID)
        }

        self.init(name: name, config: config, loadsDefaultData: true)

        #if !DEBUG
            self.currentTabGroupIndex = defaults.integer(
                forKey: "\(name)-selectedTabGroup")
        #endif
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
        let extensionLoader = AX_wBlockExtension()

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
