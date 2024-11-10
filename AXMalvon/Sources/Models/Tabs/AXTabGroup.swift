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
    
    var isCurrentTabGroup = false
    
    
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
    
    func activeTitleChanged(_ newTitle: String) {
        if self.isCurrentTabGroup {
            appProperties?.containerView.websiteTitleLabel.stringValue = newTitle
        }
    }
    
    func addTab(_ tab: AXTab) {
        let previousIndex = currentTabIndex
        
        tabs.append(tab)
        tabBarView.addTab(tab: tab)
        
        if previousIndex == -1 {
            tabBarView.updateActiveTab(to: 0)
        } else {
            tabBarView.updateActiveTab(from: previousIndex, to: tabs.count - 1)
        }        
    }
    
    func switchTab(to index: Int) {
        let previousIndex = currentTabIndex
        currentTabIndex = index
        
        tabBarView.updateActiveTab(from: previousIndex, to: index)
    }
    
    func removeTab(at: Int) {
        tabs.remove(at: at)
        currentTabIndex = currentTabIndex > at ? currentTabIndex - 1 : currentTabIndex
        
        tabBarView.removeTabButton(at)
    }
    
    func removeTab() {
        tabs.remove(at: currentTabIndex)
        currentTabIndex -= 1
        tabBarView.removeTabButton(currentTabIndex)
    }
}
