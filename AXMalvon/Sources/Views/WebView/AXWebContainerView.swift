//
//  AXWebContainerView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import Carbon.HIToolbox
import WebKit

class AXWebContainerView: NSView {
    weak var appProperties: AXAppProperties!
    
    var progressBarObserver: NSKeyValueObservation?
    private var hasDrawn: Bool = false
    
    lazy var splitView = AXWebSplitView()
    
    var currentWebView: AXWebView!
    
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
    
    func removeDelegates() {
        let webView = appProperties.currentTab.view
        webView.uiDelegate = nil
        webView.navigationDelegate = nil
    }
    
    func updateDelegates() {
        let webView = appProperties.currentTab.view
        webView.uiDelegate = self
        webView.navigationDelegate = self
    }
    
    func update(view: AXWebView) {
        currentWebView = view
        splitView.subviews.removeAll()
        
        if view.url == nil {
            appProperties.currentTab.load()
        }
        
        if !view.isLoading {
            appProperties.progressBar.close()
        }
        
        if appProperties.isFullScreen {
            view.frame = bounds
            view.layer?.cornerRadius = 0.0
        } else {
            view.frame = appProperties.sidebarToggled ? insetWebView(bounds) : bounds.insetBy(dx: 14, dy: 14)
            view.layer?.cornerRadius = 5.0
        }
        
        view.navigationDelegate = self
        view.uiDelegate = self
        splitView.addArrangedSubview(view)
        view.autoresizingMask = [.height, .width]
        if let window = view.window as? AXWindow {
            window.makeFirstResponder(view)
        }
        
        progressBarObserver = view.observe(\.estimatedProgress, changeHandler: { [self] _, _ in
            let progress: CGFloat = view.estimatedProgress
            if progress >= 0.93 {
                // Go very fast to 100!
                appProperties.progressBar.updateProgress(1.0)
            } else {
                appProperties.progressBar.smoothProgress(progress)
            }
        })
        
        if let title = view.title {
            self.windowTitleLabel.stringValue = title
            self.window?.title = title
        }
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

// WebView delegates
extension AXWebContainerView: WKUIDelegate, WKNavigationDelegate, WKDownloadDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let webView = (webView as? AXWebView), let contextMenu = webView.contextualMenuAction {
            switch contextMenu {
            case .openInNewTab:
                webView.contextualMenuAction = nil
                return appProperties.tabManager.createNewTab(config: configuration)
            }
        }
        
        return appProperties.tabManager.createNewTab(config: configuration)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        let selectedTab = appProperties.currentTabButton
        
        Task {
            do {
                let favIconURL = try await currentWebView.getFavicon()
                selectedTab?.favIconImageView.download(from: favIconURL)
            } catch {
                selectedTab?.favIconImageView.image = NSImage(systemSymbolName: "square.fill", accessibilityDescription: nil)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        appProperties.window.title = appProperties.currentTab.view.title ?? "Untitled"
        self.windowTitleLabel.stringValue = webView.title ?? "Untitled"
        
        if webView.url != nil && !appProperties.isPrivate {
            AXHistory.appendItem(title: webView.title ?? "Untitled", url: webView.url!.absoluteString)
        }
    }
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
    
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let dialog = NSOpenPanel()
        
        dialog.allowsMultipleSelection = parameters.allowsMultipleSelection
        dialog.canChooseDirectories = parameters.allowsDirectories
        
        // Show panel
        dialog.beginSheetModal(for: appProperties.window) { result in
            if result == .OK, let url = dialog.url {
                completionHandler([url])
            } else {
                completionHandler(nil)
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if let url = navigationAction.request.url,
           let scheme = url.scheme,
           !["https", "about", "http", "file"].contains(scheme),
           let appPath = NSWorkspace.shared.urlForApplication(toOpen: url) {
            Task {
                let alert = AXAlertView(title: "Do you want to open `\(appPath.lastPathComponent)`?")
                let response = await alert.presentAlert(window: self.window!)
                if response {
                    let config = NSWorkspace.OpenConfiguration()
                    config.activates = true
                    NSWorkspace.shared.open([url], withApplicationAt: appPath, configuration: config, completionHandler: nil)
                }
            }
        }
        
        // Download
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download, preferences)
            return
        }
        
        // Modifier Flags
        switch navigationAction.modifierFlags {
        case .command: // New tab
            appProperties.tabManager.navigatesToNewTabOnCreate = false
            appProperties.tabManager.createNewTab(request: navigationAction.request)
            decisionHandler(.cancel, preferences)
            return
        case [.shift, .command]: // New tab + Go to tab
            appProperties.tabManager.createNewTab(request: navigationAction.request)
            decisionHandler(.cancel, preferences)
            return
        case [.option, .command]: // New window in background
            fallthrough
        case [.shift, .option, .command]: // New window + show window
            let window = AXWindow(isPrivate: appProperties.isPrivate, restoresTab: false)
            window.appProperties.tabManager.createNewTab(request: navigationAction.request)
            window.makeKeyAndOrderFront(nil)
            decisionHandler(.cancel, preferences)
            return
        default:
            break
        }
        
        // Default
        decisionHandler(.allow, preferences)
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
        
        let downloadItem = AXDownloadItem(fileName: suggestedFilename, location: fileUrl.absoluteString, url: fileUrl, download: download)
        appProperties.sidebarView.didDownload(downloadItem)
        
        // Save to downloads
        if !appProperties.isPrivate {
            AXDownload.appendItem(fileName: suggestedFilename, location: fileUrl.relativePath)
        }
        
        completionHandler(fileUrl)
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        self.appProperties.tabManager.closeTab(appProperties.currentProfile.currentTab)
    }
    
    // func downloadDidFinish(_ download: WKDownload) { }
}

fileprivate func insetWebView(_ bounds: NSRect) -> NSRect {
    return NSRect(x: bounds.origin.x + 1, y: bounds.origin.y + 14, width: bounds.size.width - 15, height: bounds.size.height - 28)
}
