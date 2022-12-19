//
//  AXRectangularProgressIndicator.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-18.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXRectangularProgressIndicator: NSView {
    var progress: CGFloat = 0.0 {
        didSet {
            self.needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if progress != 1.0 {
            NSColor.textColor.withAlphaComponent(CGFloat.random(in: 0.5..<1.0)).setStroke()
            
            // Create a bezier path for the border
            let borderPath = NSBezierPath()
            borderPath.lineWidth = 5
            
            // Top Point
            borderPath.move(to: .init(x: 0, y: bounds.height))
            borderPath.line(to: .init(x: bounds.width * progress, y: self.bounds.height))
            
            // Right Point
            borderPath.move(to: .init(x: bounds.width, y: bounds.height))
            borderPath.line(to: .init(x: bounds.width, y: (bounds.height - (progress) * bounds.height)))
            
            // Bottom Point
            borderPath.move(to: .init(x: bounds.width, y: 0))
            borderPath.line(to: .init(x: (bounds.width - (bounds.width * progress)), y: 2))
            
            // Left Point
            borderPath.move(to: .zero)
            borderPath.line(to: .init(x: 0, y: bounds.height * progress))
            
            // Draw the border
            borderPath.stroke()
        }
    }
    
    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
