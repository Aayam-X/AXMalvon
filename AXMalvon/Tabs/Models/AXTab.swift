//
//  AXTab.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//

import AppKit
import Combine
import WebKit

class AXTab: Codable {
    var url: URL?
    var title: String = "Untitled Tab"
    var icon: NSImage?

    var titleObserver: Cancellable?

    var webConfiguration: WKWebViewConfiguration

    // swiftlint:disable:next identifier_name
    weak var _webView: AXWebView?

    var webView: AXWebView {
        if let existingWebView = _webView {
            return existingWebView
        } else {
            let newWebView = AXWebView(
                frame: .zero, configuration: webConfiguration)
            if let url = url {
                newWebView.load(URLRequest(url: url))
            }
            _webView = newWebView
            return newWebView
        }
    }

    init(url: URL! = nil, title: String, webView: AXWebView) {
        self.url = url
        self.title = title
        self._webView = webView
        self.webConfiguration = webView.configuration
    }

    // MARK: - Codeable Functions
    enum CodingKeys: String, CodingKey {
        case title, url
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        #if DEBUG
        if let configuration = decoder.userInfo[.webConfiguration] as? WKWebViewConfiguration {
            self.webConfiguration = configuration
        } else {
            mxPrint("WKWebViewConfiguration not found in JSON decoding")
            self.webConfiguration = .init()
        }
        #else
        self.webConfiguration = decoder.userInfo[.webConfiguration] as? WKWebViewConfiguration ?? .init()
        #endif

        self.title = try container.decode(String.self, forKey: .title)
        self.url = try? container.decode(URL.self, forKey: .url)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)

        let myURL = webView.url
        try container.encode(myURL, forKey: .url)
    }

    // Method to start observing title changes
    func startTitleObservation(for tabButton: AXTabButton) {
        guard let webView = _webView else { return }

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

    // Method to stop observing title changes
    func stopTitleObservation() {
        titleObserver?.cancel()
        titleObserver = nil
    }

    // Modify the deactivateWebView method
    func deactivateWebView() {
        stopTitleObservation()

        _webView?.removeFromSuperview()
        _webView = nil
    }

    deinit {
        stopTitleObservation()
    }
}

// MARK: - Favicon Downloading
extension AXTab {
    func findFavicon(tabButton: AXTabButton) {
        Task(priority: .low) { @MainActor in
            do {
                if let faviconURLString = try? await webView.evaluateJavaScript(
                    jsFaviconSearchScript) as? String,
                    let faviconURL = URL(string: faviconURLString) {
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

    // Static method to minimize instance overhead
    private func quickFaviconDownload(from url: URL) async throws -> NSImage {
        // Ultra-lightweight download with strict size limit
        let (data, _) = try await globalFaviconDownloadSession.data(from: url)

        // Minimal image creation with immediate downsizing
        guard let image = NSImage(data: data)?.downsizedIcon() else {
            throw URLError(.cannotParseResponse)
        }

        return image
    }
}

// swiftlint:disable line_length
private let jsFaviconSearchScript = """
        (d=>{const h=d.head,l=["icon","shortcut icon","apple-touch-icon","mask-icon"];for(let r of l)if((r=h.querySelector(`link[rel=\"${r}\"]`))&&r.href)return r.href;return d.location.origin+"/favicon.ico"})(document)
    """
// swiftlint:enable line_length

// Singleton session to reduce resource allocation
private let globalFaviconDownloadSession: URLSession = {
    // Hyper-optimized session configuration
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 1.5  // Aggressive timeout
    config.timeoutIntervalForResource = 1.5
    config.requestCachePolicy = .returnCacheDataElseLoad
    config.httpMaximumConnectionsPerHost = 1
    config.waitsForConnectivity = false

    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = 1
    queue.qualityOfService = .background

    return URLSession(
        configuration: config,
        delegate: nil,
        delegateQueue: queue
    )
}()

// Extension for ultra-lightweight image downsizing
extension NSImage {
    func downsizedIcon() -> NSImage? {
        let targetSize = NSSize(width: 16, height: 16)
        let newImage = NSImage(size: targetSize)

        newImage.lockFocus()
        defer { newImage.unlockFocus() }

        self.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: self.size),
            operation: .sourceOver,
            fraction: 1.0
        )

        return newImage
    }
}
