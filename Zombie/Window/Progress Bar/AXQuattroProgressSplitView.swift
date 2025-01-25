//
//  AXQuattroProgressSplitView.swift
//  Zombie
//
//  Created by Ashwin Paudel on 2024-11-17.
//

import AppKit

class AXQuattroProgressSplitView: NSSplitView, NSSplitViewDelegate,
    CAAnimationDelegate
{
    private var progress: CGFloat = 0.0

    var topBorderLayer: CAShapeLayer! = CAShapeLayer()
    var topPointPath: NSBezierPath! = NSBezierPath()
    var topAnimation: CABasicAnimation! = CABasicAnimation(keyPath: "strokeEnd")

    var rightBorderLayer: CAShapeLayer! = CAShapeLayer()
    var rightPointPath: NSBezierPath! = NSBezierPath()
    var rightAnimation: CABasicAnimation! = CABasicAnimation(
        keyPath: "strokeEnd")

    var bottomBorderLayer: CAShapeLayer! = CAShapeLayer()
    var bottomPointPath: NSBezierPath! = NSBezierPath()
    var bottomAnimation: CABasicAnimation! = CABasicAnimation(
        keyPath: "strokeEnd")

    var leftBorderLayer: CAShapeLayer! = CAShapeLayer()
    var leftPointPath: NSBezierPath! = NSBezierPath()
    var leftAnimation: CABasicAnimation! = CABasicAnimation(
        keyPath: "strokeEnd")

    init() {
        super.init(frame: .zero)

        wantsLayer = true
        self.layer?.backgroundColor =
            NSColor.systemIndigo.withAlphaComponent(0.3).cgColor
        delegate = self
        isVertical = true
        dividerStyle = .thin

        topBorderLayer.lineWidth = 9
        rightBorderLayer.lineWidth = 9
        bottomBorderLayer.lineWidth = 9
        leftBorderLayer.lineWidth = 9

        leftAnimation.delegate = self
        leftAnimation.isRemovedOnCompletion = true
        rightAnimation.isRemovedOnCompletion = true
        bottomAnimation.isRemovedOnCompletion = true
        topAnimation.isRemovedOnCompletion = true
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
        //        removeLayers()
        return view.tag == 0x01 ? false : true
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView)
        -> Bool
    {
        return false
    }

    func smoothProgress(_ newValue: CGFloat, increment by: CGFloat = 0.3) {
        if newValue - progress >= by {
            updateProgress(newValue, 0.3)
        }
    }

    func updateProgress(_ newValue: CGFloat, _ duration: CGFloat = 0.2) {
        let color = NSColor.textColor.withAlphaComponent(
            CGFloat.random(in: 0.5..<1.0)
        ).cgColor

        // Top Point
        topPointPath.move(to: .init(x: 0, y: bounds.height))
        topPointPath.line(
            to: .init(x: bounds.width * newValue, y: self.bounds.height))

        // Right Point
        rightPointPath.move(to: .init(x: bounds.width, y: bounds.height))
        rightPointPath.line(
            to: .init(
                x: bounds.width, y: (bounds.height - (newValue) * bounds.height)
            ))

        // Bottom Point
        bottomPointPath.move(to: .init(x: bounds.width, y: 0))
        bottomPointPath.line(
            to: .init(x: (bounds.width - (bounds.width * newValue)), y: 0))

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
        bottomBorderLayer.add(
            bottomAnimation, forKey: "ANIMATION:Progress:bottom")

        leftAnimation.fromValue = progress
        leftAnimation.toValue = newValue
        leftAnimation.duration = duration
        leftBorderLayer.add(leftAnimation, forKey: "ANIMATION:Progress:left")

        progress = newValue
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if progress >= 0.93 {
            close()
        }
    }

    override func removeFromSuperview() {
        topBorderLayer = nil
        topPointPath = nil
        topAnimation = nil
        rightBorderLayer = nil
        rightPointPath = nil
        rightAnimation = nil
        bottomBorderLayer = nil
        bottomPointPath = nil
        bottomAnimation = nil
        leftBorderLayer = nil
        leftPointPath = nil
        leftAnimation = nil

        super.removeFromSuperview()
    }

    override func viewDidEndLiveResize() {
        topPointPath.removeAllPoints()
        rightPointPath.removeAllPoints()
        bottomPointPath.removeAllPoints()
        leftPointPath.removeAllPoints()
    }

    func close() {
        progress = 0.0
        topBorderLayer?.removeFromSuperlayer()
        rightBorderLayer?.removeFromSuperlayer()
        bottomBorderLayer?.removeFromSuperlayer()
        leftBorderLayer?.removeFromSuperlayer()

        topPointPath.removeAllPoints()
        rightPointPath.removeAllPoints()
        bottomPointPath.removeAllPoints()
        leftPointPath.removeAllPoints()
    }
}
