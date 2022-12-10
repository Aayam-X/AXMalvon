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
    var appProperties: AXAppProperties!
    
    override func viewWillDraw() {
        // Create NSVisualEffectView
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .followsWindowActiveState
        
        visualEffectView.frame = bounds
        addSubview(visualEffectView)
        visualEffectView.autoresizingMask = [.height, .width]
        
        // To not have it collapsed at the start
        appProperties.sidebarView.frame.size.width = appProperties.sidebarWidth
        
        // Show/hide the sidebar
        if appProperties.sidebarToggled {
            appProperties.splitView.addArrangedSubview(appProperties.sidebarView)
        }
        
        appProperties.webContainerView.frame = bounds.insetBy(dx: 14, dy: 14)
        appProperties.webContainerView.autoresizingMask = [.height, .width]
        appProperties.splitView.addArrangedSubview(appProperties.webContainerView)
        
        appProperties.splitView.frame = bounds
        addSubview(appProperties.splitView)
        appProperties.splitView.autoresizingMask = [.height, .width]
        
        appProperties.tabManager.createNewTab()
    }
}
