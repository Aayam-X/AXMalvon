//
//  AXPreferenceButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-27.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import Cocoa

class AXPreferenceButton: NSButton {
    let titleView = NSTextField(frame: .zero)
    
    let imageView = NSImageView()
    
    var isSelected: Bool = false {
        didSet {
            self.layer?.backgroundColor = isSelected ? NSColor.controlAccentColor.cgColor : .clear
        }
    }
    
    init(title: String, icon: String, tag: Int) {
        super.init(frame: .zero)
        configure()
        
        // Setup self
        imageView.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        titleView.stringValue = title
        self.tag = tag
        
        self.widthAnchor.constraint(equalToConstant: 190).isActive = true
        self.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }
    
    private func configure() {
        // Style Self
        self.wantsLayer = true
        self.isBordered = false
        self.layer?.cornerRadius = 5
        self.bezelStyle = .texturedSquare
        self.title = ""
        self.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup image view
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(imageView)
        imageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        // Setup titleView
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.isEditable = false
        titleView.alignment = .left
        titleView.isBordered = false
        titleView.usesSingleLineMode = true
        titleView.drawsBackground = false
        addSubview(titleView)
        titleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        titleView.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 5.0).isActive = true
        titleView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    init() {
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        if self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds) {
            sendAction(action, to: target)
        }
    }
}
