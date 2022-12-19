//
//  AXTabContainerView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import Carbon.HIToolbox
import WebKit

class AXWebContainerView: NSView {
    unowned var appProperties: AXAppProperties!
    var splitView = AXWebSplitView()
    
    var progressBarObserver: NSKeyValueObservation?
    
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
        splitView.arrangedSubviews.forEach { view in
            view.layer?.cornerRadius = 0.0
        }
    }
    
    func exitedFullScreen() {
        splitView.frame = appProperties.sidebarToggled ? insetWebView(bounds) : bounds.insetBy(dx: 14, dy: 14)
        splitView.arrangedSubviews.forEach { view in
            view.layer?.cornerRadius = 5.0
        }
    }
    
    func update() {
        splitView.subviews.removeAll()
        appProperties.progressBar.isHidden = true
        
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
        if let window = webView.window as? AXWindow {
            window.makeFirstResponder(webView)
        }
        
        progressBarObserver = webView.observe(\.estimatedProgress, changeHandler: { [self] _, _ in
            appProperties.sidebarView.checkNavigationButtons()
            let progress = webView.estimatedProgress
            if progress == 1.0 {
                appProperties.progressBar.progress = 0.0
                appProperties.progressBar.isHidden = true
            } else {
                appProperties.progressBar.isHidden = false
                appProperties.progressBar.progress = progress
            }
        })
    }
    
    func stopObserving() {
        progressBarObserver?.invalidate()
    }
    
    func insetFrame() {
        splitView.frame = bounds.insetBy(dx: 14, dy: 14)
    }
    
    func insetFrameSidebarOff() {
        splitView.frame = insetWebView(bounds)
    }
    
    func showFindView() {
        appProperties.findBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(appProperties.findBar)
        appProperties.findBar.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        appProperties.findBar.heightAnchor.constraint(equalToConstant: 30).isActive = true
        appProperties.findBar.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
        appProperties.findBar.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
        appProperties.findBar.searchField.becomeFirstResponder()
    }
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.characters {
            case "1": // There is always going to be one tab, so no checking
                appProperties.tabManager.switch(to: 0)
            case "2" where 2 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 1)
            case "3" where 3 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 2)
            case "4" where 4 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 3)
            case "5" where 5 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 4)
            case "6" where 6 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 5)
            case "7" where 7 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 6)
            case "8" where 8 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 7)
            case "9":
                appProperties.tabManager.switch(to: appProperties.tabs.count - 1)
            default:
                super.keyDown(with: event)
            }
        }
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
        
        var fileUrl = documentDirectory.appendingPathComponent("\(suggestedFilename)", isDirectory: false)
        
        var index = 1
        while fileManager.fileExists(atPath: fileUrl.relativePath) {
            fileUrl = documentDirectory.appendingPathComponent("_\(index)\(suggestedFilename)", isDirectory: false)
            index += 1
        }
        
        appProperties.sidebarView.didDownload(.init(fileName: suggestedFilename, location: fileUrl, download: download))
        
        completionHandler(fileUrl)
    }
    
    // func downloadDidFinish(_ download: WKDownload) { }
}

fileprivate func insetWebView(_ bounds: NSRect) -> NSRect {
    return NSRect(x: bounds.origin.x + 1, y: bounds.origin.y + 14, width: bounds.size.width - 15, height: bounds.size.height - 28)
}
