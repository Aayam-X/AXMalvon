//
//  AXSearchFieldPopoverView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-12.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXSearchFieldPopoverView: NSView {
    override func viewWillDraw() {
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        layer?.cornerRadius = 50.0
        layer?.borderColor = NSColor.systemGray.cgColor
        layer?.borderWidth = 1.5
    }
}
