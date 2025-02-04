//
//  AXTab.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import Combine
import WebKit

// MARK: - AXTab

class AXTab: NSTabViewItem, Codable {
    // MARK: - Properties
    var url: URL?
    var icon: NSImage?
    var titleObserver: Cancellable?

    unowned var tabButton: AXTabButton?

    var websiteDataStore: WKWebsiteDataStore
    var websiteProcessPool: WKProcessPool

    var individualWebConfiguration: WKWebViewConfiguration

    var isEmpty = false
    var onWebViewInitialization: ((AXWebView) -> Void)?

    /// Returns the AXWebView if available, or creates/configures one if needed.
    var webView: AXWebView? {
        if let existingWebView = view as? AXWebView {
            return existingWebView
        }
        guard !isEmpty else { return nil }

        // Create a new AXWebView with our configuration
        let newWebView = AXWebView(
            frame: .zero, configuration: individualWebConfiguration)
        if let url = url {
            newWebView.load(URLRequest(url: url))
        }

        view = newWebView  // Set as NSTabViewItem's view
        onWebViewInitialization?(newWebView)
        return newWebView
    }

    // MARK: - Initializers

    /// Initializes a new tab with an optional URL and a title.
    init(
        url: URL! = nil, title: String, dataStore: WKWebsiteDataStore,
        processPool: WKProcessPool
    ) {
        self.url = url
        self.websiteDataStore = dataStore
        self.websiteProcessPool = processPool

        self.individualWebConfiguration = AXTab.configureWebConfiguration(
            processPool: processPool,
            dataStore: dataStore
        )

        super.init(identifier: nil)
        self.label = title

        let webView = AXWebView(
            frame: .zero, configuration: individualWebConfiguration)
        self.view = webView

        configureUserContent()
    }

    /// Initializes an empty tab.
    init(
        creatingEmptyTab: Bool, dataStore: WKWebsiteDataStore,
        processPool: WKProcessPool
    ) {
        self.isEmpty = creatingEmptyTab
        self.url = nil
        self.websiteDataStore = dataStore
        self.websiteProcessPool = processPool

        self.individualWebConfiguration = AXTab.configureWebConfiguration(
            processPool: processPool,
            dataStore: dataStore
        )

        super.init(identifier: nil)
        self.label = "New Tab"

        configureUserContent()
    }

    /// Initializes a tab created as a popup with a given configuration.
    init(createdPopupTab withConfig: WKWebViewConfiguration) {
        self.individualWebConfiguration =
            (withConfig.copy() as! WKWebViewConfiguration)
        self.websiteDataStore = withConfig.websiteDataStore
        self.websiteProcessPool = withConfig.processPool
        self.individualWebConfiguration.userContentController = .init()

        super.init(identifier: nil)

        let webView = AXWebView(
            frame: .zero, configuration: individualWebConfiguration)
        self.view = webView

        configureUserContent()
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case label, url, isEmpty
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard
            let dataStore = decoder.userInfo[.websiteDataStore]
                as? WKWebsiteDataStore
        else {
            fatalError("[AXTab]: Data Store not found in decoder")
        }
        self.websiteDataStore = dataStore

        guard
            let processPool = decoder.userInfo[.websiteProcessPool]
                as? WKProcessPool
        else {
            fatalError("[AXTab]: Process Pool not found in decoder")
        }
        self.websiteProcessPool = processPool

        self.individualWebConfiguration = AXTab.configureWebConfiguration(
            processPool: websiteProcessPool,
            dataStore: websiteDataStore
        )

        super.init(identifier: nil)

        configureUserContent()

        self.label = try container.decode(String.self, forKey: .label)
        self.url = try container.decodeIfPresent(URL.self, forKey: .url)
        self.isEmpty =
            try container.decodeIfPresent(Bool.self, forKey: .isEmpty) ?? false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(isEmpty, forKey: .isEmpty)

        if let webView = view as? AXWebView, let url = webView.url {
            try container.encode(url, forKey: .url)
        } else if let url = self.url {
            try container.encode(url, forKey: .url)
        }
    }

    // MARK: - WebView Management

    /// Deactivates the web view by stopping observations and removing it from the view hierarchy.
    func deactivateWebView() {
        stopAllObservations()
        view?.removeFromSuperview()
        view = nil
    }

    // MARK: - Title Observation

    func startTitleObservation(for tabButton: AXTabButton) {
        guard let webView = view as? AXWebView else { return }
        self.tabButton = tabButton

        // Use Combine to observe changes to the web view's title.
        titleObserver = webView.publisher(for: \.title)
            .sink { [weak self, weak tabButton] title in
                guard let self = self, let tabButton = tabButton else { return }
                let displayTitle = title ?? "Untitled"

                self.label = displayTitle
                tabButton.webTitle = displayTitle
                if let updatedURL = webView.url {
                    self.url = updatedURL
                }
            }
    }

    func stopAllObservations() {
        titleObserver?.cancel()
        titleObserver = nil

        if let webView = view as? AXWebView {
            let contentController = webView.configuration.userContentController
            contentController.removeScriptMessageHandler(
                forName: "faviconChanged")
            contentController.removeScriptMessageHandler(
                forName: "advancedBlockingData")
        }
    }

    // MARK: - Favicon Handling via User Script

    /// Injects the user script for favicon monitoring and sets up the message handler.
    private func configureUserContent() {
        let contentController = self.individualWebConfiguration
            .userContentController

        let userScript = WKUserScript(
            source: jsFaviconMonitoringScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(userScript)
        contentController.add(self, name: "faviconChanged")

        AXContentBlockerLoader.shared.enableAdblock(
            for: self.individualWebConfiguration, handler: self)
    }

    /// Downloads and downsizes a favicon image from the given URL.
    @MainActor
    private func quickFaviconDownload(from url: URL) async throws -> NSImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = NSImage(data: data)?.downsizedIcon() else {
            throw URLError(.cannotParseResponse)
        }
        return image
    }

    // MARK: - Helper Methods

    /// Configures a new WKWebViewConfiguration with default preferences.
    private static func configureWebConfiguration(
        processPool: WKProcessPool,
        dataStore: WKWebsiteDataStore
    ) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.enableDefaultMalvonPreferences()
        configuration.processPool = processPool
        configuration.websiteDataStore = dataStore
        return configuration
    }
}

// MARK: - WKScriptMessageHandler
extension AXTab: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        switch message.name {
        case "faviconChanged" where message.body is String:
            guard let url = URL(string: message.body as! String) else { return }
            Task { @MainActor in
                if let tabButton = self.tabButton {
                    self.icon = try? await quickFaviconDownload(from: url)
                    tabButton.favicon = self.icon
                }
            }

        case "advancedBlockingData" where message.body is String:
            Task {
                do {
                    guard let url = URL(string: message.body as! String) else {
                        mxPrint("Invalid URL: \(message.body)")
                        return
                    }

                    let data = try await ContentBlockerEngineWrapper.shared
                        .getData(url: url)
                    let response: [String: Any] = [
                        "url": url.absoluteString,
                        "data": data,
                        "verbose": true,
                    ]

                    if let jsonData = try? JSONSerialization.data(
                        withJSONObject: response),
                        let js = String(data: jsonData, encoding: .utf8)
                    {
                        DispatchQueue.main.async {
                            self.webView?.evaluateJavaScript(
                                "(()=>{(handleMessage({name:'advancedBlockingData', message:\(js)}))})();",
                                completionHandler: nil
                            )
                        }
                    }
                } catch {
                    mxPrint("BlockingDataError: \(error)")
                }
            }

        default:
            mxPrint(
                "AXTab.UserContentController: Detected unknown WebKit name: \(message.name), body: \(message.body)"
            )
            return
        }
    }
}

// MARK: - The Favicon-Monitoring User Script

private let jsFaviconMonitoringScript = """
    let l,o=document.head,r=["icon","shortcut icon","apple-touch-icon","mask-icon"],f=_=>(u=(()=>{for(const t of r){const e=o.querySelector(`link[rel="${t}"]`);if(e?.href)return e.href}return location.origin+"/favicon.ico"})(),u!==l&&(l=u,window.webkit?.messageHandlers?.faviconChanged?.postMessage(u)));f(),new MutationObserver(f).observe(o,{childList:1,attributes:1,attributeFilter:["href"]});
    """

// MARK: - NSImage Helper Extension
extension NSImage {
    /// Returns a downsized version of the image (16×16).
    func downsizedIcon() -> NSImage? {
        let targetSize = NSSize(width: 16, height: 16)
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: self.size),
            operation: .copy,
            fraction: 1.0
        )
        resizedImage.unlockFocus()
        return resizedImage
    }
}
