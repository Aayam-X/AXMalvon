//
//  AXTabBarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import Cocoa

class AXTabBarView: NSView, AXTabButtonDelegate {
    weak var appProperties: AXSessionProperties!
    var tabGroup: AXTabGroup
    private var hasDrawn = false
    
    // Views
    var tabStackView = NSStackView()
    var scrollView: NSScrollView!
    let clipView = AXFlippedClipView()
    
    init(tabGroup: AXTabGroup, appProperties: AXSessionProperties!) {
        self.tabGroup = tabGroup
        super.init(frame: .zero)
        self.appProperties = appProperties
        self.translatesAutoresizingMaskIntoConstraints = false
        
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        tabStackView.orientation = .vertical
        tabStackView.spacing = 1.08
        tabStackView.detachesHiddenViews = false
        
        // Create scrollView
        scrollView = NSScrollView()
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
    }
    
    override func viewWillDraw() {
        tabStackView.widthAnchor.constraint(equalTo: superview!.widthAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addTab() {
        let button = AXButton()
        button.title = "Untitled"
        addButtonToStackView(button)
    }
    
    func addTab(tab: AXTab) {
        let button = AXTabButton(tabGroup: tabGroup)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.tag = tabGroup.tabs.count - 1
        tabGroup.currentTabIndex = button.tag
        button.tabTitle = tabGroup.currentTab.webView.title ?? "Untitled"
        
        addButtonToStackView(button)
        
        button.startObserving()
        button.delegate = self
        
        // appProperties.tabManager.switchTab(to: index)
    }
    
    func tabButtonDidSelect(_ tabButton: AXTabButton) {
        let previousTag = tabGroup.currentTabIndex
        tabGroup.currentTabIndex = tabButton.tag
        
        tabGroup.tabBarView.updateActiveTab(from: previousTag, to: tabButton.tag)
    }
    
    private func addButtonToStackView(_ button: NSButton) {
        tabStackView.addArrangedSubview(button)
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: tabStackView.leadingAnchor, constant: 5),
            button.trailingAnchor.constraint(equalTo: tabStackView.trailingAnchor, constant: -4),
        ])
    }
    
    func updateActiveTab(from: Int, to: Int) {
        let button = tabStackView.arrangedSubviews[from] as! AXTabButton
        button.isSelected = false
        
        let newButton = tabStackView.arrangedSubviews[to] as! AXTabButton
        newButton.isSelected = true
        
        // I believe it is far more efficient if this code is handled here;
        // As that means calling less functions.
        let tab = tabGroup.tabs[to]
        appProperties.tabManager.updateWebContainerView(tab: tab)
    }
    
    func updateActiveTab(to: Int) {
        let newButton = tabStackView.arrangedSubviews[to] as! AXTabButton
        newButton.isSelected = true
        
        let tab = tabGroup.tabs[to]
        appProperties.tabManager.updateWebContainerView(tab: tab)
    }
    
    func removeTabButton(_ at: Int) {
        tabStackView.arrangedSubviews[at].removeFromSuperview()
        
        for (index, button) in tabStackView.arrangedSubviews.enumerated().dropFirst(at) {
            if let button = button as? AXTabButton {
                button.tag = index
            }
        }
    }
    
    func tabButtonWillClose(_ tabButton: AXTabButton) {
        for (index, button) in tabStackView.arrangedSubviews.enumerated().dropFirst(tabButton.tag) {
            if let button = button as? AXTabButton {
                button.tag = index
            }
        }
    }
    
}

final class AXFlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}
