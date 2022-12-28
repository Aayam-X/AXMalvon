//
//  AXSearchFieldSuggestItem.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-24.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXSearchFieldSuggestItem: NSButton {
    let titleView: NSTextField! = NSTextField(frame: .zero)
    
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    
    var isMouseDown = false
    
    var trackingArea: NSTrackingArea!
    
    var isSelected: Bool = false {
        didSet {
            self.layer?.backgroundColor = isSelected ? selectedColor.cgColor : .clear
        }
    }
    
    var titleValue: String = "" {
        didSet {
            titleView.stringValue = titleValue
        }
    }
    
    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 5
        isBordered = false
        bezelStyle = .shadowlessSquare
        title = ""
        
        setTrackingArea()
        
        // Setup titleView
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.isEditable = false
        titleView.alignment = .left
        titleView.isBordered = false
        titleView.usesSingleLineMode = true
        titleView.drawsBackground = false
        addSubview(titleView)
        titleView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        titleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        titleView.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if !isSelected && !titleView.stringValue.isEmpty {
            self.layer?.backgroundColor = self.isMouseDown ? selectedColor.cgColor : hoverColor.cgColor
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds) {
            sendAction(action, to: target)
        }
        self.isMouseDown = true
        
        if !titleView.stringValue.isEmpty {
            self.layer?.backgroundColor = selectedColor.cgColor
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        isMouseDown = false
        layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
    }
    
    override func mouseExited(with event: NSEvent) {
        self.layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
    }
}
