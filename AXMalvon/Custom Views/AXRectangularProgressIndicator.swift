//
//  AXRectangularProgressIndicator.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-18.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXRectangularProgressIndicator: NSView, CAAnimationDelegate {
    private var progress: CGFloat = 0.0
    
    let topBorderLayer = CAShapeLayer()
    let topPointPath = NSBezierPath()
    let topAnimation = CABasicAnimation(keyPath: "strokeEnd")
    
    let rightBorderLayer = CAShapeLayer()
    let rightPointPath = NSBezierPath()
    let rightAnimation = CABasicAnimation(keyPath: "strokeEnd")
    
    let bottomBorderLayer = CAShapeLayer()
    let bottomPointPath = NSBezierPath()
    let bottomAnimation = CABasicAnimation(keyPath: "strokeEnd")
    
    let leftBorderLayer = CAShapeLayer()
    let leftPointPath = NSBezierPath()
    let leftAnimation = CABasicAnimation(keyPath: "strokeEnd")
    
    func smoothProgress(_ newValue: CGFloat, increment by: CGFloat = 0.3) {
        if newValue - progress >= by {
            updateProgress(newValue, 0.3)
        }
    }
    
    func updateProgress(_ newValue: CGFloat, _ duration: CGFloat = 0.2) {
        let color = NSColor.textColor.withAlphaComponent(CGFloat.random(in: 0.5..<1.0)).cgColor
        
        // Top Point
        topPointPath.move(to: .init(x: 0, y: bounds.height))
        topPointPath.line(to: .init(x: bounds.width * newValue, y: self.bounds.height))
        
        // Right Point
        rightPointPath.move(to: .init(x: bounds.width, y: bounds.height))
        rightPointPath.line(to: .init(x: bounds.width, y: (bounds.height - (newValue) * bounds.height)))
        
        // Bottom Point
        bottomPointPath.move(to: .init(x: bounds.width, y: 0))
        bottomPointPath.line(to: .init(x: (bounds.width - (bounds.width * newValue)), y: 0))
        
        // Left Point
        leftPointPath.move(to: .zero)
        leftPointPath.line(to: .init(x: 0, y: bounds.height * newValue))
        
        topBorderLayer.path = topPointPath.cgPath
        topBorderLayer.strokeColor = color
        
        rightBorderLayer.path = rightPointPath.cgPath
        rightBorderLayer.strokeColor = color
        
        bottomBorderLayer.path = bottomPointPath.cgPath
        bottomBorderLayer.strokeColor = color
        
        leftBorderLayer.path = leftPointPath.cgPath
        leftBorderLayer.strokeColor = color
        
        layer?.addSublayer(topBorderLayer)
        layer?.addSublayer(rightBorderLayer)
        layer?.addSublayer(bottomBorderLayer)
        layer?.addSublayer(leftBorderLayer)
        
        topAnimation.fromValue = progress
        topAnimation.toValue = newValue
        topAnimation.duration = duration
        topBorderLayer.add(topAnimation, forKey: "ANIMATION:Progress:top")
        
        rightAnimation.fromValue = progress
        rightAnimation.toValue = newValue
        rightAnimation.duration = duration
        rightBorderLayer.add(rightAnimation, forKey: "ANIMATION:Progress:right")
        
        bottomAnimation.fromValue = progress
        bottomAnimation.toValue = newValue
        bottomAnimation.duration = duration
        bottomBorderLayer.add(bottomAnimation, forKey: "ANIMATION:Progress:bottom")
        
        leftAnimation.fromValue = progress
        leftAnimation.toValue = newValue
        leftAnimation.duration = duration
        leftBorderLayer.add(leftAnimation, forKey: "ANIMATION:Progress:left")
        
        leftAnimation.delegate = self
        leftAnimation.isRemovedOnCompletion = true
        rightAnimation.isRemovedOnCompletion = true
        bottomAnimation.isRemovedOnCompletion = true
        topAnimation.isRemovedOnCompletion = true
        
        progress = newValue
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if progress >= 0.93 {
            progress = 0.0
            topBorderLayer.removeFromSuperlayer()
            rightBorderLayer.removeFromSuperlayer()
            bottomBorderLayer.removeFromSuperlayer()
            leftBorderLayer.removeFromSuperlayer()
        }
    }
    
    override func viewDidEndLiveResize() {
        topPointPath.removeAllPoints()
        rightPointPath.removeAllPoints()
        bottomPointPath.removeAllPoints()
        leftPointPath.removeAllPoints()
    }
    
    func close() {
        progress = 0.0
        topBorderLayer.removeFromSuperlayer()
        rightBorderLayer.removeFromSuperlayer()
        bottomBorderLayer.removeFromSuperlayer()
        leftBorderLayer.removeFromSuperlayer()
    }
    
    init() {
        super.init(frame: .zero)
        topBorderLayer.lineWidth = 5
        rightBorderLayer.lineWidth = 5
        bottomBorderLayer.lineWidth = 5
        leftBorderLayer.lineWidth = 5
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NSBezierPath {
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            
            switch type {
            case .moveTo:
                path.move(to: points[0])
                
            case .lineTo:
                path.addLine(to: points[0])
                
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
                
            case .closePath:
                path.closeSubpath()
                
            @unknown default:
                break
            }
        }
        return path
    }
}
