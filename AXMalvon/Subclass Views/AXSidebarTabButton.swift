//
//  AXSidebarTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-11.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXSidebarTabButton: NSButton {
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    
    var isSelected: Bool = false {
        didSet {
            self.layer?.backgroundColor = isSelected ? selectedColor.cgColor : .clear
        }
    }
    
    var isMouseDown = false
    
    var trackingArea : NSTrackingArea!
    
    init() {
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        self.setTrackingArea(WithDrag: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTrackingArea(WithDrag drag: Bool = false) {
        var options : NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited]
        if drag {
            options.insert(.enabledDuringMouseDrag)
        }
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.isMouseDown = false
        self.removeTrackingArea(self.trackingArea)
        self.setTrackingArea(WithDrag: false)
        layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
    }
    
    override func mouseDown(with event: NSEvent) {
        self.removeTrackingArea(self.trackingArea)
        if self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds) {
            sendAction(action, to: target)
        }
        self.setTrackingArea(WithDrag: true)
        self.isMouseDown = true
        self.layer?.backgroundColor = selectedColor.cgColor
    }
    
    override func mouseEntered(with event: NSEvent) {
        if !isSelected {
            self.layer?.backgroundColor = self.isMouseDown ? selectedColor.cgColor : hoverColor.cgColor
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        self.layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
    }
}
