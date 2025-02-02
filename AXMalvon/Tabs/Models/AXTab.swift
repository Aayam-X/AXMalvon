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
    var url: URL?
    var title: String = "Untitled Tab" {
        didSet {
            label = title  // Sync with NSTabViewItem's label
        }
    }
    var icon: NSImage?
    var titleObserver: Cancellable?

    unowned var tabButton: AXTabButton?

    var websiteDataStore: WKWebsiteDataStore
    var websiteProcessPool: WKProcessPool

    var individualWebConfiguration: WKWebViewConfiguration

    var isEmpty = false
    var onWebViewInitialization: ((AXWebView) -> Void)?

    var webView: AXWebView? {
        if let existingWebView = self.view as? AXWebView {
            return existingWebView
        } else {
            guard !isEmpty else { return nil }

            // Create a new AXWebView with our configuration
            let newWebView = AXWebView(
                frame: .zero, configuration: self.individualWebConfiguration)
            if let url = url {
                newWebView.load(URLRequest(url: url))
            }

            // Inject the favicon-monitoring user script and add our message handler.
            configureUserContent(for: newWebView)

            view = newWebView  // Set as NSTabViewItem's view
            onWebViewInitialization?(newWebView)
            return newWebView
        }
    }

    // MARK: - Initializers
    init(
        url: URL! = nil, title: String, dataStore: WKWebsiteDataStore,
        processPool: WKProcessPool
    ) {
        self.url = url
        self.title = title
        self.websiteProcessPool = processPool
        self.websiteDataStore = dataStore

        self.individualWebConfiguration = .init()
        self.individualWebConfiguration.enableDefaultMalvonPreferences()
        self.individualWebConfiguration.processPool = websiteProcessPool
        self.individualWebConfiguration.websiteDataStore = websiteDataStore

        super.init(identifier: nil)

        let webView = AXWebView(
            frame: .zero, configuration: self.individualWebConfiguration)
        self.view = webView
        configureUserContent(for: webView)

        if let url {
            webView.load(URLRequest(url: url))
        }
    }

    init(
        creatingEmptyTab: Bool, dataStore: WKWebsiteDataStore,
        processPool: WKProcessPool
    ) {
        self.isEmpty = creatingEmptyTab
        self.url = nil
        self.title = "New Tab"
        self.websiteDataStore = dataStore
        self.websiteProcessPool = processPool

        self.individualWebConfiguration = .init()
        self.individualWebConfiguration.enableDefaultMalvonPreferences()
        self.individualWebConfiguration.processPool = websiteProcessPool
        self.individualWebConfiguration.websiteDataStore = websiteDataStore

        super.init(identifier: nil)
    }

    init(createdPopupTab withConfig: WKWebViewConfiguration) {
        self.individualWebConfiguration =
            withConfig.copy() as! WKWebViewConfiguration

        self.websiteDataStore = withConfig.websiteDataStore
        self.websiteProcessPool = withConfig.processPool

        self.individualWebConfiguration.userContentController = .init()
        //        self.individualWebConfiguration = withConfig

        //        self.individualWebConfiguration = WKWebViewConfiguration()
        //        self.individualWebConfiguration.websiteDataStore = self.websiteDataStore
        //        self.individualWebConfiguration.processPool = self.websiteProcessPool
        //        self.individualWebConfiguration.preferences = withConfig.preferences
        //        self.individualWebConfiguration.userContentController = withConfig.userContentController
        //        self.individualWebConfiguration.

        super.init(identifier: nil)

        let webView = AXWebView(
            frame: .zero, configuration: self.individualWebConfiguration)
        self.view = webView

        configureUserContent(for: webView)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case title, url, isEmpty
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        #if DEBUG
            if let dataStore = decoder.userInfo[.websiteDataStore]
                as? WKWebsiteDataStore
            {
                self.websiteDataStore = dataStore
            } else {
                fatalError("[AXTab]: Data Store not found in decoder")
            }

            if let processPool = decoder.userInfo[.websiteProcessPool]
                as? WKProcessPool
            {
                self.websiteProcessPool = processPool
            } else {
                fatalError("[AXTab]: Process Pool not found in decoder")
            }
        #else
            webConfiguration =
                (decoder.userInfo[.webConfiguration] as? WKWebViewConfiguration)
                ?? WKWebViewConfiguration()
        #endif

        self.individualWebConfiguration = .init()
        self.individualWebConfiguration.processPool = websiteProcessPool
        self.individualWebConfiguration.websiteDataStore = websiteDataStore

        super.init(identifier: nil)

        title = try container.decode(String.self, forKey: .title)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        isEmpty =
            try container.decodeIfPresent(Bool.self, forKey: .isEmpty) ?? false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(isEmpty, forKey: .isEmpty)

        if let webView = self.view as? AXWebView, let url = webView.url {
            try container.encode(url, forKey: .url)
        }
    }

    func deactivateWebView() {
        stopAllObservations()
        // Remove the web view from its superview and drop the reference.
        self.view?.removeFromSuperview()
        self.view = nil
    }

    // MARK: - Title Observation

    func startTitleObservation(for tabButton: AXTabButton) {
        guard let webView = self.view as? AXWebView else { return }
        self.tabButton = tabButton

        // Use Combine to observe changes to the web view's title.
        self.titleObserver = webView.publisher(for: \.title)
            .sink { [weak self, weak tabButton] title in
                guard let self = self, let tabButton = tabButton else { return }
                let displayTitle = title ?? "Untitled"

                // Update our URL based on the web view’s current URL.
                if !displayTitle.isEmpty, self.title != displayTitle {
                    self.updateTabURL(with: webView)
                }

                self.title = displayTitle
                tabButton.webTitle = displayTitle
            }
    }

    // Update our stored URL.
    private func updateTabURL(with webView: AXWebView) {
        guard let newURL = webView.url else { return }
        self.url = newURL
    }

    func stopAllObservations() {
        titleObserver?.cancel()
        titleObserver = nil

        if let webView = self.view as? AXWebView {
            webView.configuration.userContentController
                .removeScriptMessageHandler(forName: "faviconChanged")
        }
    }

    // MARK: - Favicon Handling via User Script

    /// Call this when creating or reusing the web view. It injects the monitoring user script and
    /// sets up our message handler.
    private func configureUserContent(for webView: AXWebView) {
        let contentController = webView.configuration.userContentController

        // Add the user script that monitors for favicon changes.
        let userScript = WKUserScript(
            source: jsFaviconMonitoringScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true)
        contentController.addUserScript(userScript)

        // Add self as the message handler for favicon changes.
        // (Be sure to remove it when the web view is deallocated.)
        contentController.add(self, name: "faviconChanged")
    }

    /// Download a favicon image from the given URL.
    @MainActor
    private func quickFaviconDownload(from url: URL) async throws -> NSImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = NSImage(data: data)?.downsizedIcon() else {
            throw URLError(.cannotParseResponse)
        }
        return image
    }
}

// MARK: - WKScriptMessageHandler
// This extension makes AXTab respond to messages from the injected user script.

extension AXTab: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // Expect a message from our injected script with the favicon URL.
        if message.name == "faviconChanged",
            let faviconURLString = message.body as? String,
            let faviconURL = URL(string: faviconURLString)
        {
            // Download the favicon asynchronously.
            Task { @MainActor in
                do {
                    let favicon = try await quickFaviconDownload(
                        from: faviconURL)
                    self.icon = favicon
                    // Update the associated tab button if we have one.
                    self.tabButton?.favicon = favicon
                } catch {
                    self.tabButton?.favicon = nil
                }
            }
        }
    }
}

// MARK: - Helper extension for image resizing

extension NSImage {
    func downsizedIcon() -> NSImage? {
        let targetSize = NSSize(width: 16, height: 16)
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: self.size),
            operation: .copy,
            fraction: 1.0)
        resizedImage.unlockFocus()
        return resizedImage
    }
}

// MARK: - The Favicon-Monitoring User Script

private let jsFaviconMonitoringScript = """
    (()=>{const h=document.head,r=["icon","shortcut icon","apple-touch-icon","mask-icon"],f=()=>{const l=r.map(t=>h.querySelector(`link[rel="${t}"]`)).find(l=>l?.href);return l?new URL(l.href,document.baseURI).href:document.location.origin+"/favicon.ico"},n=()=>window.webkit?.messageHandlers?.faviconChanged?.postMessage(f());n(),new MutationObserver(n).observe(h,{childList:!0,subtree:!0,attributes:!0,attributeFilter:["href"]})})();
    """
