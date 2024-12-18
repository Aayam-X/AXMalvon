//
//  AXHorizontalToolbarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-14.
//

import AppKit

protocol AXHorizontalToolbarViewDelegate: AnyObject {
    func didTapBackButton()
    func didTapForwardButton()

    func requestsCurrentTabGroup() -> AXTabGroup
}

class AXHorizontalToolbarView: NSView {
    private var hasDrawn: Bool = false
    var delegate: AXHorizontalToolbarViewDelegate?

    private lazy var backButton: NSButton = {
        let image = NSImage(
            systemSymbolName: "chevron.left",
            accessibilityDescription: "Go Back")!
        let button = NSButton(
            image: image, target: self, action: #selector(backButtonAction))
        button.bezelStyle = .texturedRounded
        button.toolTip = "Go Back"
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        return button
    }()

    private lazy var forwardButton: NSButton = {
        let image = NSImage(
            systemSymbolName: "chevron.right",
            accessibilityDescription: "Go Forward")!
        let button = NSButton(
            image: image, target: self, action: #selector(forwardButtonAction))
        button.bezelStyle = .texturedRounded
        button.toolTip = "Go Forward"
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        return button
    }()

    lazy var tabGroupInfoView: AXTabGroupInfoView = {
        let button = AXTabGroupInfoView()
        button.onLeftMouseDown = showWorkspaceSwapper
        button.onRightMouseDown = showTabGroupInfoView

        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(lessThanOrEqualToConstant: 150).isActive =
            true
        button.heightAnchor.constraint(equalToConstant: 16).isActive = true

        return button
    }()

    lazy var workspaceSwapperPopoverView: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .transient

        let controller = NSViewController()
        controller.view = workspaceSwapperView
        popover.contentViewController = controller

        return popover
    }()

    lazy var tabGroupInfoPopoverView: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .transient
        let vc = NSViewController()
        vc.view = tabGroupCustomizerView
        popover.contentViewController = vc

        popover.show(relativeTo: bounds, of: self, preferredEdge: .maxX)

        return popover
    }()

    // This standalone view is needed for the NSWindow to access its delegate
    lazy var workspaceSwapperView: AXWorkspaceSwapperView = {
        let view = AXWorkspaceSwapperView()

        return view
    }()

    lazy var tabGroupCustomizerView: AXTabGroupCustomizerView! = {
        guard let tabGroup = delegate?.requestsCurrentTabGroup() else {
            return nil
        }
        return AXTabGroupCustomizerView(tabGroup: tabGroup)
    }()

    lazy var searchField = AXSidebarSearchButton()

    private lazy var topDivider: NSBox = {
        let divider = NSBox()
        divider.boxType = .separator
        return divider
    }()

    private lazy var bottomDivider: NSBox = {
        let divider = NSBox()
        divider.boxType = .separator
        return divider
    }()

    override func viewWillDraw() {
        guard !hasDrawn else { return }
        defer { hasDrawn = true }

        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        setupSubviews()
    }

    private func setupSubviews() {
        // Add subviews
        addSubview(topDivider)
        addSubview(backButton)
        addSubview(forwardButton)
        addSubview(searchField)
        addSubview(tabGroupInfoView)
        addSubview(bottomDivider)

        // Layout subviews
        topDivider.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        searchField.translatesAutoresizingMaskIntoConstraints = false
        tabGroupInfoView.translatesAutoresizingMaskIntoConstraints = false
        bottomDivider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Top divider constraints
            topDivider.topAnchor.constraint(equalTo: topAnchor),
            topDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            topDivider.heightAnchor.constraint(equalToConstant: 1),

            // Back button constraints
            backButton.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            // Forward button constraints
            forwardButton.leadingAnchor.constraint(
                equalTo: backButton.trailingAnchor, constant: 8),
            forwardButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            forwardButton.widthAnchor.constraint(equalToConstant: 40),
            forwardButton.heightAnchor.constraint(equalToConstant: 40),

            // Search field constraints
            searchField.leftAnchor.constraint(
                equalTo: forwardButton.rightAnchor, constant: 16),
            searchField.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchField.rightAnchor.constraint(
                equalTo: tabGroupInfoView.leftAnchor, constant: -10),

            tabGroupInfoView.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -16),
            tabGroupInfoView.centerYAnchor.constraint(
                equalTo: centerYAnchor, constant: -3),

            // Bottom divider constraints
            bottomDivider.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomDivider.heightAnchor.constraint(equalToConstant: 1),
        ])

        searchField.target = self
        searchField.action = #selector(searchButtonTapped)

        wantsLayer = true
        layer?.backgroundColor =
            NSColor.textBackgroundColor.withAlphaComponent(0.3).cgColor
    }

    override func viewDidEndLiveResize() {
        searchField.addressField.preferredMaxLayoutWidth = self.frame.width - 32
    }

    @objc func searchButtonTapped() {
        guard let window = self.window as? AXWindow else { return }
        let searchBar = AppDelegate.searchBar

        searchBar.parentWindow1 = window
        searchBar.searchBarDelegate = window

        // Convert the button's frame to the screen coordinate system
        if let buttonSuperview = searchField.superview {
            let buttonFrameInWindow = buttonSuperview.convert(
                searchField.frame, to: nil)
            let buttonFrameInScreen = window.convertToScreen(
                buttonFrameInWindow)

            // Calculate the point just below the search button
            let pointBelowButton = NSPoint(
                x: buttonFrameInScreen.origin.x,
                y: buttonFrameInScreen.origin.y - searchBar.frame.height)  // Adjust height of search bar

            searchBar.showCurrentURL(at: pointBelowButton)
        }
    }

    @objc func backButtonAction(_ sender: Any?) {
        delegate?.didTapBackButton()
    }

    @objc func forwardButtonAction(_ sender: Any?) {
        delegate?.didTapForwardButton()
    }

    @objc func showWorkspaceSwapper() {
        workspaceSwapperView.reloadTabGroups()

        workspaceSwapperPopoverView.show(
            relativeTo: tabGroupInfoView.bounds,
            of: tabGroupInfoView, preferredEdge: .minY)
    }

    @objc func showTabGroupInfoView() {
        tabGroupInfoPopoverView.show(
            relativeTo: tabGroupInfoView.bounds, of: tabGroupInfoView,
            preferredEdge: .minY)
    }
}
