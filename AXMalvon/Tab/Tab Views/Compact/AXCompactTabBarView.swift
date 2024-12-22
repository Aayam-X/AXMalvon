//
//  AXCompactTabBarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//

import AppKit

enum TabStickyPosition {
    case left
    case right
    case none
}

protocol AXCompactTabBarViewDelegate: AnyObject {
    // Sticky tab behavior
    func tabBarShouldMakeTabSticky(
        _ tab: AXTabButton, position: TabStickyPosition)
    func tabBarShouldRemoveSticky()

    func tabBarRemovedTab()
}

// Note: This class will only have the scrollable tabs; not the search bar. That will be implemented in the hosting view.
class AXCompactTabBarView: NSView, AXTabBarViewTemplate {
    var tabGroup: AXTabGroup!
    var delegate: (any AXTabBarViewDelegate)?
    var stickyDelegate: (any AXCompactTabBarViewDelegate)?

    private let minTabWidth: CGFloat = 90
    private let maxTabWidth: CGFloat = 250
    private var widthOfCurrentBounds: CGFloat = 0
    private var lastTabCount: Int = 0

    internal lazy var tabStackView = NSStackView()

    private lazy var scrollView: AXScrollView = {
        let scroll = AXScrollView(frame: self.bounds)
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = false
        scroll.usesPredominantAxisScrolling = true
        scroll.horizontalScrollElasticity = .allowed
        scroll.verticalScrollElasticity = .none
        scroll.autoresizingMask = [.width, .height]
        scroll.translatesAutoresizingMaskIntoConstraints = true
        scroll.automaticallyAdjustsContentInsets = false
        return scroll
    }()

    private var tabWidthConstraints: [NSLayoutConstraint] = []
    private var currentStickyState: TabStickyPosition = .none
    private var lastScrollPosition: CGFloat = 0
    private var firstTabInitialFrame: CGRect?

    init() {
        super.init(frame: .zero)
        configure()
        widthOfCurrentBounds = bounds.width
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        // Only update if bounds width or tab count has changed so that would stop unnesesary code being ran.
        // To be honest, viewDidEnd resize would have been better but I think real time constraint updating looks better
        let currentWidth = bounds.width
        let currentTabCount = tabStackView.arrangedSubviews.count

        if currentWidth != widthOfCurrentBounds
            || currentTabCount != lastTabCount
        {
            super.layout()
            updateTabWidths()
            updateStickyTabs()

            widthOfCurrentBounds = currentWidth
            lastTabCount = currentTabCount
        }
    }

    func configure() {
        wantsLayer = true

        // Set up scroll view notifications with debouncing
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidScroll),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        addSubview(scrollView)
        scrollView.documentView = tabStackView
        setupTabStackView()

        // Delaying the initial scrolls kinda makes it look better idk how to explain
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.81) { [weak self] in
            self?.scrollToTab(at: self?.tabGroup.selectedIndex ?? 0)
        }
    }

    private func setupTabStackView() {
        tabStackView.frame = scrollView.bounds
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
    }

    @objc private func scrollViewDidScroll(_ notification: Notification) {
        // You could use a dispatch worker so that it uses less CPU while scrolling
        // But the transition between sticky to non-sticky wouldn't look smooth and there would be a delay.
        updateStickyTabs()
    }

    func addTabButton(for tab: AXTab) {
        let button = AXCompactTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        let newIndex = tabGroup.tabs.count - 1
        button.tag = newIndex

        let previousIndex = tabGroup.selectedIndex
        tabGroup.selectedIndex = newIndex

        // Slides in from the left and then goes to the right
        addButtonToTabView(button)
        button.alphaValue = 0
        button.frame.origin.x = tabStackView.frame.width

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            button.animator().frame.origin.x = 0  // Slide to its final position
            button.animator().alphaValue = 1
        }) {
            self.scrollToTab(at: newIndex)
        }

        updateTabSelection(from: previousIndex, to: newIndex)
        delegate?.tabBarSwitchedTo(tabAt: newIndex)
    }

    func removeTabButton(at index: Int) {
        let button = tabStackView.arrangedSubviews[index] as! AXTabButton
        self.updateIndices(after: index)
        tabWidthConstraints.remove(at: index)

        // Slides in from the right and then goes to the left, underneath the stackView making it look like it's going kinda inwards
        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(
                    name: .easeInEaseOut)
                button.animator().frame.origin.x =
                    button.frame.origin.x - button.frame.width  // Slide out to the left
                button.animator().alphaValue = 0
            },
            completionHandler: {
                button.removeFromSuperview()

                // Animate width changes for remaining tabs
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.2
                    context.timingFunction = CAMediaTimingFunction(
                        name: .easeInEaseOut)
                    self.updateTabWidths()
                    self.tabStackView.layoutSubtreeIfNeeded()
                })
            })

        stickyDelegate?.tabBarRemovedTab()
    }

    // When the user first launches the app and it needs to display the tabs from the user defaults.
    func addTabButtonInBackground(for tab: AXTab, index: Int) {
        let button = AXCompactTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        button.tag = index
        button.webTitle = tab.title

        addButtonToTabView(button)
        button.startObserving()
    }

    // Each button has a tag, it updates the position of it
    // Called when you close a tab
    func updateIndices(after index: Int) {
        for (index, button) in tabStackView.arrangedSubviews.enumerated()
            .dropFirst(index)
        {
            mxPrint("DELETATION START INDEX = \(index)")
            if let button = button as? AXTabButton {
                button.tag = index
            }
        }

        updateSelectedItemIndex(after: index)
    }

    // Changes the highlighted/selected tab
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

        stickyDelegate?.tabBarShouldRemoveSticky()
        scrollToTab(at: to)
    }

    func tabButtonDidSelect(_ tabButton: AXTabButton) {
        let previousTag = tabGroup.selectedIndex

        let newTag = tabButton.tag
        tabGroup.selectedIndex = newTag

        // Update the active tab
        updateTabSelection(from: previousTag, to: newTag)

        scrollToTab(at: newTag)
        scrollView.layoutSubtreeIfNeeded()
    }

    // Maybe a better name, called when the user presses X on the tab.
    func tabButtonWillClose(_ tabButton: AXTabButton) {
        let index = tabButton.tag

        // Remove the tab from the group
        tabGroup.tabs.remove(at: index)
        tabButton.removeFromSuperview()

        mxPrint("DELETED TAB COUNT", tabGroup.tabs.count)

        // Update indices of tabs after the removed one
        self.updateIndices(after: index)
    }

    private func addButtonToTabView(_ button: AXTabButton) {
        tabStackView.addArrangedSubview(button)

        let availableWidth = bounds.width - 45
        let tabCount = CGFloat(tabStackView.arrangedSubviews.count)

        let idealWidth = min(maxTabWidth, availableWidth / tabCount)
        let finalWidth = max(minTabWidth, idealWidth)

        let newWidthConstraint = button.widthAnchor.constraint(
            equalToConstant: finalWidth)
        newWidthConstraint.isActive = true

        for constraint in tabWidthConstraints {
            constraint.constant = finalWidth
        }

        tabWidthConstraints.append(newWidthConstraint)

        // Reset initial frames when adding new tabs
        firstTabInitialFrame = nil
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

    func scrollToTab(at index: Int) {
        guard index >= 0, index < tabStackView.arrangedSubviews.count else {
            return
        }

        // Get the position of the tab to scroll to
        let tabView = tabStackView.arrangedSubviews[index]

        // Calculate the target point to center the tab in the scroll view
        let targetPointX =
            tabView.frame.origin.x + (tabView.frame.size.width / 2)
            - (scrollView.frame.size.width / 2)
        let targetPoint = NSPoint(x: targetPointX, y: 0)

        // Animate the scrolling
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.5
        let clipView = self.scrollView.contentView
        clipView.animator().setBoundsOrigin(targetPoint)
        self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
        NSAnimationContext.endGrouping()
    }

    // This function determines the index of where the selectedTab should be
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

        // Sticky Tab stuff
        stickyDelegate?.tabBarShouldRemoveSticky()
        updateTabWidths()
        scrollToTab(at: tabGroup.selectedIndex)
    }
}

// MARK: - Sticky Tab Functions
extension AXCompactTabBarView {
    private func updateStickyTabs() {
        guard !tabGroup.tabs.isEmpty,
            let currentTab = tabStackView.arrangedSubviews[
                tabGroup.selectedIndex] as? AXTabButton
        else { return }

        let scrollPosition = scrollView.documentVisibleRect.origin.x
        let visibleWidth = scrollView.documentVisibleRect.width
        let maxVisiblePosition = scrollPosition + visibleWidth

        // Only update frame cache if needed
        if firstTabInitialFrame == nil
            || currentTab.frame != firstTabInitialFrame
        {
            firstTabInitialFrame = currentTab.frame
        }

        // Calculate sticky state efficiently
        let shouldBeSticky: TabStickyPosition
        if scrollPosition > 0 && currentTab.frame.minX < scrollPosition {
            shouldBeSticky = .left
        } else if let documentView = scrollView.documentView,
            maxVisiblePosition < documentView.frame.width
                && currentTab.frame.maxX > maxVisiblePosition
        {
            shouldBeSticky = .right
        } else {
            shouldBeSticky = .none
        }

        // Only notify delegate if state changed
        if shouldBeSticky != currentStickyState {
            if shouldBeSticky == .none {
                stickyDelegate?.tabBarShouldRemoveSticky()
            } else if let firstWidthConstraint = tabWidthConstraints.first,
                firstWidthConstraint.constant == minTabWidth
            {
                stickyDelegate?.tabBarShouldMakeTabSticky(
                    currentTab, position: shouldBeSticky)
            }
            currentStickyState = shouldBeSticky
        }

        lastScrollPosition = scrollPosition
    }

    private func updateTabWidths() {
        let availableWidth = bounds.width - 55
        let tabCount = CGFloat(tabStackView.arrangedSubviews.count)

        guard tabCount > 0 else { return }

        // Calculate the ideal width for each tab
        let idealWidth = min(maxTabWidth, availableWidth / tabCount)
        let finalWidth = max(minTabWidth, idealWidth)

        for constraint in tabWidthConstraints {
            constraint.animator().constant = finalWidth
        }

        let usesHorizontalScroller: Bool = idealWidth <= 90
        scrollView.horizontalScrollElasticity =
            usesHorizontalScroller ? .allowed : .none
    }
}
