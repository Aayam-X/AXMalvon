//
//  AXTwoPaneSplitView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-04.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class AXTwoPaneSplitView: NSView {
    private let leftView: NSView
    private let rightView: NSView

    private let dividerView: NSView
    private let dividerWidth: CGFloat = 2
    private var dividerWidthConstraint: NSLayoutConstraint?

    private var isDragging = false
    private var lastDragLocation: NSPoint?
    private var leftViewWidthConstraint: NSLayoutConstraint?
    private var isLeftViewHidden = false  // Track the visibility state of the left view

    init(leftView: NSView, rightView: NSView) {
        self.leftView = leftView
        self.rightView = rightView
        dividerView = NSView()

        super.init(frame: .zero)

        setupViews()
        setupConstraints()
        setupGestureRecognizers()
    }

    required init?(coder: NSCoder) {
        leftView = NSView()
        rightView = NSView()
        dividerView = NSView()

        super.init(coder: coder)

        setupViews()
        setupConstraints()
        setupGestureRecognizers()
    }

    private func setupViews() {
        leftView.translatesAutoresizingMaskIntoConstraints = false
        rightView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false

        dividerView.wantsLayer = true
        dividerView.layer?.backgroundColor = NSColor.separatorColor.cgColor

        addSubview(leftView)
        addSubview(dividerView)
        addSubview(rightView)
    }

    private func setupConstraints() {
        let width =
            UserDefaults.standard.object(forKey: "verticalTabWidth") as? CGFloat
            ?? 210
        leftViewWidthConstraint = leftView.widthAnchor.constraint(
            equalToConstant: width)

        dividerWidthConstraint = dividerView.widthAnchor.constraint(
            equalToConstant: dividerWidth)

        // Left view constraints
        leftView.activateConstraints([
            .left: .view(self),
            .verticalEdges: .view(self),
        ])
        leftViewWidthConstraint!.isActive = true

        // Divider view constraints
        dividerView.activateConstraints([
            .leftRight: .view(leftView),
            .verticalEdges: .view(self),
        ])
        dividerWidthConstraint!.isActive = true

        // Right view constraints
        rightView.activateConstraints([
            .leftRight: .view(dividerView),
            .right: .view(self),
            .verticalEdges: .view(self),
        ])
    }

    private func setupGestureRecognizers() {
        dividerView.addGestureRecognizer(
            NSPanGestureRecognizer(
                target: self, action: #selector(handlePanGesture(_:))))

        // Change cursor when hovering over divider
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [
                .mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect,
            ],
            owner: self,
            userInfo: nil)
        dividerView.addTrackingArea(trackingArea)
    }

    @objc private func handlePanGesture(
        _ gestureRecognizer: NSPanGestureRecognizer
    ) {
        switch gestureRecognizer.state {
        case .began:
            isDragging = true
            lastDragLocation = gestureRecognizer.location(in: self)

        case .changed:
            guard isDragging, let lastLocation = lastDragLocation else {
                return
            }
            let currentLocation = gestureRecognizer.location(in: self)
            let deltaX = currentLocation.x - lastLocation.x

            // Calculate the new width for the left view
            let newWidth = leftView.frame.width + deltaX

            // Clamp the new width to the desired range (180 - 500)
            let clampedWidth = max(180, min(newWidth, 500))

            // Update the left view's width constraint
            if let oldConstraint = leftViewWidthConstraint {
                oldConstraint.isActive = false
            }
            leftViewWidthConstraint = leftView.widthAnchor.constraint(
                equalToConstant: clampedWidth)
            leftViewWidthConstraint?.isActive = true

            // Update the layout
            layoutSubtreeIfNeeded()

            // Save the current drag location
            lastDragLocation = currentLocation

        case .ended, .cancelled:
            isDragging = false
            lastDragLocation = nil
            NSCursor.pop()

        default:
            break
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.resizeLeftRight.push()
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.pop()
        UserDefaults.standard.set(
            leftViewWidthConstraint?.constant, forKey: "verticalTabWidth")
    }

    /// Toggles the visibility of the left view with animation
    func toggleLeftView() -> Bool {
        isLeftViewHidden.toggle()
        let targetWidth: CGFloat =
            isLeftViewHidden
            ? 45
            : (UserDefaults.standard.object(forKey: "verticalTabWidth")
                as? CGFloat ?? 210)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            leftViewWidthConstraint?.animator().constant = targetWidth
            self.leftView.isHidden = self.isLeftViewHidden
        } completionHandler: {
            self.leftViewWidthConstraint?.animator().constant =
                self.isLeftViewHidden ? 0 : targetWidth
            self.dividerView.isHidden = self.isLeftViewHidden
            self.dividerWidthConstraint?.constant =
                self.isLeftViewHidden ? 0 : 2
        }

        return isLeftViewHidden
    }
}
