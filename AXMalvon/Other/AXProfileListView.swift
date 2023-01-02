//
//  AXProfileListView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-01.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import Cocoa

final class AXFlippedClipViewCentered: NSClipView {
    override var isFlipped: Bool {
        return true
    }
    
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        
        if let containerView = self.documentView {
            rect.origin.x = (containerView.frame.width - rect.width) / 2
            rect.origin.y = (containerView.frame.height - rect.height) / 2
        }
        
        return rect
    }
}

class AXProfileListView: NSView {
    weak var appProperties: AXAppProperties!
    
    let scrollView = NSScrollView()
    let clipView = AXFlippedClipViewCentered()
    let stackView = NSStackView()
    
    private var hasDrawn: Bool = false
    
    override func viewWillDraw() {
        if !hasDrawn {
            
            // Add scrollView
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.drawsBackground = false
            addSubview(scrollView)
            scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            // Add clipView
            clipView.translatesAutoresizingMaskIntoConstraints = false
            clipView.drawsBackground = false
            scrollView.contentView = clipView
            clipView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
            clipView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
            clipView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            clipView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
            
            // Add stackView
            scrollView.documentView = stackView
            stackView.translatesAutoresizingMaskIntoConstraints = false
            addProfileButtons()
            
            hasDrawn = true
        }
    }
    
    func addProfileButtons() {
        for (index, profile) in AX_profiles.enumerated() {
            let item = AXHoverButton()
            item.translatesAutoresizingMaskIntoConstraints = false
            item.heightAnchor.constraint(equalToConstant: 30).isActive = true
            item.widthAnchor.constraint(equalToConstant: 35).isActive = true
            item.image = NSImage(systemSymbolName: "star", accessibilityDescription: nil)
            item.toolTip = profile.name
            item.target = self
            item.tag = index
            stackView.addArrangedSubview(item)
            item.action = #selector(buttonClickAction(_:))
        }
    }
    
    @objc func buttonClickAction(_ sender: AXHoverButton) {
        appProperties.profileManager.switchProfiles(to: sender.tag)
        appProperties.tabManager.switchedProfile()
    }
}
