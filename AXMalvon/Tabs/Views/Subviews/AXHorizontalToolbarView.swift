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
    var delegate: AXHorizontalToolbarViewDelegate?

    var tabGroupInfoView: AXTabGroupInfoView
    var searchButton: AXSidebarSearchButton

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

    init(
        tabGroupInfoView: AXTabGroupInfoView,
        searchButton: AXSidebarSearchButton
    ) {
        self.tabGroupInfoView = tabGroupInfoView
        self.searchButton = searchButton
        super.init(frame: .zero)

        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Add subviews
        addSubview(topDivider)
        addSubview(backButton)
        addSubview(forwardButton)
        addSubview(searchButton)
        addSubview(tabGroupInfoView)
        addSubview(bottomDivider)

        // Layout subviews
        topDivider.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        tabGroupInfoView.translatesAutoresizingMaskIntoConstraints = false
        bottomDivider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Top divider constraints
            topDivider.topAnchor.constraint(equalTo: topAnchor),
            topDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            topDivider.heightAnchor.constraint(equalToConstant: 1),

            // Tab group information view
            tabGroupInfoView.widthAnchor.constraint(
                lessThanOrEqualToConstant: 150),
            tabGroupInfoView.leftAnchor.constraint(
                equalTo: leftAnchor, constant: 8),
            tabGroupInfoView.centerYAnchor.constraint(
                equalTo: centerYAnchor, constant: -3),

            // Back button constraints
            backButton.leftAnchor.constraint(
                equalTo: tabGroupInfoView.rightAnchor, constant: 8),
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
            searchButton.leftAnchor.constraint(
                equalTo: forwardButton.rightAnchor, constant: 16),
            searchButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchButton.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -16),

            // Bottom divider constraints
            bottomDivider.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomDivider.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomDivider.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomDivider.heightAnchor.constraint(equalToConstant: 1),
        ])

        searchButton.target = self
        searchButton.action = #selector(searchButtonTapped)

        wantsLayer = true
        layer?.backgroundColor =
            NSColor.textBackgroundColor.withAlphaComponent(0.3).cgColor
    }

    override func viewDidEndLiveResize() {
        searchButton.addressField.preferredMaxLayoutWidth =
            self.frame.width - 32
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

    @objc func backButtonAction(_ sender: Any?) {
        delegate?.didTapBackButton()
    }

    @objc func forwardButtonAction(_ sender: Any?) {
        delegate?.didTapForwardButton()
    }
}
