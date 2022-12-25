//
//  AXSideBarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-04.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

fileprivate final class FlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}

class AXSideBarView: NSView {
    // MARK: - Variables
    unowned var appProperties: AXAppProperties!
    
    let scrollView = NSScrollView()
    
    fileprivate let clipView = FlippedClipView()
    
    var stackView = NSStackView()
    
    weak var toggleSidebarButtonLeftConstaint: NSLayoutConstraint?
    
    var trackingArea: NSTrackingArea!
    
    let supportedDraggingTypes: [NSPasteboard.PasteboardType] = [.URL, .init("com.aayamx.malvon.tabButton")]
    
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
    
    fileprivate var hasDrawn = false
    
    override var tag: Int {
        return 0x01
    }
    
    // MARK: Functions
    
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
            
            // Setup the scrollview
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.automaticallyAdjustsContentInsets = false
            scrollView.contentInsets = .init(top: 0, left: 9, bottom: 0, right: 0)
            addSubview(scrollView)
            scrollView.drawsBackground = false
            scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 35).isActive = true
            
            // Setup clipview
            clipView.translatesAutoresizingMaskIntoConstraints = false
            clipView.drawsBackground = false
            scrollView.contentView = clipView
            clipView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
            clipView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
            clipView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            clipView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
            
            // Setup stackview
            stackView.orientation = .vertical
            stackView.spacing = 1.08
            stackView.detachesHiddenViews = false
            stackView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.documentView = stackView
            stackView.widthAnchor.constraint(equalTo: clipView.widthAnchor, constant: -15).isActive = true
            
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
        (stackView.arrangedSubviews[appProperties.currentTab] as! AXSidebarTabButton).isSelected = false
        
        appProperties.currentTab = sender.tag
        
        appProperties.webContainerView.update()
        (sender as! AXSidebarTabButton).isSelected = true
        
        appProperties.window.title = appProperties.tabs[sender.tag].title ?? "Untitled"
    }
    
    @objc func backButtonAction() {
        let webView = appProperties.tabs[appProperties.currentTab].view
        webView.goBack()
    }
    
    @objc func forwardButtonAction() {
        let webView = appProperties.tabs[appProperties.currentTab].view
        webView.goForward()
    }
    
    @objc func reloadButtonAction() {
        appProperties.tabs[appProperties.currentTab].view.reload()
    }
    
    func checkNavigationButtons() {
        let webView = appProperties.tabs[appProperties.currentTab].view
        
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }
    
    // MARK: - Functions
    override func viewDidEndLiveResize() {
        appProperties.sidebarWidth = self.frame.size.width
        removeTrackingArea(trackingArea)
        trackingArea = NSTrackingArea(rect: .init(x: bounds.origin.x - 100, y: bounds.origin.y, width: bounds.size.width + 100, height: bounds.size.height), options: [.activeAlways, .mouseEnteredAndExited], owner: self)
        addTrackingArea(trackingArea)
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        if oldSize.height == frame.height {
            if !appProperties.isFullScreen {
                if frame.width >= 210 {
                    self.layer?.backgroundColor = .clear
                } else {
                    self.layer?.backgroundColor = NSColor.red.cgColor
                }
            }
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
    
    override public func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    
    func enteredFullScreen() {
        toggleSidebarButtonLeftConstaint?.constant = 5
    }
    
    func exitedFullScreen() {
        toggleSidebarButtonLeftConstaint?.constant = 76
    }
    
    func updateAll() {
        stackView.subviews.removeAll()
        
        for (index, tab) in appProperties.tabs.enumerated() {
            _update_didCreateTab(tab, index)
        }
        
        (stackView.arrangedSubviews[appProperties.currentTab] as! AXSidebarTabButton).isSelected = true
    }
    
    // Add a new item into the stackview
    func didCreateTab(_ oldPos: Int) {
        (stackView.arrangedSubviews[safe: oldPos] as? AXSidebarTabButton)?.isSelected = false
        let t = appProperties.tabs[appProperties.currentTab]
        
        let button = AXSidebarTabButton(appProperties)
        button.tag = appProperties.currentTab
        button.startObserving()
        
        button.alignment = .natural
        button.target = self
        button.action = #selector(tabClick)
        button.tabTitle = t.title ?? "Untitled"
        stackView.addArrangedSubview(button)
        button.isSelected = true
        
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    }
    
    func swapAt(_ first: Int, _ second: Int) {
        let firstSubview = stackView.arrangedSubviews[first] as! AXSidebarTabButton
        let secondSubview = stackView.arrangedSubviews[second] as! AXSidebarTabButton
        
        firstSubview.tag = second
        secondSubview.tag = first
        
        stackView.removeArrangedSubview(firstSubview)
        stackView.insertArrangedSubview(firstSubview, at: second)
        stackView.insertArrangedSubview(secondSubview, at: first)
    }
    
    func removedTab(_ at: Int) {
        let tab = stackView.arrangedSubviews[at] as! AXSidebarTabButton
        tab.stopObserving()
        tab.removeFromSuperview()
        
        // Fix tab.position
        for index in at..<stackView.arrangedSubviews.count {
            let tab = stackView.arrangedSubviews[index] as! AXSidebarTabButton
            tab.tag -= 1
        }
        
        (stackView.arrangedSubviews[appProperties.currentTab] as! AXSidebarTabButton).isSelected = true
    }
    
    func didDownload(_ d: AXDownloadItem) {
        let button = AXSidebarDownloadButton(appProperties)
        button.downloadItem = d
        button.startObserving()
        
        stackView.addArrangedSubview(button)
        
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    }
    
    
    func moveSelectionTo(to: Int) {
        (stackView.arrangedSubviews[appProperties.currentTab] as! AXSidebarTabButton).isSelected = false
        
        appProperties.currentTab = to
        
        appProperties.webContainerView.update()
        (stackView.arrangedSubviews[appProperties.currentTab] as! AXSidebarTabButton).isSelected = true
        
        appProperties.window.title = appProperties.tabs[to].title ?? "Untitled"
    }
    
    func _update_didCreateTab(_ t: AXTabItem, _ i: Int) {
        let button = AXSidebarTabButton(appProperties)
        button.tag = i
        button.startObserving()
        
        button.alignment = .natural
        button.target = self
        button.action = #selector(tabClick)
        button.tabTitle = t.title ?? "Untitled"
        stackView.addArrangedSubview(button)
        
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    }
    
    // MARK: - Drag and Drop
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteBoardItemIsValid = sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self, AXSidebarTabButton.self])
        self.window?.orderFront(nil)
        
        if let button = sender.draggingSource as? AXSidebarTabButton {
            if button.window?.windowNumber != self.window?.windowNumber {
                /// **Button from a diff window**
                // Update the tabs in the `appProperties`
                let otherAppProperty = button.appProperties!
                
                
                print(button.tag, otherAppProperty.tabs.count)
                appProperties.tabs.append(otherAppProperty.tabs[button.tag])
                otherAppProperty.tabs.remove(at: button.tag)
                
                // Last tab
                if otherAppProperty.tabs.isEmpty {
                    button.window?.close()
                } else {
                    // Update the current tab in that window
                    // TODO: Fix problem here
                    if otherAppProperty.currentTab == otherAppProperty.tabs.count - 1 {
                        otherAppProperty.currentTab -= 1
                    }
                    
                    // Fix tab.position
                    for index in button.tag..<otherAppProperty.sidebarView.stackView.arrangedSubviews.count {
                        let tab = otherAppProperty.sidebarView.stackView.arrangedSubviews[index] as! AXSidebarTabButton
                        tab.tag -= 1
                    }
                    
                    (otherAppProperty.sidebarView.stackView.arrangedSubviews[otherAppProperty.currentTab] as! AXSidebarTabButton).isSelected = true
                    otherAppProperty.webContainerView.update()
                }
                
                // Remove the button from the origin window
                // And update the appProperties
                button.removeFromSuperview()
                button.appProperties = self.appProperties
                button.tag = stackView.arrangedSubviews.count
                button.startObserving()
                
                button.target = self
                button.action = #selector(tabClick)
                button.tabTitle = appProperties.tabs[button.tag].title ?? "Untitled"
                stackView.addArrangedSubview(button)
                
                // Change selected button
                (stackView.arrangedSubviews[safe: appProperties.currentTab] as? AXSidebarTabButton)?.isSelected = false
                appProperties.currentTab = button.tag
                button.isSelected = true
                appProperties.webContainerView.update()
                
                button.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
                
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
            if let url = object as? NSURL {
                appProperties.tabManager.createNewTab(url: url as URL)
            }
            
            // if let tabButton = object as? AXSidebarTabButton {
            //  print("BRUH")
            // }
        }
        
        return true
    }
}
