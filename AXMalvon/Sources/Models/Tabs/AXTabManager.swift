//
//  AXTabManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//

import AppKit
import WebKit

class AXTabManager {
    weak var appProperties: AXSessionProperties!
    
    // Profile Information
    var currentProfile: AXWebKitProfile { profiles[profileIndex] }
    private var profiles: [AXWebKitProfile]
    private var profileIndex: Int = 0 {
        didSet {
            currentProfile.isCurrent = true
        }
    }
    
    // Tab Group Information
    var currentTabGroup: AXTabGroup { currentProfile.currentTabGroup }
    var currentWebView: AXWebView { currentProfile.currentTabGroup.currentTab.webView }
    
    init(appProperties: AXSessionProperties?) {
        self.appProperties = appProperties
        profiles = [
            .init(name: "Primary", appProperties: appProperties),
            .init(name: "Secondary", appProperties: appProperties),
        ]
    }
}

// MARK: Tab Functions
extension AXTabManager {
//    func switchTab(to: Int) {
//        let currentTabGroup = currentProfile.currentTabGroup
//        currentTabGroup.currentTabIndex = to
//        
//        appProperties.containerView.updateView(webView: currentTabGroup.currentTab.webView)
//    }
    
//    func updateWebContainerView() {
//        appProperties.containerView.updateView(webView: currentTabGroup.currentTab.webView)
//    }
    
    func updateWebContainerView(tab: AXTab) {
        appProperties.containerView.updateView(webView: tab.webView)
    }
    
    func createNewTab(from stringURL: String) {
        guard let url = URL(string: stringURL) else { return }
        let webView = AXWebView(frame: .zero, configuration: currentProfile.configuration)
        webView.load(URLRequest(url: url))
        
        
        let tab = AXTab(url: url, webView: webView)
        currentProfile.currentTabGroup.addTab(tab)
    }
    
    func createNewTab(from url: URL) {
        let webView = AXWebView(frame: .zero, configuration: currentProfile.configuration)
        webView.load(URLRequest(url: url))
        
        
        let tab = AXTab(url: url, webView: webView)
        currentProfile.currentTabGroup.addTab(tab)
    }
    
    func createNewPopupTab(with configuration: WKWebViewConfiguration) -> AXWebView {
        let webView = AXWebView(frame: .zero, configuration: configuration)
        
        
        let tab = AXTab(webView: webView)
        currentProfile.currentTabGroup.addTab(tab)
        
        return webView
    }
    
    func updateTitle(forTab at: Int, with: String) {
        appProperties.containerView.websiteTitleLabel.stringValue = with
        self.appProperties.window.title = with
        // Later on we'll do the sidebar
    }
}

// MARK: Current Web Page Functions
extension AXTabManager {
    func updateCurrentWebPage(with url: URL) {
        currentTabGroup.currentTab.webView.load(URLRequest(url: url))
    }
}

// MARK: Profile Functions
extension AXTabManager {
    func switchProfile(to: Int) {
        profileIndex = to
    }
}
