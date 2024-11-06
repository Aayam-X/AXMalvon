//
//  AXTabGroup.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//

import AppKit
import WebKit

class AXTabGroup {
    var id = UUID()
    var name: String
    weak var appProperties: AXSessionProperties?
    
    
    var tabs: [AXTab] = []
    var currentTabIndex: Int = 0
    var currentTab: AXTab { tabs[currentTabIndex] }
    
    lazy var tabBarView: AXTabBarView = {
        let tabBarView = AXTabBarView(tabGroup: self, appProperties: self.appProperties)
        
        return tabBarView
    }()
    
    init(name: String = "Untitled Tab Group", _ appProperties: AXSessionProperties?) {
        self.name = name
        self.appProperties = appProperties
    }
    
    func updateTitle(fromTab at: Int, to: String) {
//        if appProperties.tabManager.currentProfile.currentTabGroup.id == self.id && at == currentTabIndex {
//            appProperties.containerView.websiteTitleLabel.stringValue = to
//        }
        
        // Nothing else ig???
    }
    
    func addTab(_ tab: AXTab) {
        let previousIndex = tabs.count - 1
        
        tabs.append(tab)
        tabBarView.addTab(tab: tab)
        tabBarView.updateActiveTab(from: previousIndex, to: tabs.count - 1)
        
        appProperties!.tabManager.switchTab(to: tabs.count - 1)
    }
}
