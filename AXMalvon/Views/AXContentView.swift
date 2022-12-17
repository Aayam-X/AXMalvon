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
            
            appProperties.progressBar.translatesAutoresizingMaskIntoConstraints = false
            appProperties.progressBar.style = .bar
            appProperties.progressBar.controlSize = .small
            appProperties.progressBar.isIndeterminate = false
            appProperties.progressBar.minValue = 0
            appProperties.progressBar.maxValue = 100
            self.addSubview(appProperties.progressBar)
            appProperties.progressBar.topAnchor.constraint(equalTo: topAnchor, constant: -5).isActive = true
            appProperties.progressBar.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            appProperties.progressBar.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            appProperties.progressBar.doubleValue = 0.0
            
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
}
