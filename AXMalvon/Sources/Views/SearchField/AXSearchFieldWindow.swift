//
//  AXSearchFieldWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-25.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
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
        
        backgroundColor = .textBackgroundColor // NSWindow stuff
    }
    
    // override func close() {
    //  super.close()
    // }
}
