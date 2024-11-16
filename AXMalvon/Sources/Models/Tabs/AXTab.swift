//
//  AXTab.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//

import WebKit

class AXTab: Codable {
    var url: URL?
    var title: String = "Untitled Tab"
    weak var webConfiguration: WKWebViewConfiguration? = nil
    
    var _webView: AXWebView?
    
    var webView: AXWebView {
        // Return the existing `_webView` if it's already initialized
        if let existingWebView = _webView {
            return existingWebView
        } else {
            // `_webView` is nil, so create a new instance
            let newWebView = AXWebView(frame: .zero, configuration: webConfiguration!)
            if let url = url {
                newWebView.load(URLRequest(url: url))
            }
            _webView = newWebView
            return newWebView
        }
    }
    
    init(url: URL! = nil, webView: AXWebView) {
        self.url = url
        self._webView = webView
    }
    
    enum CodingKeys: String, CodingKey {
        case url, title
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        url = try? container.decode(URL.self, forKey: .url)
        title = try container.decode(String.self, forKey: .title)
        
        webConfiguration = decoder.userInfo[.webConfigKey] as? WKWebViewConfiguration
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let currentURL = webView.url
        try container.encode(currentURL, forKey: .url)
        try container.encode(title, forKey: .title)
    }
}
