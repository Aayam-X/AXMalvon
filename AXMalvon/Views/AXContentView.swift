//
//  AXContentView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXContentView: NSView {
    unowned var appProperties: AXAppProperties!
    
    var hasDrawn = false
    
    override func viewWillDraw() {
        if !hasDrawn {
            if appProperties.isPrivate {
                self.layer?.backgroundColor = .black
            } else {
                // Create NSVisualEffectView
                let visualEffectView = NSVisualEffectView()
                visualEffectView.material = .popover
                visualEffectView.blendingMode = .behindWindow
                visualEffectView.state = .followsWindowActiveState
                
                visualEffectView.frame = bounds
                addSubview(visualEffectView)
                visualEffectView.autoresizingMask = [.height, .width]
            }
            
            // Setup progress bar
            appProperties.progressBar.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(appProperties.progressBar)
            appProperties.progressBar.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
            appProperties.progressBar.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            appProperties.progressBar.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            appProperties.progressBar.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            // To not have it collapsed at the start
            appProperties.sidebarView.frame.size.width = appProperties.sidebarWidth
            
            // Show/hide the sidebar
            if appProperties.sidebarToggled {
                appProperties.splitView.addArrangedSubview(appProperties.sidebarView)
            }
            
            appProperties.splitView.addArrangedSubview(appProperties.webContainerView)
            
            appProperties.splitView.frame = bounds
            addSubview(appProperties.splitView)
            appProperties.splitView.autoresizingMask = [.height, .width]
            
            if appProperties.tabs.isEmpty {
                // Create a tab
                appProperties.tabManager.createNewTab()
            } else {
                appProperties.tabManager.updateAll()
            }
        }
    }
    
    // Show a searchbar popover
    func displaySearchBarPopover() {
        appProperties.popOver.frame = bounds.insetBy(dx: 250, dy: 250)
        addSubview(appProperties.popOver)
        appProperties.searchFieldShown = true
        appProperties.popOver.searchField.becomeFirstResponder()
    }
    
    func showSearchBar() {
        if !appProperties.searchFieldShown {
            appProperties.popOver.frame = bounds.insetBy(dx: 250, dy: 250)
            addSubview(appProperties.popOver)
            appProperties.popOver.searchField.stringValue = appProperties.tabs[appProperties.currentTab].view.url?.absoluteString ?? ""
            appProperties.searchFieldShown = true
            appProperties.popOver.searchField.becomeFirstResponder()
        } else {
            appProperties.popOver.close()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.characters {
            case "1": // There is always going to be one tab, so no checking
                appProperties.tabManager.switch(to: 0)
            case "2" where 2 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 1)
            case "3" where 3 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 2)
            case "4" where 4 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 3)
            case "5" where 5 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 4)
            case "6" where 6 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 5)
            case "7" where 7 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 6)
            case "8" where 8 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 7)
            case "9":
                appProperties.tabManager.switch(to: appProperties.tabs.count - 1)
            default:
                super.keyDown(with: event)
            }
        }
    }
}
