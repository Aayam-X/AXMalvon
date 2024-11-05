//
//  AXPreferenceProfilesView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//  Copyright © 2024 Aayam(X). All rights reserved.
//

import Cocoa

class AXPreferenceProfilesView: NSView {
    private var hasDrawn: Bool = false
    
    var titleLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 35, weight: .medium)
        return label
    }()
    
    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        
        self.setFrameSize(.init(width: 500, height: 300))
        
        // Name label
        titleLabel.stringValue = "Profiles"
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 25).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        
    }
}
