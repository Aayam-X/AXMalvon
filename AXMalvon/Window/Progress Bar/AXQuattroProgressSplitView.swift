//
//  AXQuattroProgressSplitView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-17.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Cocoa
import QuartzCore

class AXQuattroProgressSplitView: NSSplitView, NSSplitViewDelegate,
    CAAnimationDelegate
{
    private let animationQueue = DispatchQueue(
        label: "com.ayaamx.AXMalvon.progressAnimation",
        qos: .userInitiated
    )

    private let borderLayers: [CAShapeLayer] = {
        return (0..<4).map { _ in
            let layer = CAShapeLayer()
            layer.lineWidth = 6.0
            layer.strokeColor =
                NSColor.textColor.withAlphaComponent(0.3).cgColor
            layer.isHidden = true
            layer.opacity = 0.0
            return layer
        }
    }()

    private var currentProgress: CGFloat = 0.0
    private var animationToken: UUID?

    init() {
        super.init(frame: .zero)

        wantsLayer = true
        setupLayers()

        delegate = self
        isVertical = true
        dividerStyle = .thin
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        borderLayers.forEach { layer?.addSublayer($0) }
    }

    private func createBorderPath(for edge: NSRectEdge) -> NSBezierPath {
        let path = NSBezierPath()
        switch edge {
        case .maxY:
            path.move(to: CGPoint(x: 0, y: bounds.height))
            path.line(to: CGPoint(x: bounds.width, y: bounds.height))
        case .maxX:
            path.move(to: CGPoint(x: bounds.width, y: bounds.height))
            path.line(to: CGPoint(x: bounds.width, y: 0))
        case .minY:
            path.move(to: CGPoint(x: bounds.width, y: 0))
            path.line(to: CGPoint(x: 0, y: 0))
        case .minX:
            path.move(to: CGPoint(x: 0, y: 0))
            path.line(to: CGPoint(x: 0, y: bounds.height))
        @unknown default:
            break
        }
        return path
    }

    func beginAnimation(with value: Double) {
        let targetProgress: CGFloat
        let duration: CFTimeInterval

        switch value {
        case 93...:
            targetProgress = 1.0
            duration = 0.69
        case 0.75...:
            targetProgress = 0.80
            duration = 9.0
        case 0.50...:
            targetProgress = 0.75
            duration = 1.2
        case 0.25...:
            targetProgress = 0.50
            duration = 0.9
        default:
            targetProgress = 0.25
            duration = 0.6
        }

        animateProgressAsync(to: targetProgress, duration: duration)
    }

    private func animateProgressAsync(
        to targetProgress: CGFloat, duration: CFTimeInterval
    ) {
        let currentToken = UUID()
        animationToken = currentToken

        animationQueue.async { [weak self] in
            guard let self = self else { return }

            let startProgress = self.currentProgress

            DispatchQueue.main.async {
                guard self.animationToken == currentToken else { return }

                // Prepare and start animation
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                animation.fromValue = startProgress
                animation.toValue = targetProgress
                animation.duration = duration
                animation.timingFunction = CAMediaTimingFunction(
                    name: .easeInEaseOut)

                // Apply animation to each border layer
                for (index, layer) in self.borderLayers.enumerated() {
                    let path = self.createBorderPath(
                        for: NSRectEdge(rawValue: UInt(index))!)
                    layer.path = path.cgPath
                    layer.zPosition = 1
                    layer.opacity = 1.0
                    layer.isHidden = false
                    layer.add(animation, forKey: "progressAnimation")
                }

                if targetProgress >= 0.95 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        [weak self] in
                        guard let self = self else { return }
                        self.borderLayers.forEach { layer in
                            layer.opacity = 0.0
                            layer.isHidden = true
                        }
                    }
                }

                self.currentProgress = targetProgress
            }
        }
    }

    func finishAnimation() {
        animateProgressAsync(to: 1.0, duration: 0.69)
    }

    func cancelAnimations() {
        animationToken = nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.borderLayers.forEach { layer in
                layer.removeAllAnimations()
                layer.opacity = 0.0
                layer.isHidden = true
            }
        }
    }

    // MARK: - NSSplitViewDelegate Methods
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
        return view.tag != 0x01
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView)
        -> Bool
    {
        return false
    }

    override func drawDivider(in rect: NSRect) {
        // Empty Divider
    }
}
