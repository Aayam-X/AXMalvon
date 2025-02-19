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
                                AXGestureViewDelegate, AXTabBarViewDelegate
{
    func tabBarSwitchedTo(_ tabButton: any AXTabButton) {
        tabHostingDelegate?.tabBarSwitchedTo(tabButton)
    }
    
    func tabBarShouldClose(_ tabButton: any AXTabButton) -> Bool {
        return tabHostingDelegate?.tabBarShouldClose(tabButton) ?? true
    }
    
    func tabBarDidClose(_ tabAt: Int) {
        tabHostingDelegate?.tabBarDidClose(tabAt)
    }
    
    internal var tabBarView: any AXTabBarViewTemplate
    weak var tabHostingDelegate: (any AXTabHostingViewDelegate)?

    var tabGroupInfoView: AXTabGroupInfoView
    internal var searchButton: AXSidebarSearchButton
    private var gestureView: AXGestureView

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

    private lazy var helloWorldExtensionButton: NSButton = {
        let buttonImage = NSImage(
            systemSymbolName: "doc", accessibilityDescription: nil)!
        let button = NSButton(
            image: buttonImage, target: self,
            action: #selector(helloWorldExtensionButtonAction))
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
        self.wantsLayer = true
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        tabBarView.delegate = self
        gestureView.delegate = self
        tabGroupInfoView.onRightMouseDown = showTabGroupCustomizer

        gestureView.translatesAutoresizingMaskIntoConstraints = false
        tabBarView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(gestureView)
        addSubview(addNewTabButton)
        addSubview(workspaceSwapperButton)
        addSubview(helloWorldExtensionButton)
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

        // Workspace Swapper Button
        helloWorldExtensionButton.activateConstraints([
            .bottom: .view(self, constant: -9),
            .leftRight: .view(workspaceSwapperButton, constant: 2),
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
    }

    // MARK: - Mouse Functions
    @objc
    func addNewTab() {
        tabHostingDelegate?.tabHostingViewCreatedNewTab()
    }

    @objc
    func showWorkspaceSwapper() {
        tabHostingDelegate?.tabHostingViewDisplaysWorkspaceSwapperPanel(
            workspaceSwapperButton)
    }

    var buttonPressCount: Int = 0
    var helloWorldExtension: CRXExtension?
    @objc
    func helloWorldExtensionButtonAction() {
        if let helloWorldExtension = helloWorldExtension {
            // NSPopover with AXWebView
            guard let popupURL = helloWorldExtension.popupURL else { return }

            let popover = NSPopover()
            popover.contentSize = NSSize(width: 400, height: 300)  // Adjust size as needed
            popover.behavior = .semitransient
            popover.contentViewController = ExtensionPopupController(
                popupURL: popupURL)

            // Show the popover
            popover.show(
                relativeTo: helloWorldExtensionButton.bounds,
                of: helloWorldExtensionButton, preferredEdge: .maxY)

            // FIXME: Next Steps, run the `popup.js` script.
        } else {
            helloWorldExtension = CRXExtension(extensionName: "Hello-World")
            print(helloWorldExtension?.manifest as Any)
        }

        class ExtensionPopupController: NSViewController {
            var webView: AXWebView!

            init(popupURL: URL) {
                super.init(nibName: nil, bundle: nil)
                self.webView = AXWebView(frame: .zero)
                self.webView.configuration.enableDefaultMalvonPreferences()
                self.webView.loadFileURL(
                    popupURL,
                    allowingReadAccessTo: popupURL.deletingLastPathComponent())
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            override func loadView() {
                self.view = webView
            }
        }
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
