//
//  AXTabManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-10.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXTabManager {
    weak var appProperties: AXAppProperties!
    
    // When a new tab is created, we will go to that tab
    var navigatesToNewTabOnCreate = true
    
    // Updates every single view
    func updateAll() {
        appProperties.sidebarView.updateAll()
        appProperties.webContainerView.update(view: appProperties.currentProfile.tabs[appProperties.currentProfile.currentTab].view)
    }
    
    func tabMovedToNewWindow(_ i: Int) {
        let tab = appProperties.currentProfile.tabs[i]
        tab.view.removeFromSuperview()
        
        if appProperties.currentProfile.tabs.count != 1 {
            // Go to previous tab
            if appProperties.currentProfile.previousTab == appProperties.currentProfile.tabs.count - 1 {
                if appProperties.currentProfile.currentTab == i {
                    if i == appProperties.currentProfile.tabs.count - 1 {
                        appProperties.currentProfile.currentTab -= 1
                    }
                } else if appProperties.currentProfile.currentTab > i {
                    appProperties.currentProfile.currentTab -= 1
                }
            } else {
                appProperties.currentProfile.currentTab = appProperties.currentProfile.previousTab
            }
            
            appProperties.currentProfile.tabs.remove(at: i)
            appProperties.sidebarView.removedTab(i)
            appProperties.webContainerView.update(view: appProperties.currentProfile.tabs[appProperties.currentProfile.currentTab].view)
        } else {
            // Close window
            appProperties.window.close()
        }
    }
    
    func tabDraggedToOtherWindow(_ i: Int) {
        let tab = appProperties.currentProfile.tabs[i]
        tab.view.removeFromSuperview()
        
        if appProperties.currentProfile.tabs.count != 1 {
            // Go to previous tab
            if appProperties.currentProfile.previousTab == appProperties.currentProfile.tabs.count - 1 {
                if appProperties.currentProfile.currentTab == i {
                    if i == appProperties.currentProfile.tabs.count - 1 {
                        appProperties.currentProfile.currentTab -= 1
                    }
                } else if appProperties.currentProfile.currentTab > i {
                    appProperties.currentProfile.currentTab -= 1
                }
            } else {
                appProperties.currentProfile.currentTab = appProperties.currentProfile.previousTab
            }
            
            appProperties.currentProfile.tabs.remove(at: i)
            
            // Remove button from stackView
            let button = appProperties.sidebarView.tabView.tabStackView.arrangedSubviews[i]
            button.removeFromSuperview()
            
            appProperties.sidebarView.updatePosition(from: i)
            appProperties.sidebarView.updateSelection()
            appProperties.webContainerView.update(view: appProperties.currentProfile.tabs[appProperties.currentProfile.currentTab].view)
        } else {
            // Close window
            appProperties.window.close()
        }
    }
    
    func showSearchField() {
        appProperties.contentView.showSearchBar()
    }
    
    func openSearchBar() {
        appProperties.contentView.displaySearchBarPopover()
    }
    
    // MARK: - Tab functions
    func `switch`(to: Int) {
        appProperties.sidebarView.tabView.switch(to: to)
    }
    
    func closeTab(_ at: Int) {
        print(appProperties.currentProfile.tabs.count)
        let tab = appProperties.currentProfile.tabs[at]
        tab.view.removeFromSuperview()
        
        if let url = tab.view.url {
            appProperties.currentProfile.previouslyClosedTabs.append(url)
        }
        
        if appProperties.currentProfile.tabs.count != 1 {
            // Go to previous tab
            if appProperties.currentProfile.previousTab >= appProperties.currentProfile.tabs.count - 1 {
                if appProperties.currentProfile.currentTab == at {
                    if at == appProperties.currentProfile.tabs.count - 1 {
                        appProperties.currentProfile.currentTab -= 1
                    }
                } else if appProperties.currentProfile.currentTab > at {
                    appProperties.currentProfile.currentTab -= 1
                }
            } else {
                appProperties.currentProfile.currentTab = appProperties.currentProfile.previousTab
            }
            
            appProperties.currentProfile.tabs.remove(at: at)
            appProperties.sidebarView.removedTab(at)
            
            appProperties.webContainerView.update(view: appProperties.currentTab.view)
        } else {
            // Close window
            appProperties.window.close()
        }
    }
    
    func restoreTab() {
        if !appProperties.currentProfile.previouslyClosedTabs.isEmpty {
            createNewTab(url: appProperties.currentProfile.previouslyClosedTabs.removeLast())
        }
    }
    
    func swapAt(_ first: Int, _ second: Int) {
        if first != second {
            appProperties.sidebarView.swapAt(first, second)
        }
    }
    
    // MARK: - Create New Tab
    @discardableResult
    private func addTabAndUpdate(webView: AXWebView) -> AXWebView {
        var tabItem = AXTabItem(view: webView)
        tabItem.url = webView.url
        
        if navigatesToNewTabOnCreate {
            appProperties.sidebarView.createTab(tabItem)
        } else {
            appProperties.sidebarView.didCreateTabInBackground(index: appProperties.currentProfile.tabs.count - 1)
            navigatesToNewTabOnCreate = true
        }
        
        return tabItem.view
    }
    
    func createNewTab(fileURL: URL) {
        // Check if private
        if appProperties.isPrivate {
            createNewPrivateTab(fileURL: fileURL)
            return
        }
        
        // Create webView
        let webView = AXWebView(frame: .zero, configuration: appProperties.webViewConfiguration)
        webView.addConfigurations()
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
        
        // Create tab
        addTabAndUpdate(webView: webView)
    }
    
    func createNewTab(url: URL) {
        // Check if private
        if appProperties.isPrivate {
            createNewPrivateTab(url: url)
            return
        }
        
        // Create webView
        let webView = AXWebView(frame: .zero, configuration: appProperties.webViewConfiguration)
        webView.addConfigurations()
        webView.load(URLRequest(url: url))
        
        addTabAndUpdate(webView: webView)
    }
    
    func createNewTab(request: URLRequest) {
        // Check if private
        if appProperties.isPrivate {
            createNewPrivateTab(request: request)
            return
        }
        
        // Create webView
        let webView = AXWebView(frame: .zero, configuration: appProperties.webViewConfiguration)
        webView.addConfigurations()
        webView.load(request)
        
        addTabAndUpdate(webView: webView)
    }
    
    func createNewTab(request: URLRequest, config: WKWebViewConfiguration) -> AXWebView {
        // Check if private
        if appProperties.isPrivate {
            return createNewPrivateTab(request: request, config: config)
        }
        
        // Create webView
        let webView = AXWebView(frame: .zero, configuration: config)
        webView.addConfigurations()
        webView.load(request)
        
        return addTabAndUpdate(webView: webView)
    }
    
    func createNewTab() {
        // Check if private
        if appProperties.isPrivate {
            createNewPrivateTab()
            return
        }
        
        // Create webView
        let webView = AXWebView(frame: .zero, configuration: appProperties.webViewConfiguration)
        webView.addConfigurations()
        webView.loadFileURL(newtabURL!, allowingReadAccessTo: newtabURL!)
        
        // Create tab
        addTabAndUpdate(webView: webView)
    }
    
    func createNewTab(config: WKWebViewConfiguration) -> AXWebView {
        // Check if private
        if appProperties.isPrivate {
            return createNewPrivateTab(configuration: config)
        }
        
        // Create webView
        let webView = AXWebView(frame: .zero, configuration: config)
        webView.addConfigurations()
        
        // Create tab
        return addTabAndUpdate(webView: webView)
    }
    
    func createNewPrivateTab() {
        // Create webView
        let webView = AXWebView(frame: .zero, configuration: appProperties.webViewConfiguration)
        webView.addConfigurations()
        webView.loadFileURL(newtabURL!, allowingReadAccessTo: newtabURL!)
        
        // Create tab
        addTabAndUpdate(webView: webView)
    }
    
    func createNewPrivateTab(fileURL: URL) {
        let webView = AXWebView(frame: .zero, configuration: appProperties.webViewConfiguration)
        webView.addConfigurations()
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
        
        // Create tab
        addTabAndUpdate(webView: webView)
    }
    
    func createNewPrivateTab(url: URL) {
        let webView = AXWebView(frame: .zero, configuration: appProperties.webViewConfiguration)
        webView.addConfigurations()
        webView.load(URLRequest(url: url))
        
        // Create tab
        addTabAndUpdate(webView: webView)
    }
    
    func createNewPrivateTab(request: URLRequest) {
        let webView = AXWebView(frame: .zero, configuration: appProperties.webViewConfiguration)
        webView.addConfigurations()
        webView.load(request)
        
        // Create tab
        addTabAndUpdate(webView: webView)
    }
    
    func createNewPrivateTab(request: URLRequest, config: WKWebViewConfiguration) -> AXWebView {
        config.websiteDataStore = appProperties.webViewConfiguration.websiteDataStore
        config.processPool = appProperties.webViewConfiguration.processPool
        
        let webView = AXWebView(frame: .zero, configuration: appProperties.webViewConfiguration)
        webView.addConfigurations()
        webView.load(request)
        
        // Create tab
        return addTabAndUpdate(webView: webView)
    }
    
    func createNewPrivateTab(configuration: WKWebViewConfiguration) -> AXWebView {
        configuration.websiteDataStore = appProperties.webViewConfiguration.websiteDataStore
        configuration.processPool = appProperties.webViewConfiguration.processPool
        
        let webView = AXWebView(frame: .zero, configuration: configuration)
        webView.addConfigurations()
        
        // Create tab
        return addTabAndUpdate(webView: webView)
    }
    
}
