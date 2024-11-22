//
//  AXNavigationGestureView.swift
//  AXMalvon
//
//  Created by Baba Paudel on 2024-11-10.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
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

    var backgroundColor: NSColor = {
        #if DEBUG
            return .systemGray.withAlphaComponent(0.2)
        #else
            return .systemRed.withAlphaComponent(0.2)
        #endif
    }()

    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        setTrackingArea()

        self.layer?.backgroundColor = backgroundColor.cgColor

        // Constraints for the Tab Group Information View
        tabGroupInformationView.translatesAutoresizingMaskIntoConstraints =
            false

        addSubview(tabGroupInformationView)

        tabGroupInfoViewLeftConstraint = tabGroupInformationView.leftAnchor
            .constraint(
                equalTo: leftAnchor, constant: 80
            )
        NSLayoutConstraint.activate([
            tabGroupInformationView.rightAnchor.constraint(
                equalTo: rightAnchor),
            tabGroupInformationView.topAnchor.constraint(
                equalTo: topAnchor, constant: 4),
            tabGroupInfoViewLeftConstraint!,
        ])
    }

    func updateTitles(title: String, subtitle: String) {
        tabGroupInformationView.tabGroupLabel.stringValue = title
        tabGroupInformationView.profileLabel.stringValue = subtitle
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
        if let window = event.window as? AXWindow {
            window.trafficLightManager.hideButtons()
        }
    }

    override func mouseExited(with event: NSEvent) {
        if scrollWithMice {
            handleScrollEnd()
            scrollEventFinished = false
        }

        if let window = event.window as? AXWindow {
            window.trafficLightManager.showButtons()
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

    func handleScrollEnd() {
        scrollEventFinished = true
        delegate?.gestureView(didSwipe: userSwipedDirection)
        userSwipedDirection = nil
    }
}
