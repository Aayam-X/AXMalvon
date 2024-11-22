//
//  AXQuattroProgressSplitView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-17.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

class AXQuattroProgressSplitView: NSSplitView, NSSplitViewDelegate,
    CAAnimationDelegate
{
    private var isAnimating: Bool = false  // Flag to check if animation is ongoing

    private var topBorderLayer = CAShapeLayer()
    private var rightBorderLayer = CAShapeLayer()
    private var bottomBorderLayer = CAShapeLayer()
    private var leftBorderLayer = CAShapeLayer()

    init() {
        super.init(frame: .zero)

        wantsLayer = true
        setupLayers()

        #if DEBUG
            self.layer?.backgroundColor =
                NSColor.systemGray.withAlphaComponent(0.3).cgColor
        #else
            self.layer?.backgroundColor =
                NSColor.systemRed.withAlphaComponent(0.3).cgColor
        #endif

        delegate = self
        isVertical = true
        dividerStyle = .thin
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func splitView(
        _ splitView: NSSplitView,
        constrainMinCoordinate proposedMinimumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        return 160
    }

    func splitView(
        _ splitView: NSSplitView,
        constrainMaxCoordinate proposedMaximumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        return 500
    }

    func splitView(
        _ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView
    ) -> Bool {
        return view.tag == 0x01 ? false : true
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView)
        -> Bool
    {
        return false
    }

    private func setupLayers() {
        let borderWidth: CGFloat = 9.0

        // Configure each layer
        topBorderLayer.lineWidth = borderWidth
        topBorderLayer.strokeColor = NSColor.systemRed.cgColor
        topBorderLayer.isHidden = false
        layer?.addSublayer(topBorderLayer)

        rightBorderLayer.lineWidth = borderWidth
        rightBorderLayer.strokeColor = NSColor.systemGreen.cgColor
        rightBorderLayer.isHidden = false
        layer?.addSublayer(rightBorderLayer)

        bottomBorderLayer.lineWidth = borderWidth
        bottomBorderLayer.strokeColor = NSColor.systemBlue.cgColor
        bottomBorderLayer.isHidden = false
        layer?.addSublayer(bottomBorderLayer)

        leftBorderLayer.lineWidth = borderWidth
        leftBorderLayer.strokeColor = NSColor.systemYellow.cgColor
        leftBorderLayer.isHidden = false
        layer?.addSublayer(leftBorderLayer)
    }

    func beginAnimation(with value: Double) {
        if value >= 93 {
            finishAnimation()
        } else if value >= 0.75 {
            animateProgress(from: 0.75, to: 0.80, duration: 9)
        } else if value >= 0.50 {
            animateProgress(from: 0.50, to: 0.75, duration: 1.2)
        } else if value >= 0.25 {
            animateProgress(from: 0.25, to: 0.50, duration: 0.9)
        } else {
            animateProgress(from: 0.0, to: 0.25, duration: 0.6)
        }
    }

    func finishAnimation() {
        // Immediately stop any ongoing animations
        cancelOngoingAnimations()

        // Override current progress and animate quickly to 100%
        animateProgress(from: 0.8, to: 1.0, duration: 0.69)  // Quick animation to 100%
    }

    private func animateProgress(
        from start: CGFloat, to end: CGFloat, duration: CFTimeInterval
    ) {
        // Get the current progress if an animation is running
        let currentProgress = topBorderLayer.presentation()?.strokeEnd ?? start

        // Remove ongoing animations to avoid conflicts
        cancelOngoingAnimations()

        // Create a new animation with the current state as the starting point
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = currentProgress
        animation.toValue = end
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.delegate = self

        // Apply the animation to all borders
        applyAnimation(
            animation, to: topBorderLayer, withPath: createTopBorderPath())
        applyAnimation(
            animation, to: rightBorderLayer, withPath: createRightBorderPath())
        applyAnimation(
            animation, to: bottomBorderLayer, withPath: createBottomBorderPath()
        )
        applyAnimation(
            animation, to: leftBorderLayer, withPath: createLeftBorderPath())

        isAnimating = true
    }

    private func createTopBorderPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.height))
        path.line(to: CGPoint(x: bounds.width, y: bounds.height))
        return path
    }

    private func createRightBorderPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: bounds.width, y: bounds.height))
        path.line(to: CGPoint(x: bounds.width, y: 0))
        return path
    }

    private func createBottomBorderPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: bounds.width, y: 0))
        path.line(to: CGPoint(x: 0, y: 0))
        return path
    }

    private func createLeftBorderPath() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.line(to: CGPoint(x: 0, y: bounds.height))
        return path
    }

    private func applyAnimation(
        _ animation: CABasicAnimation, to layer: CAShapeLayer,
        withPath path: NSBezierPath
    ) {
        layer.path = path.cgPath
        layer.zPosition = 1
        layer.add(animation, forKey: "progressAnimation")
    }

    private func cancelOngoingAnimations() {
        // Remove all animations from each layer
        topBorderLayer.removeAllAnimations()
        rightBorderLayer.removeAllAnimations()
        bottomBorderLayer.removeAllAnimations()
        leftBorderLayer.removeAllAnimations()

        // Reset animation flag
        isAnimating = false
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag, !isAnimating else { return }  // Ensure the animation completed

        [
            self.topBorderLayer, self.rightBorderLayer, self.bottomBorderLayer,
            self.leftBorderLayer,
        ].forEach { layer in
            layer.opacity = 0.0
            layer.isHidden = true
        }

        self.isAnimating = false
    }

    func animationDidStart(_ anim: CAAnimation) {
        [
            self.topBorderLayer, self.rightBorderLayer, self.bottomBorderLayer,
            self.leftBorderLayer,
        ].forEach { layer in
            layer.opacity = 1.0
            layer.isHidden = false
            self.isAnimating = false
        }
    }
}
