//
//  AXCompactTabHostingView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//

import AppKit

// The hosting view contains the tabView along with the search field, web navigation buttons and the workspace swapper view
class AXCompactTabHostingView: NSView, AXTabHostingViewProtocol {
    var tabBarView: any AXTabBarViewTemplate
    var delegate: (any AXTabHostingViewDelegate)?

    // The tab that is being stickied.
    private weak var stickyTab: AXTabButton?

    internal lazy var tabGroupInfoView: AXTabGroupInfoView = {
        let view = AXTabGroupInfoView()
        view.onLeftMouseDown = tabGroupInfoViewLeftDown
        view.onRightMouseDown = tabGroupInfoViewRightDown
        return view
    }()

    internal lazy var searchButton: AXSidebarSearchButton = {
        let button = AXSidebarSearchButton()
        button.target = self
        button.action = #selector(searchButtonTapped)
        return button
    }()

    private lazy var browserNavigationStackView: AXGestureStackView = {
        let stackView = AXGestureStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.distribution = .gravityAreas
        stackView.spacing = 3
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.gestureDelegate = self
        return stackView
    }()

    private lazy var leftStickyTab: AXCompactTabButton =
        createConfiguredStickyTab()
    private lazy var rightStickyTab: AXCompactTabButton =
        createConfiguredStickyTab()

    required init(tabBarView: any AXTabBarViewTemplate) {
        self.tabBarView = tabBarView
        super.init(frame: .zero)
        setupViews()
    }

    private func setupViews() {
        for view in [tabGroupInfoView, searchButton] {
            browserNavigationStackView.addArrangedSubview(view)
        }

        // Add subviews in correct z-order
        addSubview(tabBarView)
        addSubview(browserNavigationStackView)
        addSubview(
            leftStickyTab, positioned: .above, relativeTo: tabBarView)
        addSubview(
            rightStickyTab, positioned: .above, relativeTo: tabBarView)

        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        tabBarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            browserNavigationStackView.leadingAnchor.constraint(
                equalTo: leadingAnchor),
            browserNavigationStackView.centerYAnchor.constraint(
                equalTo: centerYAnchor),
            browserNavigationStackView.trailingAnchor.constraint(
                equalTo: tabBarView.leadingAnchor),

            tabBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabBarView.topAnchor.constraint(equalTo: topAnchor),
            tabBarView.bottomAnchor.constraint(equalTo: bottomAnchor),

            leftStickyTab.leadingAnchor.constraint(
                equalTo: browserNavigationStackView.trailingAnchor, constant: 5),
            leftStickyTab.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftStickyTab.widthAnchor.constraint(equalToConstant: 90),

            rightStickyTab.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightStickyTab.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightStickyTab.widthAnchor.constraint(equalToConstant: 90),

            searchButton.widthAnchor.constraint(
                equalTo: self.widthAnchor, multiplier: 0.25),
            searchButton.heightAnchor.constraint(equalToConstant: 30),
            tabGroupInfoView.widthAnchor.constraint(equalToConstant: 150),
        ])

        if let tabBarView = tabBarView as? AXCompactTabBarView {
            tabBarView.stickyDelegate = self
        }
    }

    func tabGroupInfoViewLeftDown() {
        delegate?.tabHostingViewDisplaysWorkspaceSwapperPanel(tabGroupInfoView)
    }

    func tabGroupInfoViewRightDown() {
        delegate?.tabHostingViewDisplaysTabGroupCustomizationPanel(
            tabGroupInfoView)
    }

    @objc func didTapBackButton() {
        delegate?.tabHostingViewNavigateBackwards()
    }
    @objc func didTapForwardButton() {
        delegate?.tabHostingViewNavigateForward()
    }

    // FIXME: AXWindow should be handling this method
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

// MARK: - Sticky Tab Methods
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

    // Use a single function to create sticky tabs with shared configuration
    private func createConfiguredStickyTab() -> AXCompactTabButton {
        let view = AXCompactTabButton(tab: nil)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        view.layer?.shadowColor = NSColor.black.cgColor
        view.layer?.shadowOpacity = 0.3
        view.layer?.shadowRadius = 10

        view.isHidden = true

        return view
    }
}

extension AXCompactTabHostingView: AXGestureViewDelegate {
    func gestureView(didSwipe direction: AXGestureViewSwipeDirection!) {
        switch direction {
        case .backwards:
            delegate?.tabHostingViewNavigateBackwards()
        case .reload:
            delegate?.tabHostingViewReloadCurrentPage()
        case .forwards:
            delegate?.tabHostingViewNavigateForward()
        case .nothing, .none:
            break
        }
    }
}
