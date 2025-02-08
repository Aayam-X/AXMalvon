//
//  AXTabsManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-07.
//

import AppKit
import WebKit

class AXTabsManager {
    private var selectedTabIndex = 0 {
        didSet {
            guard !tabGroup.tabs.isEmpty else {
                selectedTabIndex = 0
                return
            }
            selectedTabIndex = max(0, min(selectedTabIndex, tabGroup.tabs.count - 1))
            tabBarView.selectedTabIndex = selectedTabIndex
            tabGroup.selectedIndex = selectedTabIndex
        }
    }
    
    private var browserWebView: AXWebContainerView
    private var tabBarView: AXTabBarViewTemplate
    private var tabGroup: AXTabGroup
    
    init(browserWebView: AXWebContainerView, tabBarView: AXTabBarViewTemplate, tabGroup: AXTabGroup) {
        self.browserWebView = browserWebView
        self.tabBarView = tabBarView
        self.tabGroup = tabGroup
    }
    
    func update(tabGroup: AXTabGroup) {
        tabBarView.updateTabGroup(tabGroup)
        browserWebView.malvonUpdateTabViewItems(tabGroup: tabGroup)
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
        tabBarView.addTabButton()
        browserWebView.malvonAddWebView(tab: tab)
        
        selectedTabIndex = tabGroup.tabs.count - 1
        browserWebView.selectTabViewItem(at: selectedTabIndex, tab: tab)
    }
    
    @discardableResult
    func addEmptyTab(config: WKWebViewConfiguration) -> AXTab {
        let tab = AXTab(creatingEmptyTab: true, configuration: config)
        tabGroup.tabs.append(tab)
        tabBarView.addTabButton()
        browserWebView.malvonAddWebView(tab: tab)
        
        selectedTabIndex = tabGroup.tabs.count - 1
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
        browserWebView.malvonRemoveWebView(at: index)
        
        if tabGroup.tabs.isEmpty {
            selectedTabIndex = 0
        } else if selectedTabIndex >= tabGroup.tabs.count {
            selectedTabIndex = tabGroup.tabs.count - 1
        }
    }
    
    func removeCurrentTab() {
        removeTab(at: selectedTabIndex)
    }
}
