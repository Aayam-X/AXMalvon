//
//  AXAppProperties.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-05.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import Foundation

// Every AXWindow will have one instance of this
class AXAppProperties {
    // Views
    let sidebarView: AXSideBarView
    let splitView: AXSplitView
    let contentView: AXContentView
    let webContainerView: AXWebContainerView
    
    // State Variables
    var isFullScreen: Bool = false
    var sidebarToggled: Bool
    
    // Variables
    var tabs = [AXTabItem]()
    var currentTab = 0
    
    init() {
        sidebarToggled = (UserDefaults.standard.object(forKey: "sidebarToggled") as? Bool) ?? true
        
        sidebarView = AXSideBarView()
        splitView = AXSplitView()
        contentView = AXContentView()
        webContainerView = AXWebContainerView()
        
        sidebarView.appProperties = self
        contentView.appProperties = self
        webContainerView.appProperties = self
    }
    
    func saveProperties() {
        UserDefaults.standard.set(sidebarToggled, forKey: "sidebarToggled")
    }
}
