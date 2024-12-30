//
//  AXNavigationGestureView.swift
//  AXMalvon
//
//  Created by Baba Paudel on 2024-11-10.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Tab Group Information View
        tabGroupInfoView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabGroupInfoView)

        tabGroupInfoViewLeftConstraint = tabGroupInfoView.leftAnchor.constraint(
            equalTo: leftAnchor, constant: 8)
        NSLayoutConstraint.activate([
            tabGroupInfoView.rightAnchor.constraint(equalTo: rightAnchor),
            tabGroupInfoView.topAnchor.constraint(
                equalTo: topAnchor, constant: 4),
            tabGroupInfoViewLeftConstraint!
        ])

        // Search Button
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.title = ""
        searchButton.target = self
        addSubview(searchButton)
        NSLayoutConstraint.activate([
            searchButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            searchButton.leftAnchor.constraint(
                equalTo: leftAnchor, constant: 5),
            searchButton.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -7),
            searchButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 100, height: 44)  // Adjust based on your needs
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

    override func mouseEntered(with event: NSEvent) {
        updateConstraintsWhenMouse(
            window: event.window as? AXWindow, entered: true)
    }

    override func mouseExited(with event: NSEvent) {
        if scrollWithMice {
            handleScrollEnd()
            scrollEventFinished = false
        }

        updateConstraintsWhenMouse(
            window: event.window as? AXWindow, entered: false)
    }

    func handleScrollEnd() {
        scrollEventFinished = true
        delegate?.gestureView(didSwipe: userSwipedDirection)
        userSwipedDirection = nil
    }

    func updateConstraintsWhenMouse(
        window: AXWindow?, entered: Bool
    ) {
        guard let window else { return }
        var entered = entered

        if window.styleMask.contains(.fullScreen) {
            entered = false
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = entered ? 0.15 : 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            // Update constraints and visibility based on the state
            tabGroupInfoView.imageView.isHidden = entered
            tabGroupInfoViewLeftConstraint?.animator().constant =
                entered ? 70 : 5.5
            tabGroupInfoView.contentStackView.layoutSubtreeIfNeeded()

            if !window.styleMask.contains(.fullScreen), !entered {
                window.trafficLightsHide()
            } else {
                window.trafficLightsShow()
            }
        }
    }
}

class AXGestureStackView: NSStackView {
    weak var gestureDelegate: AXGestureViewDelegate?
    private var userSwipedDirection: AXGestureViewSwipeDirection?
    private var scrollEventFinished: Bool = false
    private var trackingArea: NSTrackingArea!
    var scrollWithMice: Bool = false

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 150, height: 44)  // Adjust as needed
    }

    override var isFlipped: Bool {
        return true  // Use true for top-to-bottom layout
    }

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        updateTrackingAreas()
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
