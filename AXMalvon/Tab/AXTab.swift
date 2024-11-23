//
//  AXTab.swift
//  AXTabSystem
//
//  Created by Ashwin Paudel on 2024-11-14.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXTab: Codable {
    var url: URL?
    var title: String = "Untitled Tab"
    weak var webConfiguration: WKWebViewConfiguration? = nil

    weak var _webView: AXWebView?

    var webView: AXWebView {
        if let existingWebView = _webView {
            return existingWebView
        } else {
            // `_webView` is nil, so create a new instance
            // FIXME: When the user deactivates a tab, a new webview needs to be created
            // The configuration must be set when deactivating a tab.
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

    func deactivateWebView() {
        _webView = nil
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
}
