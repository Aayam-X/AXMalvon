//
//  AXTabManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-10.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXTabManager {
    unowned var appProperties: AXAppProperties!
    
    // Updates every single view
    func updateAll() {
        appProperties.currentTab = 0
        appProperties.sidebarView.updateAll()
        appProperties.webContainerView.update()
    }
    
    func tabMovedToNewWindow(_ i: Int) {
        let tab = appProperties.tabs[i]
        tab.view.removeFromSuperview()
        
        if appProperties.tabs.count != 1 {
            appProperties.currentTab = i - 1
            appProperties.tabs.remove(at: i)
            appProperties.sidebarView.removedTab(i)
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
    
    func createNewTab(fileURL: URL) {
        let tabItem = create(fileURL: fileURL)
        appProperties.tabs.append(tabItem)
        
        self.didCreateNewTab(appProperties.tabs.count - 1)
    }
    
    func createNewTab(url: URL) {
        let tabItem = create(url: url)
        appProperties.tabs.append(tabItem)
        
        self.didCreateNewTab(appProperties.tabs.count - 1)
    }
    
    func createNewTab() {
        if appProperties.isPrivate {
            createNewPrivateTab()
            return
        }
        
        let tabItem = create()
        appProperties.tabs.append(tabItem)
        
        self.didCreateNewTab(appProperties.tabs.count - 1)
    }
    
    func createNewPrivateTab() {
        let tabItem = createPrivate(appProperties: appProperties)
        appProperties.tabs.append(tabItem)
        
        self.didCreateNewTab(appProperties.tabs.count - 1)
    }
    
    func createNewTab(config: WKWebViewConfiguration) -> AXWebView {
        let tabItem = create(config)
        appProperties.tabs.append(tabItem)
        self.didCreateNewTab(appProperties.tabs.count - 1)
        
        return tabItem.view
    }
    
    /// After creating a new tab, you will update the sidebar and the web container view
    func didCreateNewTab(_ at: Int) {
        let oldTab = appProperties.currentTab
        appProperties.currentTab = at
        
        appProperties.webContainerView.update()
        appProperties.sidebarView.didCreateTab(oldTab)
    }
    
    func removeTab(_ at: Int) {
        let tab = appProperties.tabs[at]
        tab.view.removeFromSuperview()
        
        if appProperties.tabs.count != 1 {
            if appProperties.currentTab == at {
                if at == appProperties.tabs.count - 1 {
                    // If the removed tab is the last one, set the current tab to the previous one
                    appProperties.currentTab -= 1
                } else if at != 0 {
                    // If the removed tab is not the last one, set the current tab to the next one
                    appProperties.currentTab += 1
                }
            } else if appProperties.currentTab > at {
                // If the removed tab is before the current tab, decrement the current tab index
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
    
    func swapAt(_ first: Int, _ second: Int) {
        appProperties.tabs.swapAt(first, second)
        appProperties.currentTab = second
        appProperties.sidebarView.swapAt(first, second)
    }
}


fileprivate func create() -> AXTabItem {
    let webView = AXWebView()
    
    webView.addConfigurations()
    webView.layer?.cornerRadius = 5.0
    
    webView.loadFileURL(newtabURL!, allowingReadAccessTo: newtabURL!)
    
    return .init(view: webView)
}

fileprivate func create(url: URL) -> AXTabItem {
    let webView = AXWebView()
    
    webView.addConfigurations()
    webView.layer?.cornerRadius = 5.0
    webView.load(URLRequest(url: url))
    
    return .init(view: webView)
}

fileprivate func create(fileURL: URL) -> AXTabItem {
    let webView = AXWebView()
    
    webView.addConfigurations()
    webView.layer?.cornerRadius = 5.0
    webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
    
    return .init(view: webView)
}

fileprivate func create(_ config: WKWebViewConfiguration) -> AXTabItem {
    let webView = AXWebView(frame: .zero, configuration: config)
    
    webView.addConfigurations()
    webView.layer?.cornerRadius = 5.0
    
    return .init(view: webView)
}

fileprivate func createPrivate(appProperties: AXAppProperties) -> AXTabItem {
    let webView = AXWebView(frame: .zero, configuration: appProperties.configuration!)
    webView.addConfigurations()
    
    webView.loadFileURL(newtabURL!, allowingReadAccessTo: newtabURL!)
    
    return .init(view: webView)
}
