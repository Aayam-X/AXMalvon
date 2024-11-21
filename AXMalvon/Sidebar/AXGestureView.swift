//
//  AXNavigationGestureView.swift
//  AXMalvon
//
//  Created by Baba Paudel on 2024-11-10.
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
    private var userSwipedDirection: AXGestureViewSwipeDirection?

    private var scrollEventFinished: Bool = false
    var trackingArea: NSTrackingArea!
    var scrollWithMice: Bool = false

    var tabGroupInformationView = AXSidebarTabGroupInformativeView()

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

    #if DEBUG
        var backgroundColor: NSColor = .systemGray.withAlphaComponent(0.2) {
            didSet {
                self.layer?.backgroundColor = backgroundColor.cgColor
            }
        }
    #else
        var backgroundColor: NSColor = .systemRed.withAlphaComponent(0.2) {
            didSet {
                self.layer?.backgroundColor = backgroundColor.cgColor
            }
        }
    #endif

    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        setTrackingArea()

        #if DEBUG
            self.layer?.backgroundColor =
                NSColor.systemGray.withAlphaComponent(0.3).cgColor
        #else
            //self.layer?.backgroundColor =
            //NSColor.systemRed.withAlphaComponent(0.3).cgColor
        #endif

        tabGroupInformationView.translatesAutoresizingMaskIntoConstraints =
            false
        addSubview(tabGroupInformationView)
        tabGroupInformationView.leftAnchor.constraint(
            equalTo: leftAnchor, constant: 80
        ).isActive = true
        tabGroupInformationView.rightAnchor.constraint(equalTo: rightAnchor)
            .isActive = true
        tabGroupInformationView.topAnchor.constraint(
            equalTo: topAnchor, constant: 4
        ).isActive = true
    }

    func updateTitles(title: String, subtitle: String) {
        tabGroupInformationView.tabGroupLabel.stringValue = title
        tabGroupInformationView.profileLabel.stringValue = subtitle
    }

    func setTrackingArea() {
        let options: NSTrackingArea.Options = [
            .activeAlways, .inVisibleRect, .mouseEnteredAndExited,
        ]
        trackingArea = NSTrackingArea.init(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func scrollWheel(with event: NSEvent) {
        let x = event.deltaX
        let y = event.deltaY

        // Handle event phase
        switch event.phase {
        case .began:
            scrollEventFinished = false
        case .mayBegin:
            // Cancelled
            return
        default:
            break
        }

        if event.phase != [] || event.momentumPhase != [] {
            scrollWithMice = false
        } else {
            scrollWithMice = true
        }

        if (event.phase == .ended || event.momentumPhase == .ended)
            && !scrollEventFinished
        {
            // Handle the end of the scroll
            print("Scroll ended")
            handleScrollEnd()
            return
        }

        // Early return for small delta values or if the scroll event is finished
        guard abs(x) > 0.5 || abs(y) > 0.5, !scrollEventFinished else {
            return
        }

        // Handle X-axis scroll
        if x != 0 {
            userSwipedDirection = x > 0 ? .backwards : .forwards
        }

        // Handle Y-axis scroll
        if y != 0 {
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

    func handleScrollEnd() {
        scrollEventFinished = true
        delegate?.gestureView(didSwipe: userSwipedDirection)
        userSwipedDirection = nil
    }

    override func mouseDown(with event: NSEvent) {
        popover.show(relativeTo: self.bounds, of: self, preferredEdge: .minY)
        delegate?.gestureViewMouseDown()
    }
}
