//
//  AXTabItem.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

let newtabURL = Bundle.main.url(forResource: "newtab", withExtension: "html")

struct AXTabItem: Codable {
    var title: String?
    var url: URL?
    var view: AXWebView
    
    init(view: AXWebView) {
        self.view = view
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try values.decode(String.self, forKey: .title)
        url = try? values.decode(URL.self, forKey: .url)
        
        view = AXWebView()
        view.addConfigurations()
        view.layer?.cornerRadius = 5.0
        view.load(URLRequest(url: url ?? URL(string: "https://www.google.com")!))
    }
    
    enum CodingKeys: CodingKey {
        case title
        case url
    }
    
    static public func create() -> AXTabItem {
        let webView = AXWebView()
        
        webView.addConfigurations()
        webView.layer?.cornerRadius = 5.0
        
        webView.loadFileURL(newtabURL!, allowingReadAccessTo: newtabURL!)
        
        return .init(view: webView)
    }
    
    static public func create(url: URL) -> AXTabItem {
        let webView = AXWebView()
        
        webView.addConfigurations()
        webView.layer?.cornerRadius = 5.0
        webView.load(URLRequest(url: url))
        
        return .init(view: webView)
    }
    
    static public func create(fileURL: URL) -> AXTabItem {
        let webView = AXWebView()
        
        webView.addConfigurations()
        webView.layer?.cornerRadius = 5.0
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
        
        return .init(view: webView)
    }
    
    static public func create(_ config: WKWebViewConfiguration) -> AXTabItem {
        let webView = AXWebView(frame: .zero, configuration: config)
        
        webView.addConfigurations()
        webView.layer?.cornerRadius = 5.0
        
        return .init(view: webView)
    }
    
    static public func createPrivate(appProperties: AXAppProperties) -> AXTabItem {
        let webView = AXWebView(frame: .zero, configuration: appProperties.configuration!)
        webView.addConfigurations()
        
        webView.loadFileURL(newtabURL!, allowingReadAccessTo: newtabURL!)
        
        return .init(view: webView)
    }
}
