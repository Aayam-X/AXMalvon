//
//  AXTabItem.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXTabItem {
    var title: String?
    var view: AXWebView
    
    init(view: AXWebView) {
        self.view = view
    }
    
    
    static public func create() -> AXTabItem {
        
        let webView = AXWebView()
        
        webView.addConfigurations()
        webView.layer?.cornerRadius = 5.0
        webView.load(URLRequest(url: URL(string: "https://www.google.com")!))
        
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
        
        webView.load(URLRequest(url: URL(string: "https://www.google.com")!))
        
        return .init(view: webView)
    }
}
