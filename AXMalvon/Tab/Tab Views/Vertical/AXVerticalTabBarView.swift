//
//  AXTabBarView.swift
//  AXTabSystem
//
//  Created by Ashwin Paudel on 2024-11-14.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXVerticalTabBarView: NSView, AXTabBarViewTemplate {
    var tabGroup: AXTabGroup!
    var delegate: (any AXTabBarViewDelegate)?

    private var dragTargetIndex: Int?

    // Views
    var tabStackView = NSStackView()
    var scrollView: AXScrollView!
    let clipView = AXFlippedClipView()

    lazy var divider: NSBox = {
        let box = NSBox()
        box.boxType = .custom
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: 36).isActive = true
        box.fillColor = NSColor.controlAccentColor
        return box
    }()

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.translatesAutoresizingMaskIntoConstraints = false

        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        tabStackView.orientation = .vertical
        tabStackView.spacing = 5
        tabStackView.detachesHiddenViews = true

        // Create scrollView
        scrollView = AXScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.drawsBackground = false

        // Setup clipview
        clipView.translatesAutoresizingMaskIntoConstraints = false
        clipView.drawsBackground = false
        scrollView.contentView = clipView

        // Setup stackView
        scrollView.documentView = tabStackView

        NSLayoutConstraint.activate([
            scrollView.leftAnchor.constraint(equalTo: leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: rightAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),

            clipView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            clipView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            clipView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            clipView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            tabStackView.topAnchor.constraint(equalTo: topAnchor),
            tabStackView.leftAnchor.constraint(equalTo: clipView.leftAnchor),
            tabStackView.rightAnchor.constraint(equalTo: clipView.rightAnchor),
        ])

        registerForDraggedTypes(self.registeredDraggedTypes)
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
        button.startObserving()

        updateTabSelection(from: previousIndex, to: newIndex)
        delegate?.tabBarSwitchedTo(tabAt: newIndex)
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

    func addTabButtonInBackground(for tab: AXTab, index: Int) {
        let button = AXNormalTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        button.tag = index
        button.webTitle = tab.title

        addButtonToTabView(button)
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

    func tabButtonActiveTitleChanged(
        _ newTitle: String, for tabButton: AXTabButton
    ) {
        delegate?.tabBarActiveTabTitleChanged(to: newTitle)
    }

    func tabButtonDeactivatedWebView(_ tabButton: AXTabButton) {
        let tab = tabGroup.tabs[tabButton.tag]

        if tab.webConfiguration == nil {
            tab.webConfiguration = delegate?.tabBarDeactivatedTab()
        }
    }

    private func addButtonToTabView(_ button: NSView) {
        // Add the button off-screen by modifying its frame
        button.translatesAutoresizingMaskIntoConstraints = false
        tabStackView.addArrangedSubview(button)

        NSLayoutConstraint.activate([
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
        tabStackView.addArrangedSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(
                equalTo: tabStackView.leadingAnchor, constant: 5),
            button.trailingAnchor.constraint(
                equalTo: tabStackView.trailingAnchor, constant: -3),
        ])
    }

    private func reorderTabs(from: Int, to: Int) {
        mxPrint("Reordering tabs from \(from) to \(to)")

        let firstButton = tabStackView.arrangedSubviews[from] as! AXTabButton
        let secondButton = tabStackView.arrangedSubviews[to] as! AXTabButton

        firstButton.tag = to
        secondButton.tag = from

        tabStackView.removeArrangedSubview(firstButton)
        tabStackView.insertArrangedSubview(firstButton, at: to)
        tabStackView.insertArrangedSubview(secondButton, at: from)

        firstButton.isHidden = false

        self.tabGroup.tabs.swapAt(from, to)
        tabGroup.selectedIndex = to
        self.updateIndices(after: min(from, to))
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
}

class AXScrollView: NSScrollView {
    //    override func scrollWheel(with event: NSEvent) {
    //        // Minimal scroll handling to reduce CPU usage
    //        guard event.deltaY != 0 else { return }
    //        super.scrollWheel(with: event)
    //    }
}

final class AXFlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}
