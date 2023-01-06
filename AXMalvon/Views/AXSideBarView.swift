//
//  AXSideBarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-04.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit


enum AXScrollViewScrollDirection {
    case left
    case right
}

var AXMalvon_SidebarView_scrollDirection: AXScrollViewScrollDirection! = .left


class AXSideBarView: NSView {
    // MARK: - Variables
    weak var appProperties: AXAppProperties!
    private var hasDrawn: Bool = false
    
    var trackingArea: NSTrackingArea!
    weak var toggleSidebarButtonLeftConstaint: NSLayoutConstraint?
    let supportedDraggingTypes: [NSPasteboard.PasteboardType] = [.URL, .init("com.aayamx.malvon.tabButton")]
    override var tag: Int { 0x01 }
    
    lazy var tabView: AXTabView! = {
        let tabView = AXTabView(profile: appProperties.currentProfile)
        tabView.appProperties = self.appProperties
        return tabView
    }()
    
    lazy var toggleSidebarButton: AXHoverButton = {
        let button = AXHoverButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.controlSize = .large
        button.target = self
        button.action = #selector(toggleSidebar)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var backButton: AXHoverButton = {
        let button = AXHoverButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "arrow.backward", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.target = self
        button.action = #selector(backButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var forwardButton: AXHoverButton = {
        let button = AXHoverButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "arrow.forward", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.target = self
        button.action = #selector(forwardButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var reloadButton: AXHoverButton = {
        let button = AXHoverButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.target = self
        button.action = #selector(reloadButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    var downloadsStackView: NSStackView!
    
    // MARK: - Functions
    override func viewWillDraw() {
        if !hasDrawn {
            // Configure Self
            trackingArea = NSTrackingArea(rect: .init(x: bounds.origin.x - 100, y: bounds.origin.y, width: bounds.size.width + 100, height: bounds.size.height), options: [.activeAlways, .mouseEnteredAndExited], owner: self)
            addTrackingArea(trackingArea)
            self.registerForDraggedTypes(supportedDraggingTypes)
            
            // Constraints for toggleSidebarButton
            addSubview(toggleSidebarButton)
            toggleSidebarButton.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
            toggleSidebarButtonLeftConstaint = toggleSidebarButton.leftAnchor.constraint(equalTo: leftAnchor, constant: appProperties.isFullScreen ? 5 : 76)
            toggleSidebarButtonLeftConstaint?.isActive = true
            toggleSidebarButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
            toggleSidebarButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
            
            // Constaints for reloadButton
            addSubview(reloadButton)
            reloadButton.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
            reloadButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
            reloadButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
            reloadButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
            
            // Constaints for forwardButton
            addSubview(forwardButton)
            forwardButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
            forwardButton.rightAnchor.constraint(equalTo: reloadButton.leftAnchor, constant: -10).isActive = true
            forwardButton.widthAnchor.constraint(equalToConstant: 23).isActive = true
            forwardButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
            
            // Constaints for backButton
            addSubview(backButton)
            backButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
            backButton.rightAnchor.constraint(equalTo: forwardButton.leftAnchor, constant: -10).isActive = true
            backButton.widthAnchor.constraint(equalToConstant: 23).isActive = true
            backButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
            
            // Setup profileListView
            if let profileList = appProperties.profileList {
                profileList.translatesAutoresizingMaskIntoConstraints = false
                addSubview(profileList)
                profileList.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14).isActive = true
                profileList.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
                profileList.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
                profileList.heightAnchor.constraint(equalToConstant: 30).isActive = true
            }
            
            // Setup tabView
            appProperties.profileManager?.switchProfiles(to: appProperties.currentProfileIndex)
            
            hasDrawn = true
        }
    }
    
    // MARK: - Actions
    
    @objc func toggleSidebar() {
        appProperties.sidebarToggled.toggle()
        layer?.backgroundColor = .none
        
        if appProperties.sidebarToggled {
            appProperties.window.hideTrafficLights(false)
            appProperties.splitView.insertArrangedSubview(self, at: 0)
            if !appProperties.isFullScreen {
                appProperties.webContainerView.insetFrameSidebarOff()
            }
        } else {
            appProperties.window.hideTrafficLights(true)
            if !appProperties.isFullScreen {
                appProperties.webContainerView.insetFrame()
            }
            self.removeFromSuperview()
        }
    }
    
    @objc func tabClick(_ sender: NSButton) {
        // appProperties.tabManager.switch(to: sender.tag)
    }
    
    @objc func backButtonAction() {
        let webView = appProperties.currentTab.view
        webView.goBack()
    }
    
    @objc func forwardButtonAction() {
        let webView = appProperties.currentTab.view
        webView.goForward()
    }
    
    @objc func reloadButtonAction() {
        appProperties.currentTab.view.reload()
    }
    
    func checkNavigationButtons() {
        let webView = appProperties.currentTab.view
        
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }
    
    // MARK: - Mouse Functions
    
    func updateProfile() {
        if let direction = AXMalvon_SidebarView_scrollDirection {
            // Update the profile
            var index: Int = appProperties.currentProfileIndex
            if direction == .left {
                index -= 1
            } else {
                index += 1
            }
            
            appProperties.profileManager?.switchProfiles(to: index)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if !appProperties.sidebarToggled {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.1
                appProperties.sidebarView.animator().frame.origin.x = -bounds.width
            }, completionHandler: {
                self.layer?.backgroundColor = .none
                self.removeFromSuperview()
            })
            
            appProperties.window.hideTrafficLights(true)
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        let x = event.scrollingDeltaX
        let y = event.scrollingDeltaY
        
        if x == 0 && y == 0 {
            updateProfile()
            return
        }
        
        if y == 0 {
            if x > 0 {
                AXMalvon_SidebarView_scrollDirection = .left
            }
            if x < 0 {
                AXMalvon_SidebarView_scrollDirection = .right
            }
        } else {
            AXMalvon_SidebarView_scrollDirection = nil
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    
    // MARK: - View Functions
    
    override func viewDidEndLiveResize() {
        appProperties.sidebarWidth = self.frame.size.width
        removeTrackingArea(trackingArea)
        trackingArea = NSTrackingArea(rect: .init(x: bounds.origin.x - 100, y: bounds.origin.y, width: bounds.size.width + 100, height: bounds.size.height), options: [.activeAlways, .mouseEnteredAndExited], owner: self)
        addTrackingArea(trackingArea)
        
        if appProperties.sidebarToggled {
            layer?.backgroundColor = .clear
        }
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        if oldSize.height == frame.height {
            if !appProperties.isFullScreen && appProperties.sidebarToggled {
                if frame.width >= 210 {
                    self.layer?.backgroundColor = .clear
                } else {
                    self.layer?.backgroundColor = NSColor.red.cgColor
                }
            }
        }
    }
    
    func enteredFullScreen() {
        toggleSidebarButtonLeftConstaint?.constant = 5
    }
    
    func exitedFullScreen() {
        toggleSidebarButtonLeftConstaint?.constant = 76
    }
    
    // MARK: - Tab Functions
    
    func updateAll() {
        tabView.update()
    }
    
    // Add a new item into the stackview
    func didCreateTab() {
        tabView.addTabToStackView()
    }
    
    func createTab(_ tab: AXTabItem) {
        tabView.createTab(tab)
    }
    
    // Add a new item into the stackview
    func didCreateTabInBackground(index: Int) {
        tabView.addTabToStackViewInBackground(index: index)
    }
    
    func swapAt(_ first: Int, _ second: Int) {
        tabView.swapAt(first, second)
    }
    
    func removedTab(_ at: Int) {
        tabView.removedTab(at)
    }
    
    func didDownload(_ d: AXDownloadItem) {
        if downloadsStackView == nil {
            downloadsStackView = NSStackView()
            
            downloadsStackView.orientation = .vertical
            downloadsStackView.spacing = 1.08
            downloadsStackView.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(downloadsStackView)
            downloadsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -44).isActive = true
            downloadsStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
            downloadsStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
        }
        
        if downloadsStackView.subviews.count == 3 {
            downloadsStackView.subviews.first?.removeFromSuperview()
        }
        
        let button = AXSidebarDownloadButton(appProperties, d)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.startObserving()
        
        downloadsStackView.addArrangedSubview(button)
        
        button.widthAnchor.constraint(equalTo: downloadsStackView.widthAnchor).isActive = true
    }
    
    func updateSelection() {
        tabView.updateSelection()
    }
    
    func webView_updateSelection(webView: AXWebView) {
        tabView.webView_updateSelection(webView: webView)
    }
    
    func insertTabFromOtherWindow(view: NSView) {
        tabView.insertTabFromAnotherWindow(view: view)
    }
    
    // MARK: - Drag and Drop
    //    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    //        if let button = sender.draggingSource as? AXSidebarTabButton {
    //            if button.window?.windowNumber != self.window?.windowNumber {
    //                button.draggingState = .addToSidebarView
    //            }
    //        }
    //
    //        return .copy
    //    }
    
    func updatePosition(from i: Int) {
        tabView.updateTabTags(from: i)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteBoardItemIsValid = sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self, AXSidebarTabButton.self])
        self.window?.orderFront(nil)
        
        if let button = sender.draggingSource as? AXSidebarTabButton {
            if button.window?.windowNumber != self.window?.windowNumber {
                /// **Button from a diff window**
                // Update the tabs in the `appProperties`
                let otherAppProperty = button.appProperties!
                
                // Other window
                appProperties.currentProfile.tabs.append(otherAppProperty.currentProfile.tabs[button.tag])
                otherAppProperty.tabManager.tabDraggedToOtherWindow(button.tag)
                
                // Check if button is from another profile
                if button.profile.name != appProperties.currentProfile.name {
                    print("Button must be from the same profile")
                }
                
                // Our window
                button.appProperties = appProperties
                button.profile = appProperties.currentProfile
                insertTabFromOtherWindow(view: button)
                
                print("Button from another window")
            }
        }
        
        
        if pasteBoardItemIsValid {
            return .copy
        }
        
        return NSDragOperation()
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboardObjects = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self, AXSidebarTabButton.self]), !pasteboardObjects.isEmpty else { return false }
        
        pasteboardObjects.forEach { object in
            if let url = (object as? NSURL) {
                appProperties.tabManager.createNewTab(url: url as URL)
            }
            
            // if let tabButton = object as? AXSidebarTabButton {
            //  print("BRUH")
            // }
        }
        
        return true
    }
    
    // MARK: - Other Functions
    func switchedProfile() {
        tabView.removeFromSuperview()
        
        self.tabView = AXTabView(profile: appProperties.currentProfile)
        tabView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(tabView)
        tabView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        tabView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        tabView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        tabView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        tabView.appProperties = appProperties
        
        if tabView.profile.tabs.isEmpty {
            tabView.createTab()
        }
        
        tabView.update()
    }
}
