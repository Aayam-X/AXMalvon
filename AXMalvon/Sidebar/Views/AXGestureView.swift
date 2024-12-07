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
    func gestureView(didUpdate tabGroup: AXTabGroup)
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

    var searchButton = AXSidebarSearchButton()

    private lazy var tabGroupInfoView = {
        let view = AXTabGroupInfoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.onRightMouseDown = infoViewRightMouseDown
        return view
    }()

    // Gestures
    private var userSwipedDirection: AXGestureViewSwipeDirection?
    private var scrollEventFinished: Bool = false
    var trackingArea: NSTrackingArea!
    var scrollWithMice: Bool = false

    // Other
    var tabGroupInfoViewLeftConstraint: NSLayoutConstraint?

    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        setTrackingArea()

        // Constraints for the Tab Group Information View
        addSubview(tabGroupInfoView)

        tabGroupInfoViewLeftConstraint = tabGroupInfoView.leftAnchor
            .constraint(
                equalTo: leftAnchor, constant: 8
            )
        NSLayoutConstraint.activate([
            tabGroupInfoView.rightAnchor.constraint(
                equalTo: rightAnchor),
            tabGroupInfoView.topAnchor.constraint(
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
            mxPrint("Scroll ended")
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

            if !window.styleMask.contains(.fullScreen) {
                entered
                    ? window.trafficLightManager.displayTrafficLights()
                    : window.trafficLightManager.hideTrafficLights()
            } else {
                window.trafficLightManager.displayTrafficLights()
            }
        }
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
}

extension AXGestureView {
    func currentTabGroupChanged(_ to: AXTabGroup, profile: String) {
        tabGroupInfoView.updateLabels(tabGroup: to, profileName: profile)
        self.currentTabGroup = to
    }

    // Show the popover
    @objc func infoViewRightMouseDown() {
        guard let tabGroup = currentTabGroup else { return }

        let popover = NSPopover()
        popover.behavior = .transient
        let vc = NSViewController()
        let view = AXTabGroupCustomizerView(tabGroup: tabGroup)
        view.delegate = self
        vc.view = view
        popover.contentViewController = vc

        popover.show(relativeTo: bounds, of: self, preferredEdge: .maxX)
    }
}

extension AXGestureView: AXTabGroupCustomizerViewDelegate {
    func didUpdateIcon(_ tabGroup: AXTabGroup) {
        tabGroupInfoView.updateIcon(tabGroup: tabGroup)
    }

    func didUpdateTabGroup(_ tabGroup: AXTabGroup) {
        tabGroupInfoView.updateLabels(tabGroup: tabGroup)
    }

    func didUpdateColor(_ tabGroup: AXTabGroup) {
        delegate?.gestureView(didUpdate: tabGroup)
    }
}
