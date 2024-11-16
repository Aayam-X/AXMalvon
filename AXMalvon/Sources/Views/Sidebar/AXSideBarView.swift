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
    
    lazy var gestureView = AXNavigationGestureView(appProperties: appProperties)
    lazy var tabBarView: AXTabBarView! = appProperties.tabManager.currentProfile.currentTabGroup.tabBarView

    
    override var tag: Int {
        return 0x01
    }
    
    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        
        self.layer?.backgroundColor = appProperties.tabManager.currentTabGroup.color.cgColor
        
        gestureView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gestureView)
        gestureView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        gestureView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        gestureView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        gestureView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        addSubview(tabBarView)
        NSLayoutConstraint.activate([
            tabBarView.topAnchor.constraint(equalTo: gestureView.bottomAnchor, constant: 5),
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
    
    func updateTabBarView(tabBar: AXTabBarView) {
        tabBarView.removeFromSuperview()
        
        self.tabBarView = tabBar
        
        addSubview(tabBarView)
        NSLayoutConstraint.activate([
            tabBarView.topAnchor.constraint(equalTo: gestureView.bottomAnchor, constant: 5),
            tabBarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabBarView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
