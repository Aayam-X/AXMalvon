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
    var appProperties: AXAppProperties!
    
    func createNewTab() {
        if appProperties.isPrivate {
            createNewPrivateTab()
            return
        }
        let tabItem = AXTabItem.create(appProperties.currentTab + 1, appProperties: appProperties)
        appProperties.tabs.append(tabItem)
        
        self.switch(appProperties.currentTab + 1)
    }
    
    func createNewPrivateTab() {
        let tabItem = AXTabItem.createPrivate(appProperties.currentTab + 1, appProperties: appProperties)
        appProperties.tabs.append(tabItem)
        
        self.switch(appProperties.currentTab + 1)
    }
    
    func createNewTab(config: WKWebViewConfiguration) -> AXWebView {
        let tabItem = AXTabItem.create(appProperties.currentTab + 1, config, appProperties: appProperties)
        appProperties.tabs.append(tabItem)
        self.switch(appProperties.currentTab + 1)
        
        return tabItem.view
    }
    
    func `switch`(_ toTabNo: Int) {
        let oldTab = appProperties.currentTab
        appProperties.currentTab = toTabNo
        
        appProperties.webContainerView.update(oldTab)
        appProperties.sidebarView.didCreateTab(oldTab)
    }
}
