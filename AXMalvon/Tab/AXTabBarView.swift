//
//  AXTabBarView.swift
//  AXTabSystem
//
//  Created by Ashwin Paudel on 2024-11-14.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

protocol AXTabBarViewDelegate: AnyObject {
    func tabBarSwitchedTo(tabAt: Int)
    func activeTabTitleChanged(to: String)
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
        box.heightAnchor.constraint(equalToConstant: 35).isActive = true
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
        tabStackView.spacing = 1.08
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

    func removeTab(at: Int) {
        let button = tabStackView.arrangedSubviews[at] as! AXTabButton

        button.stopObserving()
        button.removeFromSuperview()

        updateIndicies(after: at)
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
        tabStackView.addArrangedSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(
                equalTo: tabStackView.leadingAnchor, constant: 5),
            button.trailingAnchor.constraint(
                equalTo: tabStackView.trailingAnchor, constant: -5),
        ])
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
            return false
        }

        reorderTabs(from: tag, to: dragTargetIndex)
        print("Not concluded")
        return true
    }

    override func concludeDragOperation(_ sender: (any NSDraggingInfo)?) {
        // Remove the divider after the drag operation is concluded
        //divider.removeFromSuperview()
        dragTargetIndex = nil
        print("Drag operation concluded")
    }
}

// MARK: - Tab Button Delegate
extension AXTabBarView: AXTabButtonDelegate {
    func tabButtonDeactivatedWebView(_ tabButton: AXTabButton) {
        let tab = tabGroup.tabs[tabButton.tag]

        if tab.webConfiguration == nil {
            // FIXME: Get the profile's web configuration
            // This doesn't work if the tab was created locally; works only when tab is created by JSON tab group file
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
        if index >= tabGroup.tabs.count
            && tabGroup.selectedIndex >= tabGroup.tabs.count
        {
            tabGroup.selectedIndex = tabGroup.tabs.count - 1
        } else /* if tabGroup.selectedIndex < index */
        {
            // Do nothing
        }

        (tabStackView.arrangedSubviews[tabGroup.selectedIndex] as! AXTabButton)
            .isSelected = true

        delegate?.tabBarSwitchedTo(tabAt: tabGroup.selectedIndex)
    }
}

final class AXFlippedClipView: NSClipView {
    override var isFlipped: Bool {
        return true
    }
}
