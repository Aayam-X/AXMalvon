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
    var scrollView: AXSidebarScrollView!
    let clipView = AXFlippedClipView()
    
    init(profile: AXBrowserProfile) {
        self.profile = profile
        super.init(frame: .zero)
        
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        tabStackView.orientation = .vertical
        tabStackView.spacing = 1.08
        tabStackView.detachesHiddenViews = false
        
        // Create scrollView
        scrollView = AXSidebarScrollView(scrollWheelHandler: {self.appProperties.sidebarView.scrollWheel(with: $0)})
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.drawsBackground = false
        scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        // Setup clipview
        clipView.translatesAutoresizingMaskIntoConstraints = false
        clipView.drawsBackground = false
        scrollView.contentView = clipView
        clipView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        clipView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
        clipView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        clipView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        // Setup stackView
        scrollView.documentView = tabStackView
        tabStackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tabStackView.leftAnchor.constraint(equalTo: clipView.leftAnchor).isActive = true
        tabStackView.rightAnchor.constraint(equalTo: clipView.rightAnchor).isActive = true
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
    
    func updateInBackground() {
        tabStackView.subviews.removeAll()
        
        for (index, tab) in profile.tabs.enumerated() {
            createTabFromUpdate(index, tab)
        }
        
        // Select the first tab
        if profile.currentTab >= tabStackView.arrangedSubviews.count - 1 {
            profile.currentTab = 0
        }
        
        let currentButton = tabStackView.arrangedSubviews[profile.currentTab] as! AXSidebarTabButton
        currentButton.isSelected = true
    }
    
    func createTab() {
        let config = (profile != nil) ? AXGlobalProperties.shared.profiles[profile.index].configuration : appProperties.currentWebViewConfiguration!
        
        let webView = AXWebView(frame: .zero, configuration: config)
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
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = index
        button.startObserving()
        
        button.target = self
        button.action = #selector(tabClick(_:))
        button.tabTitle = tab.title ?? "Untitled"
        addButtonToStackView(button)
    }
    
    // Adds a button to the stackView
    func addTabToStackView() {
        let index = profile.tabs.count - 1
        
        let tab = profile.tabs[index]
        let button = AXSidebarTabButton(appProperties, profile)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.tag = index
        profile.currentTab = index
        button.target = self
        button.action = #selector(tabClick(_:))
        button.tabTitle = tab.title ?? "Untitled"
        
        addButtonToStackView(button)
        
        updateSelection()
        button.startObserving()
        
        self.updateAppPropertiesAndWebView(button: button, tab: tab)
    }
    
    // Adds a button to the stackView
    func addTabToStackViewInBackground(index: Int) {
        let button = AXSidebarTabButton(appProperties, profile)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.tag = index
        button.target = self
        button.action = #selector(tabClick(_:))
        addButtonToStackView(button)
        
        button.startObserving()
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
        appProperties.webContainerView.updateDelegates()
        updateSelection()
    }
    
    func updateCurrentTab(to: Int) {
        profile.currentTab = to
        
        let button = tabStackView.arrangedSubviews[to] as? AXSidebarTabButton
        let tab = profile.tabs[to]
        
        appProperties.currentTab = tab
        appProperties.currentTabButton = button
        
        appProperties.webContainerView.update(view: tab.view)
    }
    
    func insertTabFromAnotherWindow(view: NSView) {
        (tabStackView.arrangedSubviews[safe: profile.currentTab] as! AXSidebarTabButton).isSelected = false
        
        let button = view as! AXSidebarTabButton
        button.stopObserving()
        
        button.target = self
        button.action = #selector(tabClick(_:))
        addButtonToStackView(button)
        
        button.isSelected = true
        
        profile.currentTab = tabStackView.subviews.count - 1
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
        
        appProperties.currentTab = tab
        appProperties.currentTabButton = tabStackView.arrangedSubviews[to] as? AXSidebarTabButton
        appProperties.webContainerView.update(view: tab.view)
    }
    
    func updateAppPropertiesAndWebView(button: AXSidebarTabButton, tab: AXTabItem) {
        appProperties.currentTab = tab
        appProperties.currentTabButton = button
        
        appProperties.webContainerView.update(view: tab.view)
    }
    
    func updateAppPropertiesAndWebView() {
        let button = tabStackView.arrangedSubviews[profile.currentTab] as! AXSidebarTabButton
        let tab = profile.tabs[profile.currentTab]
        
        updateAppPropertiesAndWebView(button: button, tab: tab)
    }
    
    private func addButtonToStackView(_ button: NSButton) {
        tabStackView.addArrangedSubview(button)
        button.leftAnchor.constraint(equalTo: tabStackView.leftAnchor, constant: 10).isActive = true
        button.rightAnchor.constraint(equalTo: tabStackView.rightAnchor, constant: -9).isActive = true
    }
}
