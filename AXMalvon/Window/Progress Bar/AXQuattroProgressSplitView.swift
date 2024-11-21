//
//  AXQuattroProgressSplitView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-17.
//

import AppKit

class AXQuattroProgressSplitView: NSSplitView, NSSplitViewDelegate,
    CAAnimationDelegate
{
    private var progress: CGFloat = 0.0
    private var realProgress: CGFloat = 0.0
    private var previousProgress: CGFloat = 0.0

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
        let borderWidth: CGFloat = 6.0

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

    // Function to update the progress value smoothly
    func updateProgress(value: CGFloat) {
        realProgress = value

        // Only update progress if the value has changed and animation is not ongoing
        if value > previousProgress && !isAnimating {
            previousProgress += 0.1

            progress = value
            startProgressAnimation()
        }
    }

    private func startProgressAnimation() {
        // Set the animation flag to true
        isAnimating = true

        // Define the animation duration and timing
        let animationDuration: CFTimeInterval = 0.5  // Adjust duration for smoothness
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progress
        animation.toValue = 1.0  // Dynamically set the toValue
        animation.duration = animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.delegate = self

        // Apply the animation to all borders
        animateTopBorder(animation: animation)
        animateRightBorder(animation: animation)
        animateBottomBorder(animation: animation)
        animateLeftBorder(animation: animation)
    }

    private func animateTopBorder(animation: CABasicAnimation) {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.height))
        path.line(to: CGPoint(x: bounds.width, y: bounds.height))

        topBorderLayer.path = path.cgPath
        topBorderLayer.zPosition = 1  // Bring it above subviews
        topBorderLayer.add(animation, forKey: nil)
    }

    private func animateRightBorder(animation: CABasicAnimation) {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: bounds.width, y: bounds.height))
        path.line(to: CGPoint(x: bounds.width, y: 0))

        rightBorderLayer.path = path.cgPath
        rightBorderLayer.zPosition = 1  // Bring it above subviews
        rightBorderLayer.add(animation, forKey: nil)
    }

    private func animateBottomBorder(animation: CABasicAnimation) {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: bounds.width, y: 0))
        path.line(to: CGPoint(x: 0, y: 0))

        bottomBorderLayer.path = path.cgPath
        bottomBorderLayer.zPosition = 1  // Set zPosition to bring the bottom border above subviews
        bottomBorderLayer.add(animation, forKey: nil)
    }

    private func animateLeftBorder(animation: CABasicAnimation) {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.line(to: CGPoint(x: 0, y: bounds.height))

        leftBorderLayer.path = path.cgPath
        leftBorderLayer.zPosition = 1  // Set zPosition to bring the left border above subviews
        leftBorderLayer.add(animation, forKey: nil)
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        // Only hide borders if animation finished and progress is complete
        if flag, realProgress >= 0.936 {
            topBorderLayer.isHidden = true
            bottomBorderLayer.isHidden = true
            leftBorderLayer.isHidden = true
            rightBorderLayer.isHidden = true

            previousProgress = 0.0
            progress = 0.0
            print("PROGRESS ENDED")
        }

        // Reset animation flag
        isAnimating = false
    }

    func animationDidStart(_ anim: CAAnimation) {
        // Ensure borders are visible when animation starts
        topBorderLayer.isHidden = false
        bottomBorderLayer.isHidden = false
        leftBorderLayer.isHidden = false
        rightBorderLayer.isHidden = false
    }
}
