//
//  AXTab.swift
//  AXTabSystem
//
//  Created by Ashwin Paudel on 2024-11-14.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Combine
import WebKit

class AXTab: Codable {
    var url: URL?
    var title: String = "Untitled Tab"
    weak var icon: NSImage?

    var titleObserver: Cancellable? = nil

    weak var webConfiguration: WKWebViewConfiguration? = nil
    weak var _webView: AXWebView?

    var webView: AXWebView {
        if let existingWebView = _webView {
            return existingWebView
        } else {
            let newWebView = AXWebView(
                frame: .zero, configuration: webConfiguration!)
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
    }

    // MARK: - Codeable Functions
    enum CodingKeys: String, CodingKey {
        case title, url
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.webConfiguration =
            decoder.userInfo[.webConfiguration] as? WKWebViewConfiguration

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
                if self.title != displayTitle {
                    self.updateTabURLAndFavicon(
                        for: webView, tabButton: tabButton)
                }

                self.title = displayTitle
                tabButton.updateTitle(displayTitle)
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
            tabButton.findFavicon(for: webView)
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
