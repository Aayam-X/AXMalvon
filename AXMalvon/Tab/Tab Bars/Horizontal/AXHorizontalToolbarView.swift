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
}

class AXHorizontalToolbarView: NSView {
    private var hasDrawn: Bool = false
    var delegate: AXHorizontalToolbarViewDelegate?

    private lazy var backButton: NSButton = {
        let image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: "Go Back")!
        let button = NSButton(image: image, target: self, action: #selector(backButtonAction))
        button.bezelStyle = .texturedRounded
        button.toolTip = "Go Back"
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        return button
    }()

    private lazy var forwardButton: NSButton = {
        let image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: "Go Forward")!
        let button = NSButton(image: image, target: self, action: #selector(forwardButtonAction))
        button.bezelStyle = .texturedRounded
        button.toolTip = "Go Forward"
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
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
    
    lazy var workspaceSwapperPopoverView: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .transient

        let controller = NSViewController()
        controller.view = workspaceSwapperView
        popover.contentViewController = controller

        return popover
    }()
    
    // This standalone view is needed for the NSWindow to access its delegate
    lazy var workspaceSwapperView: AXWorkspaceSwapperView = {
        return AXWorkspaceSwapperView()
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
        addSubview(workspaceSwapperButton)
        addSubview(bottomDivider)

        // Layout subviews
        topDivider.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        searchField.translatesAutoresizingMaskIntoConstraints = false
        workspaceSwapperButton.translatesAutoresizingMaskIntoConstraints = false
        bottomDivider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Top divider constraints
            topDivider.topAnchor.constraint(equalTo: topAnchor),
            topDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            topDivider.heightAnchor.constraint(equalToConstant: 1),

            // Back button constraints
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            // Forward button constraints
            forwardButton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            forwardButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            forwardButton.widthAnchor.constraint(equalToConstant: 40),
            forwardButton.heightAnchor.constraint(equalToConstant: 40),

            // Search field constraints
            searchField.leftAnchor.constraint(equalTo: forwardButton.rightAnchor, constant: 16),
            searchField.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchField.rightAnchor.constraint(equalTo: workspaceSwapperButton.leftAnchor, constant: -16),
            
            workspaceSwapperButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -16),
            workspaceSwapperButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Bottom divider constraints
            bottomDivider.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomDivider.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        searchField.target = self
        searchField.action = #selector(searchButtonTapped)
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
            relativeTo: workspaceSwapperButton.bounds,
            of: workspaceSwapperButton, preferredEdge: .minY)
    }
}
