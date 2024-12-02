//
//  AXNavigationGestureView.swift
//  AXMalvon
//
//  Created by Baba Paudel on 2024-11-10.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Cocoa
import SwiftUI

protocol AXGestureViewDelegate: AnyObject {
    func gestureView(didSwipe direction: AXGestureViewSwipeDirection!)
    func gestureViewMouseDown()
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

    var tabGroupInformationView = AXSidebarTabGroupInformativeView()
    var tabGroupInfoViewLeftConstraint: NSLayoutConstraint?

    // Gestures
    private var userSwipedDirection: AXGestureViewSwipeDirection?
    private var scrollEventFinished: Bool = false
    var trackingArea: NSTrackingArea!
    var scrollWithMice: Bool = false

    var searchButton = AXSidebarSearchButton()

    // This standalone view is needed for the NSWindow to access its delegate
    lazy var popoverView: AXSidebarPopoverView = {
        return AXSidebarPopoverView()
    }()

    lazy var popover: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .transient

        let controller = NSViewController()
        controller.view = popoverView
        popover.contentViewController = controller

        return popover
    }()

    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        setTrackingArea()

        // Constraints for the Tab Group Information View
        tabGroupInformationView.translatesAutoresizingMaskIntoConstraints =
            false

        addSubview(tabGroupInformationView)

        tabGroupInfoViewLeftConstraint = tabGroupInformationView.leftAnchor
            .constraint(
                equalTo: leftAnchor, constant: 8
            )
        NSLayoutConstraint.activate([
            tabGroupInformationView.rightAnchor.constraint(
                equalTo: rightAnchor),
            tabGroupInformationView.topAnchor.constraint(
                equalTo: topAnchor, constant: 4),
            tabGroupInfoViewLeftConstraint!,
        ])

        // Search Bar
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.title = "Hello"
        searchButton.target = self
        searchButton.action = #selector(searchButtonTapped)
        addSubview(searchButton)
        NSLayoutConstraint.activate([
            searchButton.bottomAnchor.constraint(
                equalTo: bottomAnchor),
            searchButton.leftAnchor.constraint(
                equalTo: leftAnchor, constant: 5),
            searchButton.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -7),
        ])
    }

    func updateTitles(title: String, subtitle: String) {
        tabGroupInformationView.tabGroupLabel.stringValue = title
        tabGroupInformationView.profileLabel.stringValue = subtitle
    }

    @objc func searchButtonTapped() {
        guard let window = self.window as? AXWindow else { return }
        let searchBar = AppDelegate.searchBar

        searchBar.parentWindow1 = window
        searchBar.searchBarDelegate = window

        // Convert the button's frame to the screen coordinate system
        if let buttonSuperview = searchButton.superview {
            let buttonFrameInWindow = buttonSuperview.convert(
                searchButton.frame, to: nil)
            let buttonFrameInScreen = window.convertToScreen(
                buttonFrameInWindow)

            // Calculate the point just below the search button
            let pointBelowButton = NSPoint(
                x: buttonFrameInScreen.origin.x,
                y: buttonFrameInScreen.origin.y - searchBar.frame.height)  // Adjust height of search bar

            searchBar.showCurrentURL(at: pointBelowButton)
        }
    }

    // MARK: - Gesture/Mouse Functions
    override func scrollWheel(with event: NSEvent) {
        let x = event.deltaX
        let y = event.deltaY

        // Update scroll event phase state
        switch event.phase {
        case .began:
            scrollEventFinished = false
        case .mayBegin:
            return  // Cancelled, exit early
        case .ended where !scrollEventFinished,
            .ended where event.momentumPhase == .ended:
            print("Scroll ended")
            handleScrollEnd()
            return
        default:
            break
        }

        // Determine if scrolling is from a mouse
        scrollWithMice = event.phase == [] && event.momentumPhase == []

        // Handle directional scroll
        if x != 0 {
            userSwipedDirection = x > 0 ? .backwards : .forwards
        } else if y != 0 {
            userSwipedDirection = y > 0 ? .reload : .nothing
        }
    }

    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15  // Set the animation duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            tabGroupInformationView.imageView.isHidden = true
            tabGroupInfoViewLeftConstraint?.animator().constant = 70
            tabGroupInformationView.contentStackView.layoutSubtreeIfNeeded()

            if let window = event.window as? AXWindow {
                window.trafficLightManager.hideButtons()
            }
        }
    }

    override func mouseExited(with event: NSEvent) {
        if scrollWithMice {
            handleScrollEnd()
            scrollEventFinished = false
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18  // Set the animation duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            tabGroupInformationView.imageView.isHidden = false
            tabGroupInfoViewLeftConstraint?.animator().constant = 8
            tabGroupInformationView.contentStackView.layoutSubtreeIfNeeded()

            if let window = event.window as? AXWindow {
                window.trafficLightManager.showButtons()
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        popover.show(relativeTo: self.bounds, of: self, preferredEdge: .minY)
        delegate?.gestureViewMouseDown()
    }

    func setTrackingArea() {
        let options: NSTrackingArea.Options = [
            .activeAlways, .inVisibleRect, .mouseEnteredAndExited,
        ]
        trackingArea = NSTrackingArea.init(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()

        if let trackingArea {
            self.removeTrackingArea(trackingArea)
        }
        trackingArea = nil
    }

    func handleScrollEnd() {
        scrollEventFinished = true
        delegate?.gestureView(didSwipe: userSwipedDirection)
        userSwipedDirection = nil
    }
}
