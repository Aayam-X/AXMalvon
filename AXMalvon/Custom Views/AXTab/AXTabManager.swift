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
    
    func createNewTab() {
        if appProperties.isPrivate {
            createNewPrivateTab()
            return
        }
        
        let tabItem = AXTabItem.create()
        appProperties.tabs.append(tabItem)
        
        self.switch(appProperties.tabs.count - 1)
    }
    
    func createNewPrivateTab() {
        let tabItem = AXTabItem.createPrivate(appProperties: appProperties)
        appProperties.tabs.append(tabItem)
        
        self.switch(appProperties.tabs.count - 1)
    }
    
    func createNewTab(config: WKWebViewConfiguration) -> AXWebView {
        let tabItem = AXTabItem.create(config)
        appProperties.tabs.append(tabItem)
        self.switch(appProperties.tabs.count - 1)
        
        return tabItem.view
    }
    
    func `switch`(_ toTabNo: Int) {
        let oldTab = appProperties.currentTab
        appProperties.currentTab = toTabNo
        
        appProperties.webContainerView.update()
        appProperties.sidebarView.didCreateTab(oldTab)
    }
    
    func removeTab(_ at: Int) {
        let tab = appProperties.tabs[at]
        tab.view.removeFromSuperview()
        
        if appProperties.tabs.count != 1 {
            // My dumbass couldn't solve this so i had to put in OpenAI ChatGPT
            // Update the current tab index if necessary
            if appProperties.currentTab == at {
                if at == appProperties.tabs.count - 1 {
                    // If the removed tab is the last one, set the current tab to the previous one
                    appProperties.currentTab -= 1
                } else {
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
}
