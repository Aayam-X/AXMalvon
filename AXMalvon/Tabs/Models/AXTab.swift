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

class AXTab: NSObject, Codable {
    // MARK: - Properties
    var url: URL?
    var icon: NSImage?
    var title: String
    
    var isTabEmpty: Bool {
        return _webView == nil
    }
    
    private var titleObserver: Cancellable?
    
    var onTitleChange: ((String?) -> Void)?
    var onFaviconChange: ((NSImage?) -> Void)?
    
    weak var _webView: AXWebView?
    var individualWebConfiguration: WKWebViewConfiguration
    
    /// Returns the AXWebView if available, or creates/configures one if needed.
    var webView: AXWebView? {
        if let existingWebView = _webView {
            return existingWebView
        } else {
            if let url = url {
                let newWebView = AXWebView(frame: .zero, configuration: individualWebConfiguration)
                newWebView.load(URLRequest(url: url))
                
                self._webView = newWebView
                startTitleObservation()
                return newWebView
            }
        }
        return nil
    }
    
    // MARK: - Initializers
    
    /// Initializes a new tab with an optional URL and a title.
    init(url: URL! = nil, title: String, configuration: WKWebViewConfiguration)
    {
        self.title = title
        self.url = url
        self.individualWebConfiguration =
        configuration.copy() as! WKWebViewConfiguration
        
        let webView = AXWebView(
            frame: .zero, configuration: individualWebConfiguration)
        self._webView = webView
        
        super.init()
        
        initializeUserContentController()
    }
    
    /// Initializes an empty tab.
    init(
        creatingEmptyTab: Bool, configuration: WKWebViewConfiguration
    ) {
        self.url = nil
        self.title = "New Tab"
        
        self.individualWebConfiguration = configuration.copy() as! WKWebViewConfiguration
        
        super.init()
        
        initializeUserContentController()
    }
    
    /// Initializes a tab created as a popup with a given configuration.
    init(createdPopupTab withConfig: WKWebViewConfiguration) {
        self.individualWebConfiguration = withConfig.copy() as! WKWebViewConfiguration
        
        let newContentController = WKUserContentController()
        self.individualWebConfiguration.userContentController =
            newContentController

        newContentController.addUserScript(javaScriptFaviconMonitoringScript)

        
        let webView = AXWebView(
            frame: .zero, configuration: individualWebConfiguration)
        self._webView = webView
        self.title = "Popup Tab"
        
        super.init()
        
        newContentController.add(self, name: "faviconChanged")
        
        AXContentBlockerLoader.shared.enableAdblock(
            for: self.individualWebConfiguration, handler: self)
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case title, url, isEmpty
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard
            let baseConfiguration = decoder.userInfo[.webviewConfiguration]
                as? WKWebViewConfiguration
        else {
            fatalError("[AXTab]: Data Store not found in decoder")
        }
        
        self.title = try container.decode(String.self, forKey: .title)
        self.url = try container.decodeIfPresent(URL.self, forKey: .url)
        
        self.individualWebConfiguration =
        baseConfiguration.copy() as! WKWebViewConfiguration
        
        super.init()
        
        initializeUserContentController()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        
        if let webView = _webView, let url = webView.url {
            try container.encode(url, forKey: .url)
        } else if let url = self.url {
            try container.encode(url, forKey: .url)
        }
    }
    
    // MARK: - Title Observation
    
    func startTitleObservation() {
        guard let webView = _webView else { return }
        
        // Use Combine to observe changes to the web view's title.
        titleObserver = webView.publisher(for: \.title)
            .sink { [weak self] title in
                guard let self = self else { return }
                let displayTitle = title ?? "Untitled"
                
                self.title = displayTitle
                if let updatedURL = webView.url {
                    self.url = updatedURL
                }
                
                onTitleChange?(displayTitle)
            }
    }
    //
    func stopAllObservations() {
        titleObserver?.cancel()
        titleObserver = nil
        
        if let webView = _webView {
            let contentController = webView.configuration.userContentController
            contentController.removeScriptMessageHandler(
                forName: "faviconChanged")
            contentController.removeScriptMessageHandler(
                forName: "advancedBlockingData")
        }
    }
    
    /// Injects the user script for favicon monitoring and sets up the message handler.
    private func initializeUserContentController() {
        let newContentController = WKUserContentController()
        self.individualWebConfiguration.userContentController =
            newContentController

        newContentController.addUserScript(javaScriptFaviconMonitoringScript)
        newContentController.add(self, name: "faviconChanged")

        AXContentBlockerLoader.shared.enableAdblock(
            for: self.individualWebConfiguration, handler: self)
    }

    // MARK: - Favicon Handling via User Script
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
            Task {
                let image = try? await quickFaviconDownload(from: url)
                self.icon = image
                mxPrint("Found new favicon for button with tag")
                onFaviconChange?(image)
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
let javaScriptFaviconMonitoringScript = WKUserScript(
    source: jsFaviconMonitoringScript,
    injectionTime: .atDocumentEnd,
    forMainFrameOnly: true
)

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
