//
//  AXButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import AppKit

class AXButton: NSButton {
    var trackingArea: NSTrackingArea!
        
    init(isSelected: Bool = false) {
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        self.setTrackingArea()
        
        layer?.opacity = 0.5
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
        if self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds) {
            sendAction(action, to: target)
        }
        layer?.opacity = 0.8
    }
    
    override func mouseDown(with event: NSEvent) {
        layer?.opacity = 1.0
    }
    
    override func mouseEntered(with event: NSEvent) {
        if isEnabled {
            layer?.opacity = 0.8
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        layer?.opacity = 0.5
    }
}
