//
//  SwiftConstraintHelper.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-04.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

extension NSView {
    enum ConstraintTarget {
        case constant(CGFloat)
        case view(NSView, constant: CGFloat = 0)
    }
    
    enum ConstraintLayoutAxis {
        case top
        case topBottom
        
        case bottom
        case bottomTop
        
        case left
        case leftRight
        
        case right
        case rightLeft
        
        case width
        case height
        
        case centerX
        case centerY
        
        case allEdges
        case horizontalEdges
        case verticalEdges
    }
    
    func activateConstraints(_ constraints: [ConstraintLayoutAxis: ConstraintTarget]) {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        for (attribute, target) in constraints {
            let constraint: NSLayoutConstraint
            
            switch (attribute, target) {
                // Constraints to another view with optional constant
            case (.top, .view(let view, let constant)):
                constraint = self.topAnchor.constraint(equalTo: view.topAnchor, constant: constant)
            case (.topBottom, .view(let view, let constant)):
                constraint = self.topAnchor.constraint(equalTo: view.bottomAnchor, constant: constant)
            case (.bottom, .view(let view, let constant)):
                constraint = self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: constant)
            case (.bottomTop, .view(let view, let constant)):
                constraint = self.bottomAnchor.constraint(equalTo: view.topAnchor, constant: constant)
            case (.left, .view(let view, let constant)):
                constraint = self.leftAnchor.constraint(equalTo: view.leftAnchor, constant: constant)
            case (.leftRight, .view(let view, let constant)):
                constraint = self.leftAnchor.constraint(equalTo: view.rightAnchor, constant: constant)
            case (.right, .view(let view, let constant)):
                constraint = self.rightAnchor.constraint(equalTo: view.rightAnchor, constant: constant)
            case (.rightLeft, .view(let view, let constant)):
                constraint = self.rightAnchor.constraint(equalTo: view.leftAnchor, constant: constant)
            case (.width, .view(let view, let constant)):
                constraint = self.widthAnchor.constraint(equalTo: view.widthAnchor, constant: constant)
            case (.height, .view(let view, let constant)):
                constraint = self.heightAnchor.constraint(equalTo: view.heightAnchor, constant: constant)
            case (.centerX, .view(let view, let constant)):
                constraint = self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: constant)
            case (.centerY, .view(let view, let constant)):
                constraint = self.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant)
                
                // Constant constraints (to oneself)
            case (.width, .constant(let constant)):
                constraint = self.widthAnchor.constraint(equalToConstant: constant)
            case (.height, .constant(let constant)):
                constraint = self.heightAnchor.constraint(equalToConstant: constant)
                
            case (.allEdges, .view(let view, let constant)):
                constraint = self.leftAnchor.constraint(equalTo: view.leftAnchor, constant: constant)
                self.rightAnchor.constraint(equalTo: view.rightAnchor, constant: constant).isActive = true
                self.topAnchor.constraint(equalTo: view.topAnchor, constant: constant).isActive = true
                self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: constant).isActive = true
                
            case (.horizontalEdges, .view(let view, let constant)):
                constraint = self.leftAnchor.constraint(equalTo: view.leftAnchor, constant: constant)
                // NEGATIVE CONSTRAINT FOR RIGHT
                self.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -constant).isActive = true
                
            case (.verticalEdges, .view(let view, let constant)):
                constraint = self.topAnchor.constraint(equalTo: view.topAnchor, constant: constant)
                self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: constant).isActive = true
                
                
            default:
                fatalError("Unsupported constraint combination")
            }
            
            constraint.isActive = true
        }
    }
}
