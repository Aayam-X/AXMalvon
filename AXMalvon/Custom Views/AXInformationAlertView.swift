//
//  AXInformationAlertView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-25.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit

class AXInformationAlertView: NSView {
    fileprivate var hasDrawn: Bool = false
    
    let titleView = NSTextField(frame: .zero)
    
    var message: String = "" {
        didSet {
            titleView.stringValue = message
        }
    }
    
    override func viewWillDraw() {
        if !hasDrawn {
            wantsLayer = true
            self.layer?.cornerRadius = 15.0
            self.layer?.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            self.layer?.backgroundColor = .black
            
            titleView.translatesAutoresizingMaskIntoConstraints = false
            titleView.isEditable = false
            titleView.alignment = .center
            titleView.isBordered = false
            titleView.usesSingleLineMode = true
            titleView.drawsBackground = false
            titleView.lineBreakMode = .byTruncatingTail
            addSubview(titleView)
            titleView.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
            titleView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
            titleView.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            titleView.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            
            hasDrawn = true
        }
    }
}
