//
//  AXSidebarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXSidebarView: NSView, AXTabHostingViewProtocol, AXGestureViewDelegate {
    private var hasDrawn: Bool = false
    var delegate: (any AXTabHostingViewDelegate)?

    var tabGroupInfoView: AXTabGroupInfoView = AXTabGroupInfoView()
    var searchButton: AXSidebarSearchButton = AXSidebarSearchButton()
    lazy var gestureView = AXGestureView(
        tabGroupInfoView: tabGroupInfoView, searchButton: searchButton)

    var mouseExitedTrackingArea: NSTrackingArea!

    override var tag: Int {
        return 0x01
    }

    private lazy var bottomLine: NSBox = {
        let line = NSBox()
        line.boxType = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }()

    private lazy var addNewTabButton: NSButton = {
        let button = NSButton(
            image: NSImage(named: NSImage.addTemplateName)!, target: self,
            action: #selector(addNewTab))
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    private lazy var workspaceSwapperButton: NSButton = {
        let button = NSButton(
            image: NSImage(
                systemSymbolName: "rectangle.stack",
                accessibilityDescription: nil)!, target: self,
            action: #selector(showWorkspaceSwapper))
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    // This standalone view is needed for the NSWindow to access its delegate
    lazy var workspaceSwapperView: AXWorkspaceSwapperView = {
        return AXWorkspaceSwapperView()
    }()

    lazy var workspaceSwapperPopoverView: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .transient

        let controller = NSViewController()
        controller.view = workspaceSwapperView
        popover.contentViewController = controller

        return popover
    }()

    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }

        // Gesture View
        gestureView.translatesAutoresizingMaskIntoConstraints = false
        gestureView.delegate = self
        addSubview(gestureView)
        NSLayoutConstraint.activate([
            gestureView.topAnchor.constraint(equalTo: topAnchor),
            gestureView.leftAnchor.constraint(equalTo: leftAnchor),
            gestureView.rightAnchor.constraint(
                equalTo: rightAnchor, constant: 3),
            gestureView.heightAnchor.constraint(equalToConstant: 80),
        ])

        tabGroupInfoView.onRightMouseDown =
            delegate?.tabHostingViewDisplaysTabGroupCustomizationPanel

        // Divider between Search Bar and Tab
        addSubview(bottomLine)
        NSLayoutConstraint.activate([
            bottomLine.topAnchor.constraint(
                equalTo: gestureView.bottomAnchor, constant: 5),
            bottomLine.leftAnchor.constraint(equalTo: leftAnchor, constant: 12),
            bottomLine.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -10),
            bottomLine.heightAnchor.constraint(equalToConstant: 1),
        ])

        addSubview(addNewTabButton)
        NSLayoutConstraint.activate([
            addNewTabButton.bottomAnchor.constraint(
                equalTo: bottomAnchor, constant: -9),
            addNewTabButton.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -10),
            addNewTabButton.heightAnchor.constraint(equalToConstant: 30),
            addNewTabButton.widthAnchor.constraint(equalToConstant: 30),
        ])

        addSubview(workspaceSwapperButton)
        NSLayoutConstraint.activate([
            workspaceSwapperButton.bottomAnchor.constraint(
                equalTo: bottomAnchor, constant: -9),
            workspaceSwapperButton.leftAnchor.constraint(
                equalTo: leftAnchor, constant: 10),
            workspaceSwapperButton.heightAnchor.constraint(equalToConstant: 30),
            workspaceSwapperButton.widthAnchor.constraint(equalToConstant: 30),
        ])

        // AXTabBarView

        // Mouse Tracking Area
        mouseExitedTrackingArea = NSTrackingArea(
            rect: .init(
                x: bounds.origin.x + 1, y: bounds.origin.y,
                width: bounds.size.width + 100, height: bounds.size.height),
            options: [.activeAlways, .mouseEnteredAndExited], owner: self)
        addTrackingArea(mouseExitedTrackingArea)
    }

    // MARK: - Tab Bar Functions
    func insertTabBarView(tabBarView: AXTabBarViewTemplate) {
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabBarView)
        NSLayoutConstraint.activate([
            tabBarView.topAnchor.constraint(
                equalTo: topAnchor, constant: 86),
            tabBarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabBarView.bottomAnchor.constraint(
                equalTo: bottomAnchor, constant: -49),
        ])
    }

    // MARK: - Mouse Functions
    override func mouseExited(with event: NSEvent) {
        guard let window = self.window as? AXWindow, window.hiddenSidebarView
        else { return }

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.1
                self.animator().frame.origin.x = -bounds.width
            },
            completionHandler: {
                self.layer?.backgroundColor = .none
                self.removeFromSuperview()
            })
    }

    override func viewDidEndLiveResize() {
        removeTrackingArea(mouseExitedTrackingArea)
        mouseExitedTrackingArea = NSTrackingArea(
            rect: .init(
                x: bounds.origin.x - 100, y: bounds.origin.y,
                width: bounds.size.width + 100, height: bounds.size.height),
            options: [.activeAlways, .mouseEnteredAndExited], owner: self)
        addTrackingArea(mouseExitedTrackingArea)
    }

    @objc func addNewTab() {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }

        appDelegate.toggleSearchBarForNewTab(nil)
    }

    @objc func showWorkspaceSwapper() {
        delegate?.tabHostingViewDisplaysWorkspaceSwapperPanel()
    }

    func gestureView(didSwipe direction: AXGestureViewSwipeDirection!) {
        switch direction {
        case .backwards:
            delegate?.tabHostingViewNavigateBackwards()
        case .forwards:
            delegate?.tabHostingViewNavigateForward()
        case .reload:
            delegate?.tabHostingViewReloadCurrentPage()
        case .nothing, nil:
            break
        }
    }
}
