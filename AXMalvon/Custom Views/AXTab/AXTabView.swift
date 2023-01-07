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
    var scrollView: AXScrollView!
    let clipView = AXFlippedClipView()
    
    init(profile: AXBrowserProfile) {
        self.profile = profile
        super.init(frame: .zero)
        
        tabStackView.orientation = .vertical
        tabStackView.spacing = 1.08
        tabStackView.detachesHiddenViews = false
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create scrollView
        scrollView = AXScrollView(horizontalScrollHandler: { [weak self] in
            self?.appProperties.sidebarView.updateProfile()
        })
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
        addSubview(tabStackView)
        tabStackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tabStackView.widthAnchor.constraint(equalTo: clipView.widthAnchor, constant: -8).isActive = true
        scrollView.documentView = tabStackView
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
    }
    
    // Adds a button to the stackView
    func addTabToStackView() {
        let index = profile.tabs.count - 1
        
        let tab = profile.tabs[index]
        let button = AXSidebarTabButton(appProperties, profile)
        
        button.tag = index
        profile.currentTab = index
        button.target = self
        button.action = #selector(tabClick(_:))
        button.tabTitle = tab.title ?? "Untitled"
        
        tabStackView.addArrangedSubview(button)
        button.widthAnchor.constraint(equalTo: tabStackView.widthAnchor).isActive = true
        
        updateSelection()
        button.startObserving()
        
        self.updateAppPropertiesAndWebView(button: button, tab: tab)
    }
    
    // Adds a button to the stackView
    func addTabToStackViewInBackground(index: Int) {
        let button = AXSidebarTabButton(appProperties, profile)
        
        button.tag = index
        button.target = self
        button.action = #selector(tabClick(_:))
        tabStackView.addArrangedSubview(button)
        button.widthAnchor.constraint(equalTo: tabStackView.widthAnchor).isActive = true
        
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
        tabStackView.addArrangedSubview(button)
        button.isSelected = true
        
        button.widthAnchor.constraint(equalTo: tabStackView.widthAnchor).isActive = true
        
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
}
