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

class AXTab: NSTabViewItem, Codable {
    var url: URL?
    var title: String = "Untitled Tab" {
        didSet {
            label = title  // Sync with NSTabViewItem's label
        }
    }
    var icon: NSImage?
    var titleObserver: Cancellable?
    var webConfiguration: WKWebViewConfiguration
    var isEmpty = false
    var onWebViewInitialization: ((AXWebView) -> Void)?

    var webView: AXWebView? {
        if let existingWebView = self.view as? AXWebView {
            return existingWebView
        } else {
            guard !isEmpty else { return nil }

            let newWebView = AXWebView(
                frame: .zero, configuration: webConfiguration)
            if let url = url {
                newWebView.load(URLRequest(url: url))
            }

            view = newWebView  // Set as NSTabViewItem's view
            onWebViewInitialization?(newWebView)
            return newWebView
        }
    }

    // MARK: - Initializers

    override init(identifier: Any?) {
        self.webConfiguration = WKWebViewConfiguration()
        super.init(identifier: identifier)
        label = title
    }

    convenience init(url: URL? = nil, title: String, webView: AXWebView) {
        self.init(identifier: nil)
        self.url = url
        self.title = title
        self.view = webView
        self.webConfiguration = webView.configuration
    }

    convenience init(
        creatingEmptyTab: Bool, configuration: WKWebViewConfiguration
    ) {
        self.init(identifier: nil)
        self.isEmpty = creatingEmptyTab
        self.title = "New Tab"
        self.webConfiguration = configuration
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case title, url, isEmpty
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Get webConfiguration from userInfo
        #if DEBUG
            if let config = decoder.userInfo[.webConfiguration]
                as? WKWebViewConfiguration
            {
                webConfiguration = config
            } else {
                print("WKWebViewConfiguration not found in decoder")
                webConfiguration = WKWebViewConfiguration()
            }
        #else
            webConfiguration =
                (decoder.userInfo[.webConfiguration] as? WKWebViewConfiguration)
                ?? WKWebViewConfiguration()
        #endif

        super.init(identifier: nil)  // Initialize NSTabViewItem

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
        stopTitleObservation()

        self.view?.removeFromSuperview()
        self.view = nil
    }

    // MARK: - Title Observation

    func startTitleObservation(for tabButton: AXTabButton) {
        guard let webView = self.view as? AXWebView else { return }

        // Use a more efficient observation method
        self.titleObserver = webView.publisher(for: \.title)
            .sink { [weak self, weak tabButton] title in
                guard let self = self, let tabButton = tabButton else { return }

                // Optimize title handling
                let displayTitle = title ?? "Untitled"

                // Efficiently handle URL and favicon updates
                if !displayTitle.isEmpty, self.title != displayTitle {
                    self.updateTabURLAndFavicon(
                        for: webView, tabButton: tabButton)
                }

                self.title = displayTitle
                tabButton.webTitle = displayTitle
            }
    }

    // Separate method to handle URL and favicon updates
    private func updateTabURLAndFavicon(
        for webView: AXWebView, tabButton: AXTabButton
    ) {
        guard let newURL = webView.url else {
            return
        }

        self.url = newURL

        // Perform favicon fetch asynchronously to reduce main thread load
        DispatchQueue.main.async {
            self.findFavicon(tabButton: tabButton)
        }
    }

    func stopTitleObservation() {
        titleObserver?.cancel()
        titleObserver = nil
    }

    // MARK: - Favicon Handling

    func findFavicon(tabButton: AXTabButton) {
        Task(priority: .low) { @MainActor in
            do {
                if let faviconURLString = try? await webView!
                    .evaluateJavaScript(
                        jsFaviconSearchScript) as? String,
                    let faviconURL = URL(string: faviconURLString)
                {
                    let favicon = try await quickFaviconDownload(
                        from: faviconURL)
                    tabButton.favicon = favicon
                    self.icon = favicon
                } else {
                    tabButton.favicon = nil
                }
            } catch {
                tabButton.favicon = nil
            }
        }
    }

    private func quickFaviconDownload(from url: URL) async throws -> NSImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = NSImage(data: data)?.downsizedIcon() else {
            throw URLError(.cannotParseResponse)
        }
        return image
    }

    // MARK: - Cleanup

    deinit {
        titleObserver?.cancel()
    }
}

// Helper extension for image resizing
extension NSImage {
    func downsizedIcon() -> NSImage? {
        let targetSize = NSSize(width: 16, height: 16)
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        draw(in: NSRect(origin: .zero, size: targetSize))
        resizedImage.unlockFocus()
        return resizedImage
    }
}

private let jsFaviconSearchScript = """
        (d=>{const h=d.head,l=["icon","shortcut icon","apple-touch-icon","mask-icon"];for(let r of l)if((r=h.querySelector(`link[rel=\"${r}\"]`))&&r.href)return r.href;return d.location.origin+"/favicon.ico"})(document)
    """
