//
//  AXTab.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//

import WebKit

class AXTab {
    var url: URL
    var webView: AXWebView
    
    init(url: URL, webView: AXWebView) {
        self.url = url
        self.webView = webView
    }
}
