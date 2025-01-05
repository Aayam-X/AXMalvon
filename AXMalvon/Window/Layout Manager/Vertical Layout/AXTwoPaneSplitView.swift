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
    private var isLeftViewHidden = false
    private var isCursorSet = false  // Track if we've pushed the resize cursor

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

        leftView.activateConstraints([
            .left: .view(self),
            .verticalEdges: .view(self),
        ])
        leftViewWidthConstraint!.isActive = true

        dividerView.activateConstraints([
            .leftRight: .view(leftView),
            .verticalEdges: .view(self),
        ])
        dividerWidthConstraint!.isActive = true

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

        let trackingArea = NSTrackingArea(
            rect: dividerView.bounds,
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
            if !isCursorSet {
                NSCursor.resizeLeftRight.push()
                isCursorSet = true
            }

        case .changed:
            guard isDragging, let lastLocation = lastDragLocation else {
                return
            }
            let currentLocation = gestureRecognizer.location(in: self)
            let deltaX = currentLocation.x - lastLocation.x

            let newWidth = leftView.frame.width + deltaX
            let clampedWidth = max(180, min(newWidth, 500))

            if let oldConstraint = leftViewWidthConstraint {
                oldConstraint.isActive = false
            }
            leftViewWidthConstraint = leftView.widthAnchor.constraint(
                equalToConstant: clampedWidth)
            leftViewWidthConstraint?.isActive = true

            layoutSubtreeIfNeeded()
            lastDragLocation = currentLocation

        case .ended, .cancelled:
            isDragging = false
            lastDragLocation = nil
            if isCursorSet {
                NSCursor.pop()
                isCursorSet = false
            }

        default:
            break
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if !isDragging && !isCursorSet {
            NSCursor.resizeLeftRight.push()
            isCursorSet = true
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if isCursorSet && !isDragging {
            NSCursor.pop()
            isCursorSet = false
        }
        UserDefaults.standard.set(
            leftViewWidthConstraint?.constant, forKey: "verticalTabWidth")
    }

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
