//
//  AXTab.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import Combine
import WebKit

/// Runtime tab: owns the live ``AXWebView`` and observes its title/favicon.
/// Persistence happens through ``AXProfile/saveTabGroups()`` which writes a
/// snapshot into SwiftData; this class is intentionally not ``Codable``.
@MainActor
final class AXTab: NSObject {
    // MARK: - Persisted-ish state (read at save time by AXProfile)

    var url: URL?
    var title: String
    var icon: NSImage?

    // MARK: - Runtime

    var isTabEmpty: Bool { _webView == nil }

    private var titleObserver: Cancellable?

    var onTitleChange: ((String?) -> Void)?
    var onFaviconChange: ((NSImage?) -> Void)?

    weak var _webView: AXWebView?
    var individualWebConfiguration: WKWebViewConfiguration

    /// The live web view. If one hasn't been created yet (e.g. the tab was
    /// just restored from disk), instantiates one and kicks off a load of
    /// the persisted URL.
    var webView: AXWebView? {
        if let existing = _webView {
            return existing
        }
        guard let url else { return nil }

        let newWebView = AXWebView(
            frame: .zero, configuration: individualWebConfiguration
        )
        newWebView.load(URLRequest(url: url))
        _webView = newWebView
        startTitleObservation()
        return newWebView
    }

    // MARK: - Initializers

    /// New tab being opened with a target URL. Creates the ``AXWebView``
    /// eagerly so callers can attach observers immediately; the page load
    /// kicks off when ``webView`` is first accessed.
    init(
        url: URL! = nil, title: String,
        configuration: WKWebViewConfiguration
    ) {
        self.title = title
        self.url = url
        self.individualWebConfiguration =
            configuration.copy() as! WKWebViewConfiguration

        let webView = AXWebView(
            frame: .zero, configuration: individualWebConfiguration
        )
        self._webView = webView

        super.init()

        initializeUserContentController()
    }

    /// Blank "New Tab" with no destination yet.
    init(
        creatingEmptyTab: Bool, configuration: WKWebViewConfiguration
    ) {
        self.url = nil
        self.title = "New Tab"
        self.individualWebConfiguration =
            configuration.copy() as! WKWebViewConfiguration

        super.init()

        initializeUserContentController()
    }

    /// Tab restored from SwiftData. The ``AXWebView`` is created lazily on
    /// first access of ``webView`` so off-screen tabs don't pay for it.
    init(
        restoredURL url: URL?, title: String,
        configuration: WKWebViewConfiguration
    ) {
        self.url = url
        self.title = title
        self.individualWebConfiguration =
            configuration.copy() as! WKWebViewConfiguration

        super.init()

        initializeUserContentController()
    }

    /// Tab spawned by `window.open()` or `target=_blank` with the page's
    /// preferred configuration.
    init(createdPopupTab withConfig: WKWebViewConfiguration) {
        self.individualWebConfiguration =
            withConfig.copy() as! WKWebViewConfiguration

        let newContentController = WKUserContentController()
        self.individualWebConfiguration.userContentController = newContentController
        newContentController.addUserScript(javaScriptFaviconMonitoringScript)

        let webView = AXWebView(
            frame: .zero, configuration: individualWebConfiguration
        )
        self._webView = webView
        self.title = "Popup Tab"

        super.init()

        newContentController.add(self, name: "faviconChanged")
    }

    // MARK: - Title observation

    func startTitleObservation() {
        guard let webView = _webView else { return }

        titleObserver = webView.publisher(for: \.title)
            .sink { [weak self] title in
                guard let self else { return }
                let displayTitle = title ?? "Untitled"

                self.title = displayTitle
                if let updatedURL = webView.url {
                    self.url = updatedURL
                }

                onTitleChange?(displayTitle)
            }
    }

    func stopAllObservations() {
        titleObserver?.cancel()
        titleObserver = nil

        if let webView = _webView {
            let controller = webView.configuration.userContentController
            controller.removeScriptMessageHandler(forName: "faviconChanged")
        }
    }

    private func initializeUserContentController() {
        let newContentController = WKUserContentController()
        self.individualWebConfiguration.userContentController = newContentController

        newContentController.addUserScript(javaScriptFaviconMonitoringScript)
        newContentController.add(self, name: "faviconChanged")
    }

    // MARK: - Favicon

    private func quickFaviconDownload(from url: URL) async throws -> NSImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = NSImage(data: data)?.downsizedIcon() else {
            throw URLError(.cannotParseResponse)
        }
        return image
    }
}

// MARK: - WKScriptMessageHandler

extension AXTab: WKScriptMessageHandler {
    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "faviconChanged",
              let urlString = message.body as? String,
              let url = URL(string: urlString) else {
            return
        }

        Task { @MainActor in
            let image = try? await quickFaviconDownload(from: url)
            self.icon = image
            self.onFaviconChange?(image)
        }
    }
}

// MARK: - Favicon-monitoring user script

let javaScriptFaviconMonitoringScript = WKUserScript(
    source: jsFaviconMonitoringScript,
    injectionTime: .atDocumentEnd,
    forMainFrameOnly: true
)

private let jsFaviconMonitoringScript = """
    let l,o=document.head,r=["icon","shortcut icon","apple-touch-icon","mask-icon"],f=_=>(u=(()=>{for(const t of r){const e=o.querySelector(`link[rel="${t}"]`);if(e?.href)return e.href}return location.origin+"/favicon.ico"})(),u!==l&&(l=u,window.webkit?.messageHandlers?.faviconChanged?.postMessage(u)));f(),new MutationObserver(f).observe(o,{childList:1,attributes:1,attributeFilter:["href"]});
    """

// MARK: - NSImage helper

extension NSImage {
    /// Downsized 16×16 copy suitable for tab-button favicons.
    func downsizedIcon() -> NSImage? {
        let targetSize = NSSize(width: 16, height: 16)
        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: self.size),
            operation: .copy,
            fraction: 1.0
        )
        resized.unlockFocus()
        return resized
    }
}
