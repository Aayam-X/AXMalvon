//
//  AXHorizontalTabBarView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-08.
//

import AppKit

private let tabBarHeight = 30.0
private let tabBarWidth = 120.0

class AXHorizontalTabBarView: NSView, AXTabBarViewTemplate {

    var tabGroup: AXTabGroup!
    var delegate: (any AXTabBarViewDelegate)?

    private var hasDrawn = false

    var tabStackView = NSStackView()
    private lazy var scrollView = AXScrollView(frame: self.bounds)

    private lazy var plusButton: NSButton = {
        let button = NSButton()
        button.title = "+"
        button.bezelStyle = .texturedRounded
        button.target = self
        button.action = #selector(plusButtonTapped)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewWillDraw() {
        guard !hasDrawn else { return }
        defer { hasDrawn = true }

        configure()
    }

    func configure() {
        wantsLayer = true

        self.scrollView.drawsBackground = false
        self.scrollView.hasHorizontalScroller = false
        self.scrollView.hasVerticalScroller = false
        self.scrollView.usesPredominantAxisScrolling = true
        self.scrollView.horizontalScrollElasticity = .allowed
        self.scrollView.verticalScrollElasticity = .none
        self.scrollView.autoresizingMask = [.width, .height]
        self.scrollView.translatesAutoresizingMaskIntoConstraints = true
        self.scrollView.automaticallyAdjustsContentInsets = false

        addSubview(scrollView)
        addSubview(plusButton)

        scrollView.documentView = tabStackView
        tabStackView.frame = scrollView.bounds

        // Configure stack view constraints
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabStackView.topAnchor.constraint(
                equalTo: scrollView.contentView.topAnchor),
            tabStackView.bottomAnchor.constraint(
                equalTo: scrollView.contentView.bottomAnchor),
            tabStackView.leadingAnchor.constraint(
                equalTo: scrollView.contentView.leadingAnchor),
        ])

        tabStackView.orientation = .horizontal
        tabStackView.distribution = .fillProportionally
        tabStackView.alignment = .centerY
        tabStackView.spacing = 6
        tabStackView.edgeInsets = .init(top: 0, left: 16, bottom: 0, right: 6)

        // Configure plus button constraints
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            plusButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            plusButton.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -6),
            plusButton.heightAnchor.constraint(equalToConstant: 16),
            plusButton.widthAnchor.constraint(equalToConstant: 16),
        ])
    }

    func addTabButton(for tab: AXTab) {
        let button = AXNormalTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        let newIndex = tabGroup.tabs.count - 1
        button.tag = newIndex

        let previousIndex = tabGroup.selectedIndex
        tabGroup.selectedIndex = newIndex

        addButtonToTabView(button)

        updateTabSelection(from: previousIndex, to: newIndex)
        delegate?.tabBarSwitchedTo(tabAt: newIndex)
    }

    func removeTabButton(at index: Int) {
        let button = tabStackView.arrangedSubviews[index] as! AXTabButton

        // FIXME: Animations
        button.removeFromSuperview()

        // Update indices and layout the stack view
        self.updateIndices(after: index)
        self.tabStackView.layoutSubtreeIfNeeded()
    }

    func addTabButtonInBackground(for tab: AXTab, index: Int) {
        let button = AXNormalTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        button.tag = index
        button.webTitle = tab.title

        addButtonToTabViewWithoutAnimation(button)
        button.startObserving()
    }

    func updateIndices(after index: Int) {
        for (index, button) in tabStackView.arrangedSubviews.enumerated()
            .dropFirst(index)
        {
            mxPrint("NEW DELETATION INDEX = \(index)")
            if let button = button as? AXNormalTabButton {
                button.tag = index
            }
        }

        updateSelectedItemIndex(after: index)
    }

    func updateTabSelection(from: Int, to: Int) {
        let arragedSubviews = tabStackView.arrangedSubviews
        let arrangedSubviewsCount = arragedSubviews.count

        guard arrangedSubviewsCount > to else { return }

        if from >= 0 && from < arrangedSubviewsCount {
            let previousButton =
                arragedSubviews[from] as! AXNormalTabButton
            previousButton.isSelected = false
        }

        let newButton = arragedSubviews[to] as! AXNormalTabButton
        newButton.isSelected = true

        delegate?.tabBarSwitchedTo(tabAt: to)
    }

    func tabButtonDidSelect(_ tabButton: any AXTabButton) {
        let previousTag = tabGroup.selectedIndex

        let newTag = tabButton.tag
        tabGroup.selectedIndex = newTag

        // Update the active tab
        updateTabSelection(from: previousTag, to: newTag)
    }

    func tabButtonWillClose(_ tabButton: any AXTabButton) {
        let index = tabButton.tag

        // Remove the tab from the group
        tabGroup.tabs.remove(at: index)
        tabButton.removeFromSuperview()

        mxPrint("DELETED TAB COUNT", tabGroup.tabs.count)

        // Update indices of tabs after the removed one
        self.updateIndices(after: index)
    }

    func tabButtonActiveTitleChanged(
        _ newTitle: String, for tabButton: any AXTabButton
    ) {
        delegate?.tabBarActiveTabTitleChanged(to: newTitle)
    }

    func tabButtonDeactivatedWebView(_ tabButton: any AXTabButton) {
        let tab = tabGroup.tabs[tabButton.tag]

        if tab.webConfiguration == nil {
            tab.webConfiguration = delegate?.tabBarDeactivatedTab()
        }
    }

    private func addButtonToTabView(_ button: AXNormalTabButton) {
        // FIXME: Animations
        // Add the button off-screen by modifying its frame
        tabStackView.addArrangedSubview(button)
        button.widthAnchor.constraint(equalToConstant: 250).isActive = true
    }

    private func addButtonToTabViewWithoutAnimation(_ button: AXNormalTabButton)
    {
        // Add the button off-screen by modifying its frame
        tabStackView.addArrangedSubview(button)
        button.widthAnchor.constraint(equalToConstant: 250).isActive = true
    }

    private func updateSelectedItemIndex(after index: Int) {
        // Handle when there are no more tabs left
        if tabGroup.tabs.isEmpty {
            mxPrint("No tabs left")
            tabGroup.selectedIndex = -1
            delegate?.tabBarSwitchedTo(tabAt: -1)
            return
        }

        // If index is out of bounds, select the last tab
        let tabCountIndex = tabGroup.tabs.count - 1

        if index > tabCountIndex && (tabGroup.selectedIndex >= index) {
            tabGroup.selectedIndex = tabCountIndex
        } else if tabGroup.selectedIndex >= index {
            tabGroup.selectedIndex = max(0, tabGroup.selectedIndex - 1)
        } else { /* if tabGroup.selectedIndex < index */
            // Do nothing
        }

        mxPrint("Updated Tab Index: \(tabGroup.selectedIndex)")
        (tabStackView.arrangedSubviews[tabGroup.selectedIndex]
            as! AXNormalTabButton)
            .isSelected = true

        delegate?.tabBarSwitchedTo(tabAt: tabGroup.selectedIndex)
    }

    @objc func plusButtonTapped() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.toggleSearchBarForNewTab(nil)
        }
    }
}
