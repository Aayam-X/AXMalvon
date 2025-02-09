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
    
    private var previousTabIndex: Int = -1
    
    private var selectedTabIndex = 0 {
        didSet {
            previousTabIndex = oldValue
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
    
    /// Base configuration is needed in the case that no tabs exist.
    func update(tabGroup: AXTabGroup, baseConfiguration: WKWebViewConfiguration) {
        self.tabGroup = tabGroup
        
        if tabGroup.tabs.isEmpty {
            addEmptyTab(config: baseConfiguration)
        }
        
        tabBarView.updateTabGroup(tabGroup)
        browserWebView.malvonUpdateTabViewItems(tabGroup: tabGroup)
        self.selectedTabIndex = tabGroup.selectedIndex
        
        // Setup title observers
        for (index, tab) in tabGroup.tabs.enumerated() {
            let button = tabBarView.tabButton(at: index)
            tab.onTitleChange = { newTitle in
                guard let newTitle = newTitle else { return }
                
                button.webTitle = newTitle
            }
            
            tab.onFaviconChange = { newFavicon in
                guard let icon = newFavicon else { return }
                
                button.favicon = icon
            }
            tab.startTitleObservation()
        }
    }
    
    // MARK: - Public Variables
    var currentTab: AXTab? {
        if selectedTabIndex >= tabGroup.tabs.count {
            return nil
        }
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
        button.webTitle = "New Tab"
        
        selectedTabIndex = tabGroup.tabs.count - 1
        print(selectedTabIndex, button.tag)
        
        tab.onTitleChange = { newTitle in
            guard let newTitle = newTitle else { return }
            
            button.webTitle = newTitle
        }
        
        tab.onFaviconChange = { newFavicon in
            guard let icon = newFavicon else { return }
            
            button.favicon = icon
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
        browserWebView.malvonRemoveWebView(at: index)
        
        if selectedTabIndex == index {
            if previousTabIndex == -1 {
                selectedTabIndex = tabGroup.tabs.count - 1
            } else {
                selectedTabIndex = min(previousTabIndex, tabGroup.tabs.count - 1)
            }
        } else if selectedTabIndex > index {
            selectedTabIndex -= 1
        }
        
        mxPrint(selectedTabIndex)
    }
    
    func removeCurrentTab() {
        removeTab(at: selectedTabIndex)
    }
}
