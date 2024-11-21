//
//  AXTabGroup.swift
//  AXTabSystem
//
//  Created by Ashwin Paudel on 2024-11-14.
//

import AppKit

class AXTabGroup: Codable {
    var name: String
    var tabs: [AXTab] = []
    var selectedIndex: Int = -1

    var tabBarView: AXTabBarView?

    init(name: String) {
        self.name = name
    }

    func initializeTabBarView() {
        guard tabBarView == nil else {
            print("Tab Bar View already exists.")
            return
        }
        tabBarView = .init(tabGroup: self)

        for (index, tab) in tabs.enumerated() {
            tabBarView?.addTabButton(for: tab, index: index)
        }

        guard selectedIndex != -1 else { return }
        tabBarView?.updateTabSelection(from: -1, to: selectedIndex)
    }

    // MARK: - Tab Functions

    func addTab(_ tab: AXTab) {
        tabs.append(tab)
        tabBarView?.addTabButton(for: tab)  // Add button to tab bar view
    }

    func switchTab(to: Int) {
        guard selectedIndex != to else { return }

        let previousIndex = selectedIndex
        self.selectedIndex = to

        switchTab(from: previousIndex, to: to)
    }

    func switchTab(from: Int, to: Int) {
        // Logic for switching tabs
        selectedIndex = to
        tabBarView?.updateTabSelection(from: from, to: to)  // Notify view
    }

    func removeTab(_ at: Int) {
        tabs.remove(at: at)
        tabBarView?.removeTab(at: at)
    }

    func removeCurrentTab() {
        removeTab(selectedIndex)
    }

    // MARK: - Codeable Functions
    enum CodingKeys: String, CodingKey {
        case name, tabs, selectedIndex
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try container.decode(String.self, forKey: .name)
        self.tabs = try container.decode([AXTab].self, forKey: .tabs)
        self.selectedIndex = try container.decode(
            Int.self, forKey: .selectedIndex)

        print("DECODED TAB VIEW WITH \(tabs.count)")
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(tabs, forKey: .tabs)
        try container.encode(selectedIndex, forKey: .selectedIndex)
    }
}

// Define a custom key for userInfo.
extension CodingUserInfoKey {
    static let webConfiguration = CodingUserInfoKey(
        rawValue: "webConfiguration")!
}
