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
        
        let gestureView = AXNavigationGestureView(appProperties: appProperties)
        gestureView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gestureView)
        gestureView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        gestureView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        gestureView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        gestureView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        addSubview(tabGroupOrProfileButton)
        tabGroupOrProfileButton.topAnchor.constraint(equalTo: gestureView.bottomAnchor, constant: 3).isActive = true
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
