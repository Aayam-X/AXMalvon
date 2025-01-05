//
//  AXVerticalTabHostingView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXVerticalTabHostingView: NSView, AXTabHostingViewProtocol,
    AXGestureViewDelegate
{
    var tabBarView: any AXTabBarViewTemplate
    var tabHostingDelegate: (any AXTabHostingViewDelegate)?

    var tabGroupInfoView: AXTabGroupInfoView
    var searchButton: AXSidebarSearchButton
    var gestureView: AXGestureView

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
        let buttonImage = NSImage(
            systemSymbolName: "rectangle.stack", accessibilityDescription: nil)!
        let button = NSButton(
            image: buttonImage, target: self,
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

    required init(
        tabBarView: any AXTabBarViewTemplate,
        searchButton: AXSidebarSearchButton,
        tabGroupInfoView: AXTabGroupInfoView
    ) {
        self.tabBarView = tabBarView
        self.tabGroupInfoView = tabGroupInfoView
        self.searchButton = searchButton
        self.gestureView = AXGestureView(
            tabGroupInfoView: tabGroupInfoView, searchButton: searchButton)

        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        gestureView.delegate = self
        tabGroupInfoView.onRightMouseDown = showTabGroupCustomizer

        gestureView.translatesAutoresizingMaskIntoConstraints = false
        tabBarView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(gestureView)
        addSubview(addNewTabButton)
        addSubview(workspaceSwapperButton)
        addSubview(tabBarView)
        addSubview(bottomLine)

        gestureView.activateConstraints([
            .top: .view(self),
            .left: .view(self),
            .right: .view(self, constant: 2),
            .height: .constant(80),
        ])

        bottomLine.activateConstraints([
            .horizontalEdges: .view(self),
            .bottom: .view(gestureView, constant: 10),
            .height: .constant(2),
        ])

        // Tab Bar View
        tabBarView.activateConstraints([
            .left: .view(self),
            .right: .view(self, constant: -2),
            .top: .view(bottomLine, constant: 8),
            .bottom: .view(addNewTabButton, constant: -2),
        ])

        // Workspace Swapper Button
        workspaceSwapperButton.activateConstraints([
            .bottom: .view(self, constant: -9),
            .left: .view(self, constant: 10),
            .height: .constant(30),
            .width: .constant(30),
        ])

        // New Tab Button
        addNewTabButton.activateConstraints([
            .right: .view(self, constant: -10),
            .bottom: .view(self, constant: -9),
            .height: .constant(30),
            .width: .constant(30),
        ])

        // Mouse Tracking Area
        mouseExitedTrackingArea = NSTrackingArea(
            rect: .init(
                x: bounds.origin.x + 1, y: bounds.origin.y,
                width: bounds.size.width + 100, height: bounds.size.height),
            options: [.activeAlways, .mouseEnteredAndExited], owner: self)
        addTrackingArea(mouseExitedTrackingArea)
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

    @objc
    func addNewTab() {
        guard let window = self.window as? AXWindow else { return }

        window.toggleSearchBarForNewTab(nil)
    }

    @objc
    func showWorkspaceSwapper() {
        tabHostingDelegate?.tabHostingViewDisplaysWorkspaceSwapperPanel(
            workspaceSwapperButton)
    }

    func showTabGroupCustomizer() {
        tabHostingDelegate?.tabHostingViewDisplaysTabGroupCustomizationPanel(
            tabGroupInfoView)
    }

    func gestureView(didSwipe direction: AXGestureViewSwipeDirection!) {
        switch direction {
        case .backwards:
            tabHostingDelegate?.tabHostingViewNavigateBackwards()
        case .forwards:
            tabHostingDelegate?.tabHostingViewNavigateForward()
        case .reload:
            tabHostingDelegate?.tabHostingViewReloadCurrentPage()
        case .nothing, nil:
            break
        }
    }
}
