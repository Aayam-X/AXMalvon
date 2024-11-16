//
//  AXTabGroup.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//

import AppKit
import WebKit

class AXTabGroup: Codable {
    var name: String
    var color: NSColor // NSColor cannot be encoded directly
    weak var appProperties: AXSessionProperties?
    
    var isCurrentTabGroup = false
    var tabs: [AXTab] = []
    var currentTabIndex: Int = -1
    
    var currentTab: AXTab! { tabs[safe: currentTabIndex] }
    
    var tabBarView: AXTabBarView!
    
    init(name: String = "Untitled Tab Group", color: NSColor = .systemRed, _ appProperties: AXSessionProperties?) {
        self.name = name
        self.color = color.withAlphaComponent(0.3)
        self.appProperties = appProperties
        
        tabBarView = AXTabBarView(tabGroup: self, appProperties: appProperties)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, color, tabs, currentTabIndex, isCurrentTabGroup
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let colorData = try container.decode(Data.self, forKey: .color)
        color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as! NSColor
        isCurrentTabGroup = try container.decode(Bool.self, forKey: .isCurrentTabGroup)
        
        tabs = try container.decode([AXTab].self, forKey: .tabs)
        
        
        currentTabIndex = try container.decode(Int.self, forKey: .currentTabIndex)
        
        // Fetch `appProperties` from decoder's `userInfo`
        if let appProperties = decoder.userInfo[.appPropertiesKey] as? AXSessionProperties {
            self.appProperties = appProperties
            self.tabBarView = AXTabBarView(tabGroup: self, appProperties: appProperties)
        }
        
        
        updateTabView()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        let colorData = NSKeyedArchiver.archivedData(withRootObject: color)
        try container.encode(colorData, forKey: .color)
        try container.encode(tabs, forKey: .tabs)
        try container.encode(currentTabIndex, forKey: .currentTabIndex)
        try container.encode(isCurrentTabGroup, forKey: .isCurrentTabGroup)
    }
}

// MARK: Tab Functions
extension AXTabGroup {
    func activeTitleChanged(_ newTitle: String) {
        if self.isCurrentTabGroup {
            // AXTabButton already checks if it is the selectedTab, so no need to worry here.
            appProperties?.containerView.websiteTitleLabel.stringValue = newTitle
        }
    }
    
    func updateTabView() {
        for (index, tab) in tabs.enumerated() {
            tabBarView.addTab(tab: tab, index: index)
        }
        
        if let button = tabBarView.tabStackView.arrangedSubviews[safe: currentTabIndex] as? AXTabButton {
            button.isSelected = true
            
            if self.isCurrentTabGroup {
                appProperties?.containerView.updateView(webView: tabs[currentTabIndex].webView)
            }
        }
    }
    
    func addTab(_ tab: AXTab) {
        let previousIndex = currentTabIndex
        
        tabs.append(tab)
        tabBarView.addTab(tab: tab)
        
        if previousIndex == -1 {
            tabBarView.updateActiveTab(to: 0)
        } else {
            tabBarView.updateActiveTab(from: previousIndex, to: tabs.count - 1)
        }
    }
    
    func switchTab(to index: Int) {
        let previousIndex = currentTabIndex
        currentTabIndex = index
        
        tabBarView.updateActiveTab(from: previousIndex, to: index)
    }
    
    func removeTab(at: Int) {
        tabs.remove(at: at)
        currentTabIndex = currentTabIndex > at ? currentTabIndex - 1 : currentTabIndex
        
        tabBarView.removeTabButton(at)
    }
    
    func removeTab() {
        tabs.remove(at: currentTabIndex)
        currentTabIndex -= 1
        tabBarView.removeTabButton(currentTabIndex)
    }
}
