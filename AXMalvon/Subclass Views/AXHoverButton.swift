//
//  AXHoverButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXHoverButton: NSButton {
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    
    var isMouseDown = false
    
    var trackingArea : NSTrackingArea!
    
    init(isSelected: Bool = false) {
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .texturedRounded
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
        if self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds) {
            sendAction(action, to: target)
        }
        self.isMouseDown = false
        self.removeTrackingArea(self.trackingArea)
        self.setTrackingArea(WithDrag: false)
        layer?.backgroundColor = .none
    }
    
    override func mouseDown(with event: NSEvent) {
        self.removeTrackingArea(self.trackingArea)
        self.setTrackingArea(WithDrag: true)
        self.isMouseDown = true
        self.layer?.backgroundColor = hoverColor.cgColor
    }
    
    override func mouseEntered(with event: NSEvent) {
        self.layer?.backgroundColor = self.isMouseDown ? selectedColor.cgColor : hoverColor.cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        self.layer?.backgroundColor = .none
    }
}
