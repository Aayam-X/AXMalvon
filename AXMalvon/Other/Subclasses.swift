//
//  Subclasses.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-02.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit

final class AXFlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}

final class AXFlippedClipViewCenteredX: NSClipView {
    override var isFlipped: Bool {
        return true
    }
    
    // Center the views
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        if let containerView = self.documentView {
            rect.origin.x = (containerView.frame.width - rect.width) / 2
        }
        
        return rect
    }
}

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

final class AXScrollView: NSScrollView {
    var horizontalScrollHandler: (() -> Void)
    
    init(horizontalScrollHandler: @escaping () -> Void) {
        self.horizontalScrollHandler = horizontalScrollHandler
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        let x = event.scrollingDeltaX
        let y = event.scrollingDeltaY
        
        if x == 0 && y == 0 {
            horizontalScrollHandler()
            return
        }
        
        if y == 0 {
            if x > 0 {
                AXMalvon_SidebarView_scrollDirection = .left
            }
            if x < 0 {
                AXMalvon_SidebarView_scrollDirection = .right
            }
        } else {
            AXMalvon_SidebarView_scrollDirection = nil
        }
    }
}
