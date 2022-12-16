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
    unowned var appProperties: AXAppProperties!
    var splitView = AXWebSplitView()
    
    var hasDrawn = false
    
    override func viewWillDraw() {
        // self.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.2).cgColor
        if !hasDrawn {
            layer?.shadowOpacity = 0.4
            layer?.shadowColor = NSColor.black.cgColor
            layer?.shadowOffset = .zero
            layer?.shadowRadius = 2
            
            splitView.frame = appProperties.sidebarToggled ? insetWebView(bounds) : bounds.insetBy(dx: 14, dy: 14)
            addSubview(splitView)
            splitView.autoresizingMask = [.height, .width]
        }
    }
    
    func enteredFullScreen() {
        splitView.frame = bounds
        splitView.layer?.cornerRadius = 0.0
    }
    
    func exitedFullScreen() {
        splitView.frame = appProperties.sidebarToggled ? insetWebView(bounds) : bounds.insetBy(dx: 14, dy: 14)
        splitView.layer?.cornerRadius = 5.0
    }
    
    func update() {
        splitView.subviews.removeAll()
        
        let webView = appProperties.tabs[appProperties.currentTab].view
        
        if appProperties.isFullScreen {
            webView.frame = bounds
            webView.layer?.cornerRadius = 0.0
        } else {
            webView.frame = appProperties.sidebarToggled ? insetWebView(bounds) : bounds.insetBy(dx: 14, dy: 14)
            webView.layer?.cornerRadius = 5.0
        }
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        splitView.addArrangedSubview(webView)
        webView.autoresizingMask = [.height, .width]
    }
    
    func insetFrame() {
        splitView.frame = bounds.insetBy(dx: 14, dy: 14)
    }
    
    func insetFrameSidebarOff() {
        splitView.frame = insetWebView(bounds)
    }
}

extension AXWebContainerView: WKUIDelegate, WKNavigationDelegate, WKDownloadDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return appProperties.tabManager.createNewTab(config: configuration)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        appProperties.window.title = appProperties.tabs[appProperties.currentTab].title ?? "Untitled"
    }
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download, preferences)
        } else {
            decisionHandler(.allow, preferences)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }
    
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        print(documentDirectory)
        let fileUrl =  documentDirectory.appendingPathComponent("\(suggestedFilename)", isDirectory: false)
        
        completionHandler(fileUrl)
    }
    
    func downloadDidFinish(_ download: WKDownload) {
        print("Hellioewdjks")
    }
}

fileprivate func insetWebView(_ bounds: NSRect) -> NSRect {
    return NSRect(x: bounds.origin.x + 1, y: bounds.origin.y + 14, width: bounds.size.width - 15, height: bounds.size.height - 28)
}
