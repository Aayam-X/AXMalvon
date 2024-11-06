//
//  AXTabBarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import Cocoa

class AXTabBarView: NSView {
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
        button.target = self
        button.action = #selector(tabClick)
        button.tabTitle = tabGroup.currentTab.webView.title ?? "Untitled"
        
        addButtonToStackView(button)
        
        button.startObserving()
        
        // appProperties.tabManager.switchTab(to: index)
    }
    

    private func addButtonToStackView(_ button: NSButton) {
        tabStackView.addArrangedSubview(button)
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: tabStackView.leadingAnchor, constant: 10),
            button.trailingAnchor.constraint(equalTo: tabStackView.trailingAnchor, constant: -9),
        ])
    }
    
    func updateActiveTab(from: Int, to: Int) {
        let button = tabStackView.arrangedSubviews[from] as! AXTabButton
        button.isSelected = false
        
        let newButton = tabStackView.arrangedSubviews[to] as! AXTabButton
        newButton.isSelected = true
    }
       
       @objc func tabClick() {
           print("Tab Click")
           
       }
}

final class AXFlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}
