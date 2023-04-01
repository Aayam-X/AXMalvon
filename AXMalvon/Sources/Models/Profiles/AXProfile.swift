//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-01.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

final class AXPrivateBrowserProfile: AXBrowserProfile {
    init() {
        super.init(name: "PrivateWindow-\(UUID().uuidString)", -1)
    }
    
    override func retriveTabs() {}
    override func saveProperties() {}
}

class AXBrowserProfile {
    var name: String // User default string
    var index: Int
    var tabs: [AXTabItem] = []
    var previouslyClosedTabs: [URL] = []
    
    lazy var tabStackView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 1.08
        stackView.detachesHiddenViews = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    var currentTab = 0 {
        willSet {
            previousTab = currentTab
        }
    }
    
    var previousTab = -1
    
    init(name: String) {
        self.name = name
        index = UserDefaults.standard.integer(forKey: "\(name)-Index")
    }
    
    init(name: String, _ index: Int) {
        self.name = name
        self.index = index
        
        UserDefaults.standard.set(index, forKey: "\(name)-Index")
        saveProperties()
    }
    
    func retriveTabs() {
        // Retrive the tabs
        if let data = UserDefaults.standard.data(forKey: "\(name)-AXTabItem") {
            do {
                let decoder = JSONDecoder()
                decoder.userInfo[AXTabItem.webViewConfigurationUserInfoKey] = AXGlobalProperties.shared.profiles[index].configuration
                self.tabs = try decoder.decode([AXTabItem].self, from: data)
                
                // Retrive the currentTab & Index
                currentTab = UserDefaults.standard.integer(forKey: "\(name)-CurrentTab")
            } catch {
                print("Unable to Decode Tabs (\(error))")
            }
        }
    }
    
    func saveProperties() {
        // Save current tab & Index
        UserDefaults.standard.set(currentTab, forKey: "\(name)-CurrentTab")
        UserDefaults.standard.set(index, forKey: "\(name)-Index")
        
        // Save tabs
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(tabs)
            UserDefaults.standard.set(data, forKey: "\(name)-AXTabItem")
        } catch {
            print("Unable to Encode Tabs (\(error.localizedDescription))")
        }
    }
}
