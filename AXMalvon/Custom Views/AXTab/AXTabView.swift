//
//  AXTabView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-03.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit

class AXTabView: NSView {
    weak var appProperties: AXAppProperties!
    unowned var profile: AXBrowserProfile! // Disabled on private mode
    
    // Views
    var tabStackView = NSStackView()
    
    init(profile: AXBrowserProfile) {
        self.profile = profile
        super.init(frame: .zero)
        
        tabStackView.orientation = .vertical
        tabStackView.spacing = 1.08
        tabStackView.detachesHiddenViews = false
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(tabStackView)
        tabStackView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        tabStackView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        tabStackView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        tabStackView.subviews.removeAll()
        
        for (index, tab) in profile.tabs.enumerated() {
            createTabFromUpdate(index, tab)
        }
        
        // Select the first tab
        let currentButton = tabStackView.arrangedSubviews[profile.currentTab] as! AXSidebarTabButton
        
        currentButton.isSelected = true
        appProperties.currentTabButton = currentButton
        
        // Go to the first tab
        let tab = profile.tabs[profile.currentTab]
        appProperties.currentTab = tab
        appProperties.webContainerView.update(view: tab.view)
    }
    
    func createTab() {
        let webView = AXWebView(frame: .zero, configuration: appProperties.webViewConfiguration)
        webView.addConfigurations()
        webView.loadFileURL(newtabURL!, allowingReadAccessTo: newtabURL!)
        
        var tabItem = AXTabItem(view: webView)
        tabItem.url = webView.url
        profile.tabs.append(tabItem)
        addTabToStackView()
    }
    
    func createTab(_ tab: AXTabItem) {
        profile.tabs.append(tab)
        addTabToStackView()
    }
    
    func createTabFromUpdate(_ index: Int, _ tab: AXTabItem) {
        let button = AXSidebarTabButton(appProperties, profile)
        button.tag = index
        button.startObserving()
        
        button.target = self
        button.action = #selector(tabClick(_:))
        button.tabTitle = tab.title ?? "Untitled"
        tabStackView.addArrangedSubview(button)
        
        button.widthAnchor.constraint(equalTo: tabStackView.widthAnchor).isActive = true
        //Testing
    }
    
    // Adds a button to the stackView
    func addTabToStackView() {
        let tab = profile.tabs[profile.currentTab]
        let button = AXSidebarTabButton(appProperties, profile)
        
        button.target = self
        button.action = #selector(tabClick(_:))
        button.tabTitle = tab.title ?? "Untitled"
        tabStackView.addArrangedSubview(button)
        
        button.tag = profile.tabs.count - 1
        profile.currentTab = button.tag
        
        button.startObserving()
        
        // De-select previous tab
        (tabStackView.arrangedSubviews[safe: profile.previousTab] as? AXSidebarTabButton)?.isSelected = false
        
        // Select current tab
        button.isSelected = true
        
        button.widthAnchor.constraint(equalTo: tabStackView.widthAnchor).isActive = true
        
        self.switch(to: button.tag)
    }
    
    // Adds a button to the stackView
    func addTabToStackViewInBackground(index: Int) {
        let tab = profile.tabs[profile.currentTab]
        let button = AXSidebarTabButton(appProperties, profile)
        
        button.tag = index
        button.startObserving()
        
        button.target = self
        button.action = #selector(tabClick(_:))
        button.tabTitle = tab.title ?? "Untitled"
        tabStackView.addArrangedSubview(button)
        
        button.widthAnchor.constraint(equalTo: tabStackView.widthAnchor).isActive = true
    }
    
    func swapAt(_ first: Int, _ second: Int) {
        let firstButton = tabStackView.arrangedSubviews[first] as! AXSidebarTabButton
        let secondButton = tabStackView.arrangedSubviews[second] as! AXSidebarTabButton
        
        firstButton.tag = second
        secondButton.tag = first
        
        tabStackView.removeArrangedSubview(firstButton)
        tabStackView.insertArrangedSubview(firstButton, at: second)
        tabStackView.insertArrangedSubview(secondButton, at: first)
        
        profile.currentTab = second
        profile.tabs.swapAt(first, second)
    }
    
    func removedTab(_ at: Int) {
        let tab = tabStackView.arrangedSubviews[at] as! AXSidebarTabButton
        tab.stopObserving()
        tab.removeFromSuperview()
        
        updateTabTags(from: at)
        
        (tabStackView.arrangedSubviews[profile.currentTab] as! AXSidebarTabButton).isSelected = true
        self.switch(to: profile.currentTab)
    }
    
    func updateSelection() {
        (tabStackView.arrangedSubviews[safe: profile.previousTab] as? AXSidebarTabButton)?.isSelected = false
        let button = tabStackView.arrangedSubviews[safe: profile.currentTab] as? AXSidebarTabButton
        button?.isSelected = true
        
        appProperties.window.title = button?.title ?? "Untitled"
    }
    
    // WebView calls this function in splitView mode, whenever the user clicks on a different web view
    func webView_updateSelection(webView: AXWebView) {
        profile.currentTab = profile.previousTab
        
        appProperties.webContainerView.currentWebView = webView
        updateSelection()
    }
    
    func insertTabFromAnotherWindow(view: NSView) {
        (tabStackView.arrangedSubviews[safe: profile.currentTab] as! AXSidebarTabButton).isSelected = false
        
        let button = view as! AXSidebarTabButton
        button.stopObserving()
        
        button.target = self
        button.action = #selector(tabClick(_:))
        tabStackView.addArrangedSubview(button)
        button.isSelected = true
        
        button.widthAnchor.constraint(equalTo: tabStackView.widthAnchor).isActive = true
        
        profile.currentTab = tabStackView.arrangedSubviews.count - 1
        button.tag = profile.currentTab
        button.startObserving()
        
        let view = profile.tabs[button.tag].view
        appProperties.webContainerView.update(view: view)
    }
    
    func updateTabTags(from i: Int) {
        for index in i..<tabStackView.arrangedSubviews.count {
            let tab = tabStackView.arrangedSubviews[index] as! AXSidebarTabButton
            tab.tag = index
            
            tab.stopObserving()
            tab.startObserving()
        }
    }
    
    @objc func tabClick(_ sender: NSButton) {
        self.switch(to: sender.tag)
    }
    
    func `switch`(to: Int) {
        if profile.currentTab != to {
            profile.currentTab = to
            updateSelection()
        }
        
        let tab = profile.tabs[to]
        appProperties.webContainerView.update(view: tab.view)
        appProperties.currentTab = tab
        
        appProperties.currentTabButton = tabStackView.arrangedSubviews[to] as? AXSidebarTabButton
    }
}
