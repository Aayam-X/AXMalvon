//
//  AXTabBarView.swift
//  AXTabSystem
//
//  Created by Ashwin Paudel on 2024-11-14.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

// swiftlint:disable force_cast
class AXVerticalTabBarView: NSView, AXTabBarViewTemplate {
    var tabGroup: AXTabGroup
    var delegate: (any AXTabBarViewDelegate)?

    var previousTabIndex: Int = -1

    private var dragTargetIndex: Int?

    // Views
    var tabStackView = NSStackView()
    var clipView = AXFlippedClipView()
    var scrollView: AXScrollView!

    lazy var divider: NSBox = {
        let box = NSBox()
        box.boxType = .custom
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: 33).isActive = true
        box.fillColor = NSColor.controlAccentColor
        return box
    }()

    required init(tabGroup: AXTabGroup) {
        self.tabGroup = tabGroup
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        // Remove autoresizing mask constraints
        self.translatesAutoresizingMaskIntoConstraints = false

        // Configure stack view
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        tabStackView.orientation = .vertical
        tabStackView.spacing = 5
        tabStackView.detachesHiddenViews = true
        tabStackView.edgeInsets = .init(top: 3, left: 0, bottom: 3, right: 0)

        // Configure scroll view
        scrollView = AXScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        addSubview(scrollView)

        // Configure clip view
        clipView.translatesAutoresizingMaskIntoConstraints = false
        clipView.drawsBackground = false
        scrollView.contentView = clipView

        // Set document view
        scrollView.documentView = tabStackView

        // IMPORTANT: Set hugging and compression resistance
        tabStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tabStackView.setContentCompressionResistancePriority(
            .defaultLow, for: .horizontal)

        // Core layout constraints
        NSLayoutConstraint.activate([
            // Scroll view fills the entire view
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Stack view dimensions
            tabStackView.leadingAnchor.constraint(
                equalTo: clipView.leadingAnchor),
            tabStackView.trailingAnchor.constraint(
                equalTo: clipView.trailingAnchor),
            tabStackView.topAnchor.constraint(equalTo: clipView.topAnchor),
            // Don't constrain the bottom - let it grow as needed

            // Ensure stack view matches clip view width
            //tabStackView.widthAnchor.constraint(equalTo: clipView.widthAnchor)
        ])
    }

    func addTabButton(for tab: AXTab) {
        let button = AXVerticalTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        let newIndex = tabGroup.tabs.count - 1
        button.tag = newIndex

        let previousIndex = tabGroup.selectedIndex
        tabGroup.selectedIndex = newIndex

        delegate?.tabBarSwitchedTo(tabAt: newIndex)

        addButtonToTabView(button)
        button.startObserving()

        updateTabSelection(from: previousIndex, to: newIndex)
    }

    func addTabButtonInBackground(for tab: AXTab, index: Int) {
        let button = AXVerticalTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        button.tag = index
        button.webTitle = tab.title

        addButtonToTabView(button)
        button.startObserving()
        button.favicon = tab.icon
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
        updateIndices(after: index)
    }

    func removeTabButton(at index: Int) {
        let button = tabStackView.arrangedSubviews[index] as! AXTabButton

        // Calculate the off-screen position for the slide animation
        let finalPosition = button.frame.offsetBy(
            dx: 0, dy: +button.frame.height)

        // Create the slide animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.05
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)

            // Slide the button down underneath the stack view
            button.animator().setFrameOrigin(finalPosition.origin)
            button.animator().alphaValue = 0  // Fade out as it slides
        } completionHandler: {
            // Remove the button after the animation completes
            button.removeFromSuperview()

            // Update indices and layout the stack view
            self.updateIndices(after: index)
            self.tabStackView.layoutSubtreeIfNeeded()
        }
    }

    func updateTabGroup(_ newTabGroup: AXTabGroup) {
        newTabGroup.tabBarView = self

        // Clear existing buttons
        for button in self.tabStackView.arrangedSubviews {
            button.removeFromSuperview()
        }

        // Update tab group
        self.tabGroup = newTabGroup
        newTabGroup.tabBarView = self

        // Add tab buttons
        for (index, tab) in newTabGroup.tabs.enumerated() {
            self.addTabButtonInBackground(for: tab, index: index)
        }

        guard newTabGroup.selectedIndex != -1 else { return }
        self.updateTabSelection(from: -1, to: newTabGroup.selectedIndex)
    }

    func tabButtonActiveTitleChanged(
        _ newTitle: String, for tabButton: AXTabButton
    ) {
        delegate?.tabBarActiveTabTitleChanged(to: newTitle)
    }

    func tabButtonDeactivatedWebView(_ tabButton: AXTabButton) {
        //  _ = tabGroup.tabs[tabButton.tag]

        //        if tab.webConfiguration == nil {
        //            tab.webConfiguration = delegate?.tabBarDeactivatedTab()
        //        }
    }

    func updateIndices(after index: Int) {
        for case let (index, button as AXTabButton) in tabStackView
            .arrangedSubviews.enumerated().dropFirst(index)
        {
            mxPrint("DELETATION START INDEX = \(index)")
            button.tag = index
        }

        updateSelectedItemIndex(after: index)
    }

    private func updateSelectedItemIndex(after index: Int) {
        // Handle when there are no more tabs left
        if tabGroup.tabs.isEmpty {
            mxPrint("No tabs left")
            tabGroup.selectedIndex = -1
            previousTabIndex = -1
            delegate?.tabBarSwitchedTo(tabAt: -1)
            return
        }

        // If index is out of bounds, select the last tab
        if tabGroup.selectedIndex == index {
            // If the removed tab was selected, select the next tab or the last one
            tabGroup.selectedIndex = min(
                previousTabIndex, tabGroup.tabs.count - 1)
        } else if tabGroup.selectedIndex > index {
            // If a tab before the selected one is removed, shift the selected index
            tabGroup.selectedIndex -= 1
        }

        mxPrint("Updated Tab Index: \(tabGroup.selectedIndex)")

        if let button = tabStackView.arrangedSubviews[tabGroup.selectedIndex]
            as? AXVerticalTabButton
        {
            button.isSelected = true
        }

        delegate?.tabBarSwitchedTo(tabAt: tabGroup.selectedIndex)
    }

    func updateTabSelection(from: Int, to index: Int) {
        self.previousTabIndex = from
        mxPrint(#function, "Previous Tab Index \(previousTabIndex)")

        let arragedSubviews = tabStackView.arrangedSubviews
        let arrangedSubviewsCount = arragedSubviews.count

        guard arrangedSubviewsCount > index else { return }

        if from >= 0 && from < arrangedSubviewsCount {
            let previousButton =
                arragedSubviews[from] as! AXTabButton
            previousButton.isSelected = false
        }

        let newButton = arragedSubviews[index] as! AXTabButton
        newButton.isSelected = true

        delegate?.tabBarSwitchedTo(tabAt: index)
    }

    private func addButtonToTabView(_ button: NSView) {
        // Add the button off-screen by modifying its frame
        button.translatesAutoresizingMaskIntoConstraints = false

        // Configure button layout priorities
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(
            .defaultLow, for: .horizontal)

        tabStackView.addArrangedSubview(button)

        NSLayoutConstraint.activate([
            // Only constrain the horizontal margins
            button.leadingAnchor.constraint(
                equalTo: tabStackView.leadingAnchor, constant: 5),
            button.trailingAnchor.constraint(
                equalTo: tabStackView.trailingAnchor, constant: -3),
        ])

        // Layout the stack view to update frames
        layoutSubtreeIfNeeded()

        guard let lastSubview = tabStackView.arrangedSubviews.last else {
            return
        }

        // Set the initial off-screen position for the animation
        button.frame.origin.y = lastSubview.frame.maxY
        button.alphaValue = 0.0  // Optional: Start fully transparent

        // Perform the animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.05  // Animation duration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)

            button.animator().frame.origin.y = 0  // Slide to its final position
            button.animator().alphaValue = 1.0  // Optional: Fade in
        }
    }

    private func addButtonToTabViewWithoutAnimation(_ button: NSView) {
        // Add the button off-screen by modifying its frame
        button.translatesAutoresizingMaskIntoConstraints = false

        // Configure button layout priorities
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(
            .defaultLow, for: .horizontal)

        tabStackView.addArrangedSubview(button)

        NSLayoutConstraint.activate([
            // Only constrain the horizontal margins
            button.leadingAnchor.constraint(
                equalTo: tabStackView.leadingAnchor, constant: 5),
            button.trailingAnchor.constraint(
                equalTo: tabStackView.trailingAnchor, constant: -3),
        ])
    }
}

extension AXVerticalTabBarView {
    private func reorderTabs(from: Int, toIndex: Int) {
        mxPrint("Reordering tabs from \(from) to \(toIndex)")

        let firstButton = tabStackView.arrangedSubviews[from] as! AXTabButton
        let secondButton =
            tabStackView.arrangedSubviews[toIndex] as! AXTabButton

        firstButton.tag = toIndex
        secondButton.tag = from

        tabStackView.removeArrangedSubview(firstButton)
        tabStackView.insertArrangedSubview(firstButton, at: toIndex)
        tabStackView.insertArrangedSubview(secondButton, at: from)

        firstButton.isHidden = false

        self.tabGroup.tabs.swapAt(from, toIndex)
        tabGroup.selectedIndex = toIndex
        self.updateIndices(after: min(from, toIndex))
    }
}

class AXScrollView: NSScrollView {
    override var isFlipped: Bool { true }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        documentView?.needsLayout = true
    }
}

final class AXFlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}

// swiftlint:enable force_cast
