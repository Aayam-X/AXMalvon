//
//  AXWebContainerView.swift
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
    lazy var splitView = AXWebSplitView()
    
    var progressBarObserver: NSKeyValueObservation?
    
    fileprivate var hasDrawn = false
    
    lazy var windowTitleLabel: NSTextField = {
        let title = NSTextField()
        title.isEditable = false
        title.alignment = .left
        title.isBordered = false
        title.usesSingleLineMode = true
        title.drawsBackground = false
        title.alphaValue = 0.3
        return title
    }()
    
    override func viewWillDraw() {
        // self.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.2).cgColor
        if !hasDrawn {
            // Setup title label
            windowTitleLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(windowTitleLabel)
            windowTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: -0.5).isActive = true
            windowTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            
            layer?.shadowOpacity = 0.4
            layer?.shadowColor = NSColor.black.cgColor
            layer?.shadowOffset = .zero
            layer?.shadowRadius = 2
            
            splitView.frame = appProperties.sidebarToggled ? insetWebView(bounds) : bounds.insetBy(dx: 14, dy: 14)
            addSubview(splitView)
            splitView.autoresizingMask = [.height, .width]
            
            hasDrawn = true
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
    
    // override func viewDidEndLiveResize() {
    //  splitView.frame = appProperties.sidebarToggled ? insetWebView(bounds) : bounds.insetBy(dx: 14, dy: 14)
    //  splitView.autoresizingMask = [.height, .width]
    // }
    //
    // override func viewWillStartLiveResize() {
    //  splitView.autoresizingMask = .none
    // }
    
    func updateDelegates() {
        let webView = appProperties.tabs[appProperties.currentTab].view
        webView.uiDelegate = self
        webView.navigationDelegate = self
    }
    
    
    func update() {
        splitView.subviews.removeAll()
        
        let webView = appProperties.tabs[appProperties.currentTab].view
        
        
        if webView.url == nil {
            appProperties.tabs[appProperties.currentTab].load()
        }
        
        if !webView.isLoading {
            appProperties.progressBar.close()
        }
        
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
            let progress = webView.estimatedProgress
            if progress >= 0.93 {
                // Go very fast to 100!
                appProperties.progressBar.updateProgress(1.0)
            } else {
                appProperties.progressBar.smoothProgress(progress)
            }
        })
        
        self.windowTitleLabel.stringValue = webView.title ?? "Untitled"
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
}

extension AXWebContainerView: WKUIDelegate, WKNavigationDelegate, WKDownloadDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return appProperties.tabManager.createNewTab(config: configuration)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        let axWebView = appProperties.tabs[appProperties.currentTab].view
        let selectedTab = appProperties.sidebarView.stackView.arrangedSubviews[appProperties.currentTab] as! AXSidebarTabButton
        axWebView.getFavicon { faviconURL in
            if let favIcon = faviconURL {
                selectedTab.favIconImageView.download(from: favIcon)
            } else {
                selectedTab.favIconImageView.image = NSImage(systemSymbolName: "square.fill", accessibilityDescription: nil)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        appProperties.window.title = appProperties.tabs[appProperties.currentTab].title ?? "Untitled"
        appProperties.sidebarView.checkNavigationButtons()
        self.windowTitleLabel.stringValue = webView.title ?? "Untitled"
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
