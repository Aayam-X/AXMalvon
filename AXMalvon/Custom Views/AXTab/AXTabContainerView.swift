//
//  AXTabContainerView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXWebContainerView: NSView {
    var appProperties: AXAppProperties!
    
    override func viewWillDraw() {
        self.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.2).cgColor
    }
    
    func enteredFullScreen() {
        subviews[0].frame = bounds
        subviews[0].layer?.cornerRadius = 0.0
    }
    
    func exitedFullScreen() {
        subviews[0].frame = bounds.insetBy(dx: 14, dy: 14)
        subviews[0].layer?.cornerRadius = 5.0
    }
    
    func update() {
        // TODO: Would this be more efficient than appProperties.currentTab.webView.removeFromSuper()
        subviews.removeAll()
        
        let webView = appProperties.tabs[appProperties.currentTab].view
        webView.frame = bounds.insetBy(dx: 14, dy: 14)
        addSubview(webView)
        webView.autoresizingMask = [.height, .width]
    }
}
