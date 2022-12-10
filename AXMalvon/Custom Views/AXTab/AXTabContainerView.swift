//
//  AXTabContainerView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXWebContainerView: NSView {
    var appProperties: AXAppProperties!
    
    override func viewWillDraw() {
        self.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.2).cgColor
    }
    
    func enteredFullScreen() {
        subviews[0].frame = bounds
        subviews[0].layer?.cornerRadius = 0.0
    }
    
    func exitedFullScreen() {
        subviews[0].frame = bounds.insetBy(dx: 14, dy: 14)
        subviews[0].layer?.cornerRadius = 5.0
    }
    
    func update(_ oldPosition: Int) {
        appProperties.tabs[safe: oldPosition]?.view.removeFromSuperview()
        
        let webView = appProperties.tabs[appProperties.currentTab].view
        if appProperties.isFullScreen {
            webView.frame = bounds
            webView.layer?.cornerRadius = 0.0
        } else {
            webView.frame = bounds.insetBy(dx: 14, dy: 14)
            webView.layer?.cornerRadius = 5.0
        }
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        addSubview(webView)
        webView.autoresizingMask = [.height, .width]
    }
}

extension AXWebContainerView: WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return appProperties.tabManager.createNewTab(config: configuration)
    }
}
