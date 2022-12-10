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
    var position: Int = 0
    var titleObserver: NSKeyValueObservation?
    var appProperties: AXAppProperties
    
    init(view: AXWebView, position: Int, appProperties: AXAppProperties) {
        self.view = view
        self.position = position
        self.appProperties = appProperties
        
        startObserving()
    }
    
    public func stopObserving() {
        titleObserver?.invalidate()
    }
    
    private func startObserving() {
        titleObserver = self.view.observe(\.title, changeHandler: { [self] webView, value in
            title = webView.title
            appProperties.sidebarView.titleChanged(position)
        })
    }
    
    static public func create(_ p: Int, appProperties: AXAppProperties) -> AXTabItem {
        
        let webView = AXWebView()
        
        webView.addConfigurations()
        webView.layer?.cornerRadius = 5.0
        webView.load(URLRequest(url: URL(string: "https://www.google.com")!))
        
        return .init(view: webView, position: p, appProperties: appProperties)
    }
    
    static public func create(_ p: Int, _ config: WKWebViewConfiguration, appProperties: AXAppProperties) -> AXTabItem {
        let webView = AXWebView(frame: .zero, configuration: config)
        
        webView.addConfigurations()
        webView.layer?.cornerRadius = 5.0
        
        return .init(view: webView, position: p, appProperties: appProperties)
    }
    
}
