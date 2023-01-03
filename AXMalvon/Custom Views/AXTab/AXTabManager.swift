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
    
    var goesToNewTab = true
    
    // Updates every single view
    func updateAll() {
        appProperties.currentTab = 0
        
        appProperties.sidebarView.updateAll()
        appProperties.webContainerView.update()
    }
    
    // Updates every single view
    func switchedProfile() {
        appProperties.webContainerView.splitView.subviews.removeAll()
        
        if appProperties.tabs.isEmpty {
            appProperties.tabManager.createNewTab()
            appProperties.currentTab = 0
        }
        
        appProperties.sidebarView.switchedProfile()
        appProperties.webContainerView.update()
    }
    
    func tabMovedToNewWindow(_ i: Int) {
        let tab = appProperties.tabs[i]
        tab.view.removeFromSuperview()
        
        if appProperties.tabs.count != 1 {
            // Same logic as remove tab
            if appProperties.currentTab == i {
                if i == appProperties.tabs.count {
                    self.switch(to: i - 1)
                }
            } else if appProperties.currentTab > i {
                self.switch(to: i - 1)
            }
            
            appProperties.tabs.remove(at: i)
            appProperties.sidebarView.removedTab(i)
            appProperties.webContainerView.update()
        } else {
            // Close window
            appProperties.window.close()
        }
    }
    
    func tabDraggedToOtherWindow(_ i: Int) {
        let tab = appProperties.tabs[i]
        tab.view.removeFromSuperview()
        
        if appProperties.tabs.count != 1 {
            // Same logic as remove tab
            if appProperties.currentTab == i {
                if i == appProperties.tabs.count - 1 {
                    appProperties.currentTab = i - 1
                }
            } else if appProperties.currentTab > i {
                appProperties.currentTab = i - 1
            }
            
            appProperties.tabs.remove(at: i)
            
            // remove button from stackView
            let button = appProperties.sidebarView.stackView.arrangedSubviews[i]
            button.removeFromSuperview()
            
            appProperties.sidebarView.updatePosition(from: i)
            appProperties.sidebarView.updateSelection()
            appProperties.webContainerView.update()
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
        if appProperties.currentTab != to {
            appProperties.currentTab = to
            appProperties.sidebarView.updateSelection()
        }
        
        appProperties.webContainerView.update()
    }
    
    func closeTab(_ at: Int) {
        let tab = appProperties.tabs[at]
        tab.view.removeFromSuperview()
        
        if let url = tab.view.url {
            appProperties.previouslyClosedTabs.append(url)
        }
        
        if appProperties.tabs.count != 1 {
            // Close tab algorithm
            if appProperties.currentTab == at {
                if at == appProperties.tabs.count - 1 {
                    appProperties.currentTab -= 1
                }
            } else if appProperties.currentTab > at {
                appProperties.currentTab -= 1
            }
            
            appProperties.tabs.remove(at: at)
            appProperties.sidebarView.removedTab(at)
            
            appProperties.webContainerView.update()
        } else {
            // Close window
            appProperties.window.close()
        }
    }
    
    func restoreTab() {
        if !appProperties.previouslyClosedTabs.isEmpty {
            createNewTab(url: appProperties.previouslyClosedTabs.removeLast())
        }
    }
    
    func swapAt(_ first: Int, _ second: Int) {
        if first != second {
            appProperties.tabs.swapAt(first, second)
            appProperties.currentTab = second
            appProperties.sidebarView.swapAt(first, second)
        }
    }
    
    // MARK: - Create New Tab
    @discardableResult
    private func addTabAndUpdate(webView: AXWebView) -> AXWebView {
        var tabItem = AXTabItem(view: webView)
        tabItem.url = webView.url
        appProperties.tabs.append(tabItem)
        
        // This is the only exception
        if goesToNewTab {
            appProperties.currentTab = appProperties.tabs.count - 1
            appProperties.sidebarView.didCreateTab()
            appProperties.webContainerView.update()
        } else {
            appProperties.sidebarView.didCreateTabInBackground(index: appProperties.tabs.count - 1)
            goesToNewTab = true
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
