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
    
    weak var toggleSidebarButtonLeftConstaint: NSLayoutConstraint?
    
    override func viewWillDraw() {
        // Constraints for toggleSidebarButton
        addSubview(toggleSidebarButton)
        toggleSidebarButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        toggleSidebarButtonLeftConstaint = toggleSidebarButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 76)
        toggleSidebarButtonLeftConstaint?.isActive = true
        toggleSidebarButton.widthAnchor.constraint(equalToConstant: 23).isActive = true
        toggleSidebarButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
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
        stackView.leftAnchor.constraint(equalTo: clipView.leftAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: clipView.topAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: clipView.rightAnchor).isActive = true
    }
    
    func enteredFullScreen() {
        toggleSidebarButtonLeftConstaint?.constant = 5
    }
    
    func exitedFullScreen() {
        toggleSidebarButtonLeftConstaint?.constant = 76
    }
    
    @objc func toggleSidebar() {
        appProperties!.sidebarToggled.toggle()
        
        if appProperties!.sidebarToggled {
            // TODO: THINK PROPERLY | toggleSidebarButtonLeftConstaint?.constant = appProperties!.isFullScreen ? 5 : 76
            appProperties?.splitView.insertArrangedSubview(self, at: 0)
            (self.window as! AXWindow).hideTrafficLights(false)
        } else {
            (self.window as! AXWindow).hideTrafficLights(true)
            self.removeFromSuperview()
            
        }
    }
    
    override var tag: Int {
        return 0x01
    }
    
    override func viewDidHide() {
        (self.window as! AXWindow).hideTrafficLights(true)
    }
    
    override func viewDidUnhide() {
        (self.window as! AXWindow).hideTrafficLights(false)
    }
    
    override public func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    
    @objc func tabClick(_ sender: NSButton) {
        appProperties.currentTab = sender.tag
        appProperties.webContainerView.update()
    }
    
    // Add a new item into the stackview
    func didCreateTab(_ t: AXTabItem) {
        let button = AXHoverButton()
        button.tag = t.position
        button.target = self
        button.action = #selector(tabClick)
        button.title = t.title ?? "Untitled"
        stackView.addArrangedSubview(button)
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    }
    
    func titleChanged(_ p: Int) {
        let button = stackView.arrangedSubviews[p] as! AXHoverButton
        button.title = appProperties.tabs[p].title ?? "Untitled"
    }
}
