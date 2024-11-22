//
//  AXTabBarView.swift
//  AXTabSystem
//
//  Created by Ashwin Paudel on 2024-11-14.
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

    // Views
    var tabStackView = NSStackView()
    var scrollView: NSScrollView!
    let clipView = AXFlippedClipView()

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
        tabStackView.detachesHiddenViews = false

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
