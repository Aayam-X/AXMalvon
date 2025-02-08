//
//  AXTabsManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-07.
//

import AppKit
import WebKit

class AXTabsManager {
    private var browserWebView: AXWebContainerView
    private var tabBarView: AXTabBarViewTemplate
    private var tabGroup: AXTabGroup // tabGroup.tabs, tabs.WKWebView
    
    private var selectedTabIndex = 0 {
        didSet {
            selectedTabIndex = max(0, min(selectedTabIndex, tabGroup.tabs.count - 1))
            tabBarView.selectedTabIndex = selectedTabIndex
            tabGroup.selectedIndex = selectedTabIndex
            browserWebView.selectTabViewItem(at: selectedTabIndex)
        }
    }
    
    init(browserWebView: AXWebContainerView, tabBarView: AXTabBarViewTemplate, tabGroup: AXTabGroup) {
        self.browserWebView = browserWebView
        self.tabBarView = tabBarView
        self.tabGroup = tabGroup
    }
    
    func update(tabGroup: AXTabGroup) {
        tabBarView.updateTabGroup(tabGroup)
        browserWebView.malvonUpdateTabViewItems(tabGroup: tabGroup)
        
        // Setup title observers
        for (index, tab) in tabGroup.tabs.enumerated() {
            let button = tabBarView.tabButton(at: index)
            tab.onTitleChange = { [weak self] newTitle in
                guard let self = self,
                        let newTitle = newTitle
                else { return }
                
                button.webTitle = newTitle
            }
            tab.startTitleObservation()
        }
    }
    
    // MARK: - Public Variables
    var currentTab: AXTab {
        return tabGroup.tabs[selectedTabIndex]
    }
    
    var isEmpty: Bool {
        tabGroup.tabs.isEmpty
    }
    
    // MARK: - Tab Functions
    func addTab(_ tab: AXTab) {
        tabGroup.tabs.append(tab)
        browserWebView.malvonAddWebView(tab: tab)
        
        let button = tabBarView.addTabButton()
        
        selectedTabIndex = tabGroup.tabs.count - 1
        
        tab.onTitleChange = { [weak self] newTitle in
            guard let self = self,
                    let newTitle = newTitle
            else { return }
            
            button.webTitle = newTitle
        }
        
        tab.startTitleObservation()
    }
    
    @discardableResult
    func addEmptyTab(config: WKWebViewConfiguration) -> AXTab {
        let tab = AXTab(creatingEmptyTab: true, configuration: config)
        addTab(tab)
        
        return tab
    }
    
    func switchTab(toIndex: Int) {
        guard selectedTabIndex != toIndex else { return }
        selectedTabIndex = toIndex
    }
    
    func removeTab(at index: Int) {
        guard index >= 0, index < tabGroup.tabs.count else { return }
        
        tabGroup.tabs[index].stopAllObservations()
        tabGroup.tabs.remove(at: index)
        tabBarView.removeTabButton(at: index)
        
        /// Note: Always switch tabs before deleting the tab. As there would be some visual glitch with NSTabView
        if tabGroup.tabs.isEmpty {
            selectedTabIndex = 0
        } else if selectedTabIndex >= tabGroup.tabs.count {
            selectedTabIndex = tabGroup.tabs.count - 1
        }
        
        browserWebView.malvonRemoveWebView(at: index)
    }
    
    func removeCurrentTab() {
        removeTab(at: selectedTabIndex)
    }
}
