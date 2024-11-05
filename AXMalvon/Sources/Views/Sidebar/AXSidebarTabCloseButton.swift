//
//  AXSidebarTabCloseButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-14.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

class AXSidebarTabCloseButton: NSButton {
    var trackingArea: NSTrackingArea!
    
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    var defaultColor: CGColor? = .none
    var mouseDown: Bool = false
    
    init(isSelected: Bool = false) {
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        self.setTrackingArea()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseUp(with event: NSEvent) {
        mouseDown = false
        if self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds) {
            sendAction(action, to: target)
        }
        
        layer?.backgroundColor = defaultColor
    }
    
    override func mouseDown(with event: NSEvent) {
        mouseDown = true
        self.layer?.backgroundColor = hoverColor.cgColor
    }
    
    override func mouseEntered(with event: NSEvent) {
        if isEnabled {
            self.layer?.backgroundColor = hoverColor.cgColor
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        mouseDown = false
    }
    
    override func mouseExited(with event: NSEvent) {
        self.layer?.backgroundColor = defaultColor
    }
}
