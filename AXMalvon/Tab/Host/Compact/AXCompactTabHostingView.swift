//
//  AXCompactTabHostingView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//

import AppKit

class AXCompactTabHostingView: NSView, AXTabHostingViewProtocol {
    var delegate: (any AXTabHostingViewDelegate)?
    private var hasDrawn: Bool = false

    private weak var stickyTab: AXTabButton?

    // Control views
    internal lazy var tabGroupInfoView: AXTabGroupInfoView = {
        let view = AXTabGroupInfoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var backButton: NSButton = {
        let button = NSButton(
            image: NSImage(named: NSImage.goLeftTemplateName)!, target: self,
            action: #selector(didTapBackButton))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var forwardButton: NSButton = {
        let button = NSButton(
            image: NSImage(named: NSImage.goRightTemplateName)!, target: self,
            action: #selector(didTapForwardButton))
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    internal lazy var searchButton: AXSidebarSearchButton = {
        let button = AXSidebarSearchButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.target = self
        button.action = #selector(searchButtonTapped)
        return button
    }()

    // Cache frequently accessed views
    private lazy var controlsStackView: NSStackView = {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var contentContainer: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Use a single function to create sticky tabs with shared configuration
    private func createConfiguredStickyTab() -> AXCompactTabButton {
        let view = AXCompactTabButton(tab: nil)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        view.layer?.shadowColor = NSColor.black.cgColor
        view.layer?.shadowOpacity = 0.3
        view.layer?.shadowRadius = 10

        return view
    }

    private lazy var leftStickyTab: AXCompactTabButton =
        createConfiguredStickyTab()
    private lazy var rightStickyTab: AXCompactTabButton =
        createConfiguredStickyTab()

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        // Control Stack View
        for view in [tabGroupInfoView, backButton, forwardButton, searchButton]
        {
            controlsStackView.addArrangedSubview(view)
        }

        // Set fixed constraints
        NSLayoutConstraint.activate([
            searchButton.widthAnchor.constraint(equalToConstant: 300),
            tabGroupInfoView.widthAnchor.constraint(equalToConstant: 80),
        ])

        // Add subviews in correct z-order
        addSubview(contentContainer)
        addSubview(controlsStackView)
        addSubview(
            leftStickyTab, positioned: .above, relativeTo: contentContainer)
        addSubview(
            rightStickyTab, positioned: .above, relativeTo: contentContainer)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            controlsStackView.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 8),
            controlsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            contentContainer.leadingAnchor.constraint(
                equalTo: controlsStackView.trailingAnchor, constant: 8),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            leftStickyTab.leadingAnchor.constraint(
                equalTo: controlsStackView.trailingAnchor, constant: 5),
            leftStickyTab.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftStickyTab.widthAnchor.constraint(equalToConstant: 90),

            rightStickyTab.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightStickyTab.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightStickyTab.widthAnchor.constraint(equalToConstant: 90),
        ])
    }

    private func createStickyTab() -> AXCompactTabButton {
        let view = AXCompactTabButton(tab: nil)
        view.layer?.zPosition = 1000
        return view
    }

    func insertTabBarView(tabBarView: any AXTabBarViewTemplate) {
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(tabBarView)

        NSLayoutConstraint.activate([
            tabBarView.leadingAnchor.constraint(
                equalTo: contentContainer.leadingAnchor),
            tabBarView.trailingAnchor.constraint(
                equalTo: contentContainer.trailingAnchor),
            tabBarView.topAnchor.constraint(
                equalTo: contentContainer.topAnchor),
            tabBarView.bottomAnchor.constraint(
                equalTo: contentContainer.bottomAnchor),
        ])

        if let tabBarView = tabBarView as? AXCompactTabBarView {
            tabBarView.stickyDelegate = self
        }
    }
}

extension AXCompactTabHostingView: AXCompactTabBarViewDelegate {
    func tabBarShouldMakeTabSticky(
        _ tab: AXTabButton, position: TabStickyPosition
    ) {
        self.stickyTab = tab

        // Reset both tabs first
        leftStickyTab.isHidden = true
        rightStickyTab.isHidden = true

        // Configure the appropriate sticky tab
        let stickyTab = position == .left ? leftStickyTab : rightStickyTab
        stickyTab.isHidden = false
        stickyTab.tab = tab.tab
        stickyTab.webTitle = tab.webTitle
        stickyTab.favicon = tab.favicon
        stickyTab.tag = tab.tag
        stickyTab.isSelected = true
        stickyTab.startObserving()
    }

    func tabBarShouldRemoveSticky() {
        leftStickyTab.isHidden = true
        rightStickyTab.isHidden = true
        [leftStickyTab, rightStickyTab].forEach { $0.tab = nil }

        stickyTab?.startObserving()
    }

    func tabBarRemovedTab() {
        leftStickyTab.isHidden = true
        rightStickyTab.isHidden = true
        [leftStickyTab, rightStickyTab].forEach { $0.tab = nil }
    }

    @objc func didTapBackButton() {
        delegate?.tabHostingViewNavigateBackwards()
    }
    @objc func didTapForwardButton() {
        delegate?.tabHostingViewNavigateForward()
    }

    @objc private func searchButtonTapped() {
        guard let window = window as? AXWindow else { return }
        let searchBar = AppDelegate.searchBar
        searchBar.parentWindow1 = window
        searchBar.searchBarDelegate = window

        if let buttonFrameInScreen = searchButton.superview.map({
            window.convertToScreen($0.convert(searchButton.frame, to: nil))
        }) {
            searchBar.showCurrentURL(
                at: NSPoint(
                    x: buttonFrameInScreen.origin.x,
                    y: buttonFrameInScreen.origin.y - searchBar.frame.height
                ))
        }
    }
}
