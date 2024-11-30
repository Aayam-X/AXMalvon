//
//  AXTabBarView.swift
//  AXTabSystem
//
//  Created by Ashwin Paudel on 2024-11-14.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

protocol AXTabBarViewDelegate: AnyObject {
    func tabBarSwitchedTo(tabAt: Int)
    func activeTabTitleChanged(to: String)

    /// Return a WKWebViewConfiguration when the user deactivates a self-created web view
    func deactivatedTab() -> WKWebViewConfiguration?
}

class AXTabBarView: NSView {
    var tabGroup: AXTabGroup
    weak var delegate: AXTabBarViewDelegate?
    private var hasDrawn = false
    private var dragTargetIndex: Int?

    // Views
    var tabStackView = NSStackView()
    var scrollView: NSScrollView!
    let clipView = AXFlippedClipView()

    lazy var divider: NSBox = {
        let box = NSBox()
        box.boxType = .custom
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: 36).isActive = true
        box.fillColor = NSColor.controlAccentColor
        return box
    }()

    init(tabGroup: AXTabGroup) {
        self.tabGroup = tabGroup
        super.init(frame: .zero)
    }

    override func viewWillDraw() {
        guard !hasDrawn else { return }
        defer { hasDrawn = true }

        self.translatesAutoresizingMaskIntoConstraints = false

        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        tabStackView.orientation = .vertical
        tabStackView.spacing = 5
        tabStackView.detachesHiddenViews = true

        // Create scrollView
        scrollView = NSScrollView()
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Tab Functions
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

    func removeTab(at index: Int) {
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
            self.updateIndicies(after: index)
            self.tabStackView.layoutSubtreeIfNeeded()
        }
    }

    func addTabButton(for tab: AXTab, index: Int) {
        let button = AXTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        let newIndex = index
        button.tag = newIndex
        button.webTitle = tab.title

        tabGroup.selectedIndex = newIndex

        addButtonToTabView(button)
        button.startObserving()
    }

    func updateIndicies(after: Int) {
        for (index, button) in tabStackView.arrangedSubviews.enumerated()
            .dropFirst(after)
        {
            print("NEW DELETATION INDEX = \(index)")
            if let button = button as? AXTabButton {
                button.tag = index
            }
        }

        updateSelectedItemIndex(after: after)
    }

    func updateTabSelection(from: Int, to: Int) {
        guard tabStackView.arrangedSubviews.count > to else { return }

        if from >= 0 && from < tabStackView.arrangedSubviews.count {
            let previousButton =
                tabStackView.arrangedSubviews[from] as! AXTabButton
            previousButton.isSelected = false
        }

        let newButton = tabStackView.arrangedSubviews[to] as! AXTabButton
        newButton.isSelected = true

        delegate?.tabBarSwitchedTo(tabAt: to)
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

    private func reorderTabs(from: Int, to: Int) {
        print("Reordering tabs from \(from) to \(to)")

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
        self.updateIndicies(after: min(from, to))
    }
}

// MARK: - Tab Button Delegate
extension AXTabBarView: AXTabButtonDelegate {
    func tabButtonDeactivatedWebView(_ tabButton: AXTabButton) {
        let tab = tabGroup.tabs[tabButton.tag]

        if tab.webConfiguration == nil {
            tab.webConfiguration = delegate?.deactivatedTab()
        }

        tab._webView?.removeFromSuperview()
        tab._webView = nil
    }

    func tabButtonActiveTitleChanged(
        _ newTitle: String, for tabButton: AXTabButton
    ) {
        delegate?.activeTabTitleChanged(to: newTitle)
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
        tabButton.stopObserving()
        tabButton.removeFromSuperview()

        print("DELETED TAB COUNT", tabGroup.tabs.count)

        // Update indices of tabs after the removed one
        updateIndicies(after: index)
    }

    private func updateSelectedItemIndex(after index: Int) {
        // Handle when there are no more tabs left
        if tabGroup.tabs.isEmpty {
            print("No tabs left")
            tabGroup.selectedIndex = -1
            delegate?.tabBarSwitchedTo(tabAt: -1)
            return
        }

        // If index is out of bounds, select the last tab
        let tabCount = tabGroup.tabs.count
        let tabCountIndex = tabGroup.tabs.count - 1

        if index >= tabCount || tabGroup.selectedIndex >= tabCountIndex {
            tabGroup.selectedIndex = tabCountIndex
        } else /* if tabGroup.selectedIndex < index */
        {
            // Do nothing
        }

        print("Updated Tab Index: \(tabGroup.selectedIndex)")
        (tabStackView.arrangedSubviews[tabGroup.selectedIndex] as! AXTabButton)
            .isSelected = true

        delegate?.tabBarSwitchedTo(tabAt: tabGroup.selectedIndex)
    }
}

// MARK: - Dragging Destination
extension AXTabBarView {
    override var registeredDraggedTypes: [NSPasteboard.PasteboardType] {
        [.axTabButton]
    }

    override func draggingEntered(_ sender: any NSDraggingInfo)
        -> NSDragOperation
    {
        let pasteboard = sender.draggingPasteboard

        if pasteboard.types!.contains(.axTabButton) {
            return .generic
        }

        return []
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo)
        -> NSDragOperation
    {
        let location = sender.draggingLocation
        let stackViewLocation = convert(location, to: tabStackView)

        // Remove the divider if it already exists in the stack view
        divider.removeFromSuperview()

        // Calculate the insertion index based on cursor's location
        let index =
            tabStackView.arrangedSubviews.firstIndex {
                stackViewLocation.y > $0.frame.minY
            } ?? tabStackView.arrangedSubviews.count - 1

        // Insert the divider at the calculated index
        tabStackView.insertArrangedSubview(divider, at: index)

        // Adjust the frame of the divider to align with the cursor
        divider.frame.origin.y = stackViewLocation.y - divider.frame.height / 2

        dragTargetIndex = index
        return .generic
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        divider.removeFromSuperview()
        guard
            let pasteboard = sender.draggingPasteboard.propertyList(
                forType: .axTabButton) as? String, let tag = Int(pasteboard),
            let dragTargetIndex
        else {
            print("Not concluded")
            return false
        }

        reorderTabs(from: tag, to: dragTargetIndex)
        return true
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        guard let sender else { return }
        _ = performDragOperation(sender)
    }

    override func concludeDragOperation(_ sender: (any NSDraggingInfo)?) {
        // Remove the divider after the drag operation is concluded
        //divider.removeFromSuperview()
        dragTargetIndex = nil
        print("Drag operation concluded")
    }
}

final class AXFlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}
