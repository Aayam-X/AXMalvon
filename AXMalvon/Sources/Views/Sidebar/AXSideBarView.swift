//
//  AXSidebarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import Cocoa

class AXSidebarView: NSView {
    weak var appProperties: AXSessionProperties!
    private var hasDrawn: Bool = false
    
    lazy var backButton: AXButton = {
        let button = AXButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "arrow.backward", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.target = self
        button.action = #selector(backButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var forwardButton: AXButton = {
        let button = AXButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "arrow.forward", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.target = self
        button.action = #selector(forwardButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var reloadButton: AXButton = {
        let button = AXButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.target = self
        button.action = #selector(reloadButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var tabGroupOrProfileButton: AXButton = {
        let button = AXButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.title = appProperties.tabManager.currentProfile.name + " — " + appProperties.tabManager.currentProfile.currentTabGroup.name
        button.lineBreakMode = .byTruncatingTail
        return button
    }()
    
    override var tag: Int {
        return 0x01
    }
    
    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        
        // Constraints for testButton
        addSubview(reloadButton)
        reloadButton.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        reloadButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true
        reloadButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        reloadButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        // Constraints for forwardButton
        addSubview(forwardButton)
        forwardButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        forwardButton.rightAnchor.constraint(equalTo: reloadButton.leftAnchor, constant: -10).isActive = true
        forwardButton.widthAnchor.constraint(equalToConstant: 23).isActive = true
        forwardButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        // Constraints for backButton
        addSubview(backButton)
        backButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        backButton.rightAnchor.constraint(equalTo: forwardButton.leftAnchor, constant: -10).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 23).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        addSubview(tabGroupOrProfileButton)
        tabGroupOrProfileButton.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 3).isActive = true
        tabGroupOrProfileButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
        tabGroupOrProfileButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -10).isActive = true

        let tabBarView = appProperties.tabManager.currentProfile.currentTabGroup.tabBarView
        addSubview(tabBarView)
                NSLayoutConstraint.activate([
                    tabBarView.topAnchor.constraint(equalTo: tabGroupOrProfileButton.bottomAnchor, constant: 5),
                    tabBarView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    tabBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    tabBarView.bottomAnchor.constraint(equalTo: bottomAnchor),
                ])
        
    }
    
    init(appProperties: AXSessionProperties!) {
        self.appProperties = appProperties
        super.init(frame: .zero) // Maybe change only the width
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func backButtonAction() {
        appProperties.containerView.currentWebView?.goBack()
    }
    
    @objc func forwardButtonAction() {
        appProperties.containerView.currentWebView?.goForward()
    }
    
    @objc func reloadButtonAction() {
        appProperties.containerView.currentWebView?.reload()
    }
    
    
    @objc private func tabGroupSelected(_ sender: NSMenuItem) {
        // Handle tab group selection
        print("Selected tab group: \(sender.title)")
    }
}
