//
//  AXNavigationGestureView.swift
//  AXMalvon
//
//  Created by Baba Paudel on 2024-11-10.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import SwiftUI

protocol AXGestureViewDelegate: AnyObject {
    func gestureView(didSwipe direction: AXGestureViewSwipeDirection!)
}

enum AXGestureViewSwipeDirection {
    case backwards
    case forwards
    case reload
    case nothing
}

class AXGestureView: NSView {
    weak var delegate: AXGestureViewDelegate?
    private var hasDrawn: Bool = false

    weak var currentTabGroup: AXTabGroup?

    private var searchButton: AXSidebarSearchButton
    private var tabGroupInfoView: AXTabGroupInfoView

    // Gestures
    private var userSwipedDirection: AXGestureViewSwipeDirection?
    private var scrollEventFinished: Bool = false
    var scrollWithMice: Bool = false
    private var trackingArea: NSTrackingArea!

    // Other
    var tabGroupInfoViewLeftConstraint: NSLayoutConstraint?

    init(
        tabGroupInfoView: AXTabGroupInfoView,
        searchButton: AXSidebarSearchButton
    ) {
        self.tabGroupInfoView = tabGroupInfoView
        self.searchButton = searchButton

        super.init(frame: .zero)

        setupViews()
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeFullScreenNotifications()
    }

    private func setupViews() {
        // Tab Group Information View
        tabGroupInfoView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabGroupInfoView)

        tabGroupInfoViewLeftConstraint = tabGroupInfoView.leftAnchor.constraint(
            equalTo: leftAnchor, constant: 72)

        tabGroupInfoView.activateConstraints([
            .right: .view(self),
            .top: .view(self, constant: 8),
        ])
        tabGroupInfoViewLeftConstraint!.isActive = true

        // Search Button
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.title = ""
        searchButton.target = self
        addSubview(searchButton)

        searchButton.activateConstraints([
            .bottom: .view(self),
            .left: .view(self, constant: 5),
            .right: .view(self, constant: -7),
            .height: .constant(33),
        ])
    }

    // MARK: - Full Screen Functions

    private func setupFullScreenNotifications() {
        if let window = self.window {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(willEnterFullScreen(_:)),
                name: NSWindow.willEnterFullScreenNotification,
                object: window
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(willExitFullScreen(_:)),
                name: NSWindow.willExitFullScreenNotification,
                object: window
            )
        }
    }

    private func removeFullScreenNotifications() {
        NotificationCenter.default.removeObserver(
            self, name: NSWindow.willEnterFullScreenNotification, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: NSWindow.willExitFullScreenNotification, object: nil)
    }

    @objc private func willEnterFullScreen(_ notification: Notification) {
        tabGroupInfoViewLeftConstraint?.animator().constant = 5
    }

    @objc private func willExitFullScreen(_ notification: Notification) {
        tabGroupInfoViewLeftConstraint?.animator().constant = 72
    }

    override func viewDidMoveToWindow() {
        removeFullScreenNotifications()
        setupFullScreenNotifications()
    }

    // MARK: - Gesture/Mouse Functions
    override func scrollWheel(with event: NSEvent) {
        let deltaX = event.deltaX
        let deltaY = event.deltaY

        // Update scroll event phase state
        switch event.phase {
        case .began:
            scrollEventFinished = false
        case .mayBegin:
            return  // Cancelled, exit early
        case .ended where !scrollEventFinished,
            .ended where event.momentumPhase == .ended:
            mxPrint("Scroll ended")
            handleScrollEnd()
            return
        default:
            break
        }

        // Determine if scrolling is from a mouse
        scrollWithMice = event.phase == [] && event.momentumPhase == []

        // Handle directional scroll
        if deltaX != 0 {
            userSwipedDirection = deltaX > 0 ? .backwards : .forwards
        } else if deltaY != 0 {
            userSwipedDirection = deltaY > 0 ? .reload : .nothing
        }
    }

    override func mouseExited(with event: NSEvent) {
        if scrollWithMice {
            handleScrollEnd()
            scrollEventFinished = false
        }
    }

    func handleScrollEnd() {
        scrollEventFinished = true
        delegate?.gestureView(didSwipe: userSwipedDirection)
        userSwipedDirection = nil
    }

    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [
            .activeAlways, .inVisibleRect, .mouseEnteredAndExited,
        ]
        trackingArea = NSTrackingArea(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
}

class AXGestureStackView: NSStackView {
    weak var gestureDelegate: AXGestureViewDelegate?
    private var userSwipedDirection: AXGestureViewSwipeDirection?
    private var scrollEventFinished: Bool = false
    var scrollWithMice: Bool = false

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 150, height: 44)  // Adjust as needed
    }

    override var isFlipped: Bool {
        return true  // Use true for top-to-bottom layout
    }

    func handleScrollEnd() {
        scrollEventFinished = true
        gestureDelegate?.gestureView(didSwipe: userSwipedDirection)
        userSwipedDirection = nil
    }

    override func scrollWheel(with event: NSEvent) {
        let deltaX = event.deltaX
        let deltaY = event.deltaY

        // Update scroll event phase state
        switch event.phase {
        case .began:
            scrollEventFinished = false
        case .mayBegin:
            return  // Cancelled, exit early
        case .ended where !scrollEventFinished,
            .ended where event.momentumPhase == .ended:
            handleScrollEnd()
            return
        default:
            break
        }

        // Determine if scrolling is from a mouse
        scrollWithMice = event.phase == [] && event.momentumPhase == []

        // Handle directional scroll
        if deltaX != 0 {
            userSwipedDirection = deltaX > 0 ? .backwards : .forwards
        } else if deltaY != 0 {
            userSwipedDirection = deltaY > 0 ? .reload : .nothing
        }
    }
}
