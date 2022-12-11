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
    var appProperties: AXAppProperties!
    
    let scrollView = NSScrollView()
    
    fileprivate let clipView = FlippedClipView()
    
    var stackView = NSStackView()
    
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
        button.keyEquivalentModifierMask = .command
        button.keyEquivalent = "r"
        button.target = self
        button.action = #selector(reloadButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    weak var toggleSidebarButtonLeftConstaint: NSLayoutConstraint?
    
    var hasDrawn = false
    
    override func viewWillDraw() {
        if !hasDrawn {
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
            stackView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.documentView = stackView
            stackView.topAnchor.constraint(equalTo: clipView.topAnchor).isActive = true
            stackView.widthAnchor.constraint(equalTo: clipView.widthAnchor).isActive = true
            
            hasDrawn = true
        }
    }
    
    func enteredFullScreen() {
        toggleSidebarButtonLeftConstaint?.constant = 5
    }
    
    func exitedFullScreen() {
        toggleSidebarButtonLeftConstaint?.constant = 76
    }
    
    @objc func toggleSidebar() {
        appProperties.sidebarToggled.toggle()
        
        if appProperties.sidebarToggled {
            appProperties.window.hideTrafficLights(false)
            appProperties.splitView.insertArrangedSubview(self, at: 0)
            if !appProperties.isFullScreen {
                appProperties.webContainerView.customInsetWebviewFrame()
            }
        } else {
            appProperties.window.hideTrafficLights(true)
            if !appProperties.isFullScreen {
                appProperties.webContainerView.insetWebviewFrame()
            }
            self.removeFromSuperview()
        }
    }
    
    @objc func backButtonAction() {
        let webView = appProperties.tabs[appProperties.currentTab].view
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc func forwardButtonAction() {
        let webView = appProperties.tabs[appProperties.currentTab].view
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @objc func reloadButtonAction() {
        appProperties.tabs[appProperties.currentTab].view.reload()
    }
    
    override func viewDidEndLiveResize() {
        appProperties.sidebarWidth = self.frame.size.width
        self.layer?.backgroundColor = .clear
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
    
    override var tag: Int {
        return 0x01
    }
    
    override public func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    
    @objc func tabClick(_ sender: NSButton) {
        let pos = appProperties.tabs[appProperties.currentTab].position
        (stackView.arrangedSubviews[pos] as! AXSidebarTabButton).isSelected = false
        
        appProperties.currentTab = sender.tag
        
        appProperties.webContainerView.update(sender.tag)
        (stackView.arrangedSubviews[sender.tag] as! AXSidebarTabButton).isSelected = true
    }
    
    // Add a new item into the stackview
    func didCreateTab(_ oldPos: Int) {
        (stackView.arrangedSubviews[safe: oldPos] as? AXSidebarTabButton)?.isSelected = false
        let t = appProperties.tabs[appProperties.currentTab]
        
        let button = AXSidebarTabButton()
        
        button.tag = t.position
        button.alignment = .natural
        button.target = self
        button.action = #selector(tabClick)
        button.title = t.title ?? "Untitled"
        stackView.addArrangedSubview(button)
        button.isSelected = true
        
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    }
    
    func titleChanged(_ p: Int) {
        let button = stackView.arrangedSubviews[p] as! AXSidebarTabButton
        button.title = appProperties.tabs[p].title ?? "Untitled"
    }
}

extension Array {
    subscript (safe index: Index) -> Element? {
        0 <= index && index < count ? self[index] : nil
    }
}
