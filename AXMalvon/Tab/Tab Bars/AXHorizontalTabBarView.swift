//
//  AXHorizontalTabBarView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-08.
//

import Cocoa

private let tabBarHeight = 30.0
private let tabBarWidth = 120.0

final class FlippedView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}

class AXHorizontalTabBarView: NSView, AXTabBarViewTemplate {
    var tabGroup: AXTabGroup!
    var delegate: (any AXTabBarViewDelegate)?

    private var hasDrawn = false

    private let tabStackView = NSStackView()
    private let scrollView = NSScrollView()
    private let containerView = FlippedView()

    override func viewWillDraw() {
        guard !hasDrawn else { return }
        defer { hasDrawn = true }

        configure()
    }

    func configure() {
        wantsLayer = true

        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = false
        scrollView.hasVerticalRuler = false
        scrollView.drawsBackground = false
        scrollView.verticalScrollElasticity = .none

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        containerView.drawsBackground = false
        scrollView.contentView = containerView
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            containerView.rightAnchor.constraint(
                equalTo: scrollView.rightAnchor),
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor),
        ])

        scrollView.documentView = tabStackView
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabStackView.leftAnchor.constraint(
                equalTo: containerView.leftAnchor),
            tabStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            tabStackView.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor),
        ])

        tabStackView.orientation = .horizontal
        tabStackView.distribution = .gravityAreas
        tabStackView.alignment = .centerY
        tabStackView.spacing = 0.5
    }

    func addTabButton(for tab: AXTab) {
        let button = AXTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        let newIndex = tabGroup.tabs.count - 1
        button.tag = newIndex

        let previousIndex = tabGroup.selectedIndex
        tabGroup.selectedIndex = newIndex

        addButtonToTabView(button)
        button.startObserving()

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
        let button = AXTabButton(tab: tab)
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
            if let button = button as? AXTabButton {
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
                arragedSubviews[from] as! AXTabButton
            previousButton.isSelected = false
        }

        let newButton = arragedSubviews[to] as! AXTabButton
        newButton.isSelected = true

        delegate?.tabBarSwitchedTo(tabAt: to)
    }

    func tabButtonDidSelect(_ tabButton: AXTabButton) {
        let previousTag = tabGroup.selectedIndex

        let newTag = tabButton.tag
        tabGroup.selectedIndex = newTag

        // Update the active tab
        updateTabSelection(from: previousTag, to: newTag)
    }

    func tabButtonWillClose(_ tabButton: AXTabButton) {
        let index = tabButton.tag

        // Remove the tab from the group
        tabGroup.tabs.remove(at: index)
        tabButton.removeFromSuperview()

        mxPrint("DELETED TAB COUNT", tabGroup.tabs.count)

        // Update indices of tabs after the removed one
        self.updateIndices(after: index)
    }

    func tabButtonActiveTitleChanged(
        _ newTitle: String, for tabButton: AXTabButton
    ) {
        delegate?.activeTabTitleChanged(to: newTitle)
    }

    func tabButtonDeactivatedWebView(_ tabButton: AXTabButton) {
        let tab = tabGroup.tabs[tabButton.tag]

        if tab.webConfiguration == nil {
            tab.webConfiguration = delegate?.deactivatedTab()
        }
    }

    private func addButtonToTabView(_ button: AXTabButton) {
        // FIXME: Animations
        // Add the button off-screen by modifying its frame
        tabStackView.addArrangedSubview(button)
        button.widthAnchor.constraint(equalToConstant: 250).isActive = true

        // Layout the stack view to update frames
        layoutSubtreeIfNeeded()
    }

    private func addButtonToTabViewWithoutAnimation(_ button: AXTabButton) {
        // Add the button off-screen by modifying its frame
        tabStackView.addArrangedSubview(button)
        button.widthAnchor.constraint(equalToConstant: 250).isActive = true

        layoutSubtreeIfNeeded()
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
        (tabStackView.arrangedSubviews[tabGroup.selectedIndex] as! AXTabButton)
            .isSelected = true

        delegate?.tabBarSwitchedTo(tabAt: tabGroup.selectedIndex)
    }

    func updateTabGroup(_ newTabGroup: AXTabGroup) {
        newTabGroup.tabBarView = self

        // Clear existing buttons
        for button in self.tabStackView.arrangedSubviews {
            button.removeFromSuperview()
        }

        // Update tab group
        self.tabGroup = newTabGroup
        //newTabGroup.tabBarView = self

        // Add tab buttons
        for (index, tab) in newTabGroup.tabs.enumerated() {
            addTabButtonInBackground(for: tab, index: index)
        }

        guard newTabGroup.selectedIndex != -1 else { return }
        self.updateTabSelection(from: -1, to: newTabGroup.selectedIndex)
    }
}
