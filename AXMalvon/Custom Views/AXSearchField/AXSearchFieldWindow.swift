//
//  AXSearchFieldWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-25.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXSearchFieldWindow: NSPanel {
    init() {
        super.init(
            contentRect: .init(x: 0, y: 0, width: 600, height: 274),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        level = .mainMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
        
        // NSWindow has a hidden NSVisualEffectView that changes the window's tint based on the wallpaper and position
        // We do not want to have two NSVisualEffectViews as it effects the performance
        // Which is why we must set the background color
        backgroundColor = .textBackgroundColor
    }
    
    // override func close() {
    //  super.close()
    // }
}
