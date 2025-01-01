//
//  AXHorizontalTabBarView.swift
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

protocol AXHorizontalTabBarViewDelegate: AnyObject {
    // Sticky tab behavior
    func tabBarShouldMakeTabSticky(
        _ tab: AXTabButton, position: TabStickyPosition)
    func tabBarShouldRemoveSticky()

    func tabBarRemovedTab()
}

// This class will only have the scrollable tabs; not the search bar nor sticky tabs
// That will be implemented in the hosting view.
class AXHorizontalTabBarView: NSView, AXTabBarViewTemplate {
    var tabGroup: AXTabGroup
    weak var delegate: (any AXTabBarViewDelegate)?
    weak var stickyDelegate: (any AXHorizontalTabBarViewDelegate)?

    private let minTabWidth: CGFloat = 90
    private let maxTabWidth: CGFloat = 250
    private var currentWidth: CGFloat = 0
    private var currentTabCount: Int = 0

    // Store constraints with their associated buttons for better management
    private var tabConstraints: [AXHorizontalTabButton: NSLayoutConstraint] = [:]
    private var currentStickyState: TabStickyPosition = .none
    private var lastScrollPosition: CGFloat = 0
    private var firstTabInitialFrame: CGRect?

    internal lazy var tabStackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.distribution = .fillProportionally
        stack.alignment = .centerY
        stack.spacing = 6
        stack.edgeInsets = .init(top: 0, left: 16, bottom: 0, right: 6)
        return stack
    }()

    private lazy var scrollView: AXScrollView = {
        let scroll = AXScrollView(frame: bounds)
        scroll.drawsBackground = false
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = false
        scroll.usesPredominantAxisScrolling = true
        scroll.horizontalScrollElasticity = .allowed
        scroll.verticalScrollElasticity = .none
        scroll.autoresizingMask = [.width, .height]
        scroll.translatesAutoresizingMaskIntoConstraints = true
        scroll.automaticallyAdjustsContentInsets = false
        scroll.contentView.postsBoundsChangedNotifications = true
        return scroll
    }()

    required init(tabGroup: AXTabGroup) {
        self.tabGroup = tabGroup
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        self.tabGroup = .init(name: "NULL")
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        wantsLayer = true
        currentWidth = bounds.width

        addSubview(scrollView)
        scrollView.documentView = tabStackView
        setupConstraints()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidScroll),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.81) { [weak self] in
            self?.scrollToTab(at: self?.tabGroup.selectedIndex ?? 0)
        }
    }

    private func setupConstraints() {
        tabStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabStackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            tabStackView.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),
            tabStackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor)
        ])
    }

    override func layout() {
        let newWidth = bounds.width
        let newTabCount = tabStackView.arrangedSubviews.count

        if newWidth != currentWidth || newTabCount != currentTabCount {
            super.layout()
            updateAllTabWidths()

            currentWidth = newWidth
            currentTabCount = newTabCount
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: (NSScreen.main?.frame.width ?? 200) / 2.5, height: 44)
    }

    func addTabButton(for tab: AXTab) {
        let button = AXHorizontalTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        button.tag = tabGroup.tabs.count - 1

        let previousIndex = tabGroup.selectedIndex
        tabGroup.selectedIndex = button.tag

        self.delegate?.tabBarSwitchedTo(tabAt: button.tag)

        addButtonWithAnimation(button) {
            self.updateTabSelection(from: previousIndex, to: button.tag)
            self.scrollToTab(at: button.tag)
        }
    }

    private func addButtonWithAnimation(_ button: AXHorizontalTabButton, completion: @escaping () -> Void) {
        addButtonToStackView(button)
        button.alphaValue = 0
        button.frame.origin.x = tabStackView.frame.width

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            button.animator().frame.origin.x = 0
            button.animator().alphaValue = 1
        }, completionHandler: completion)
    }

    private func addButtonToStackView(_ button: AXHorizontalTabButton) {
        tabStackView.addArrangedSubview(button)

        let constraint = createWidthConstraint(for: button)
        tabConstraints[button] = constraint
        constraint.isActive = true

        updateAllTabWidths()
        firstTabInitialFrame = nil
    }

    private func createWidthConstraint(for button: AXHorizontalTabButton) -> NSLayoutConstraint {
        let availableWidth = bounds.width - 45
        let tabCount = CGFloat(tabStackView.arrangedSubviews.count)
        let idealWidth = min(maxTabWidth, availableWidth / tabCount)
        let finalWidth = max(minTabWidth, idealWidth)

        return button.widthAnchor.constraint(equalToConstant: finalWidth)
    }

    // MARK: - Remove Tab Functions
//    private func removeTabWithAnimation(_ button: AXHorizontalTabButton, index: Int) {
//        NSAnimationContext.runAnimationGroup({ context in
//            context.duration = 0.2
//            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//            button.animator().frame.origin.x -= button.frame.width
//            button.animator().alphaValue = 0
//        }, completionHandler: { [weak self] in
//            self?.cleanupTab(button)
//            
//            NSAnimationContext.runAnimationGroup { context in
//                context.duration = 0.2
//                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//                self?.updateAllTabWidths()
//                self?.tabStackView.layoutSubtreeIfNeeded()
//            }
//        })
//    }

    private func cleanupTab(_ button: AXHorizontalTabButton) {
        tabConstraints.removeValue(forKey: button)
        button.removeFromSuperview()

        self.updateAllTabWidths()
        self.tabStackView.layoutSubtreeIfNeeded()

        stickyDelegate?.tabBarRemovedTab()
    }

    func tabButtonWillClose(_ tabButton: AXTabButton) {
        guard let tabButton = tabButton as? AXHorizontalTabButton else { fatalError("Incorrect Button Type") }
        let index = tabButton.tag
        tabGroup.tabs.remove(at: index)

        cleanupTab(tabButton)
        updateIndices(after: index)
    }

    func removeTabButton(at index: Int) {
        guard let button = tabStackView.arrangedSubviews[index] as? AXHorizontalTabButton else { return }

        // Remove the tab button
        cleanupTab(button)

        // Update indices and selected index
        updateIndices(after: index)

        // Scroll to the new selected tab
        scrollToTab(at: tabGroup.selectedIndex)
    }

    func updateIndices(after index: Int) {
        // Adjust tags for remaining buttons
        print("Updating Indicies after \(index)")
        for (idx, button) in tabStackView.arrangedSubviews.enumerated().dropFirst(index) {
            (button as? AXHorizontalTabButton)?.tag = idx
        }

        // Adjust the selected index
        updateSelectedItemIndex(after: index)
    }

    private func updateSelectedItemIndex(after removedIndex: Int) {
        if tabGroup.tabs.isEmpty {
            // No tabs left
            tabGroup.selectedIndex = -1
            delegate?.tabBarSwitchedTo(tabAt: -1)
            return
        }

        if tabGroup.selectedIndex == removedIndex {
            // If the removed tab was selected, select the next tab or the last one
            tabGroup.selectedIndex = min(removedIndex, tabGroup.tabs.count - 1)
        } else if tabGroup.selectedIndex > removedIndex {
            // If a tab before the selected one is removed, shift the selected index
            tabGroup.selectedIndex -= 1
        }

        // Update visuals
        if let button = tabStackView.arrangedSubviews[tabGroup.selectedIndex] as? AXHorizontalTabButton {
            button.isSelected = true
        }

        delegate?.tabBarSwitchedTo(tabAt: tabGroup.selectedIndex)
        stickyDelegate?.tabBarShouldRemoveSticky()
        updateAllTabWidths()
    }

    func updateTabSelection(from: Int, to index: Int) {
        print(#function, from, index, "UPDATED SELECTED INDEX")
        let arrangedSubviews = tabStackView.arrangedSubviews
        guard index < arrangedSubviews.count else { return }

        if from >= 0 && from < arrangedSubviews.count {
            (arrangedSubviews[from] as? AXTabButton)?.isSelected = false
        }

        (arrangedSubviews[index] as? AXTabButton)?.isSelected = true

        delegate?.tabBarSwitchedTo(tabAt: index)
        stickyDelegate?.tabBarShouldRemoveSticky()
    }

    // MARK: - Other Functions

    private func updateAllTabWidths() {
        let availableWidth = bounds.width - 55
        let tabCount = CGFloat(tabStackView.arrangedSubviews.count)

        guard tabCount > 0 else { return }

        let idealWidth = min(maxTabWidth, availableWidth / tabCount)
        let finalWidth = max(minTabWidth, idealWidth)

        // Update all constraints with animation
        for (_, constraint) in tabConstraints {
            constraint.animator().constant = finalWidth
        }

        scrollView.horizontalScrollElasticity = (idealWidth <= 90) ? .allowed : .none
    }

    func addTabButtonInBackground(for tab: AXTab, index: Int) {
        let button = AXHorizontalTabButton(tab: tab)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        button.tag = index
        button.webTitle = tab.title

        addButtonToStackView(button)
        button.startObserving()
    }

    func scrollToTab(at index: Int) {
        guard index >= 0, index < tabStackView.arrangedSubviews.count else { return }

        let tabView = tabStackView.arrangedSubviews[index]
        let targetPointX = tabView.frame.origin.x + (tabView.frame.width / 2) - (scrollView.frame.width / 2)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: targetPointX, y: 0))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }

    // MARK: - Delegate Methods

    func tabButtonDidSelect(_ tabButton: AXTabButton) {
        let previousTag = tabGroup.selectedIndex
        let newTag = tabButton.tag

        tabGroup.selectedIndex = newTag
        updateTabSelection(from: previousTag, to: newTag)
        scrollToTab(at: newTag)
    }

    func tabButtonActiveTitleChanged(_ newTitle: String, for tabButton: AXTabButton) {
        delegate?.tabBarActiveTabTitleChanged(to: newTitle)
    }

    func tabButtonDeactivatedWebView(_ tabButton: AXTabButton) {
        // Do nothing :)
    }

    // MARK: - Sticky Tab Handling
    @objc
    private func scrollViewDidScroll(_ notification: Notification) {
        updateStickyTabs()
    }

    private func updateStickyTabs() {
        guard !tabGroup.tabs.isEmpty else { return }

        let safeIndex = max(0, min(tabGroup.selectedIndex, tabStackView.arrangedSubviews.count - 1))
        guard let currentTab = tabStackView.arrangedSubviews[safeIndex] as? AXHorizontalTabButton else { return }

        let scrollPosition = scrollView.documentVisibleRect.origin.x
        let visibleWidth = scrollView.documentVisibleRect.width
        let maxVisiblePosition = scrollPosition + visibleWidth

        if firstTabInitialFrame == nil || currentTab.frame != firstTabInitialFrame {
            firstTabInitialFrame = currentTab.frame
        }

        let newStickyState = calculateStickyState(
            for: currentTab,
            scrollPosition: scrollPosition,
            maxVisiblePosition: maxVisiblePosition
        )

        updateStickyState(newStickyState, for: currentTab)
        lastScrollPosition = scrollPosition
    }

    private func calculateStickyState(
        for tab: AXTabButton,
        scrollPosition: CGFloat,
        maxVisiblePosition: CGFloat
    ) -> TabStickyPosition {
        if scrollPosition > 0 && tab.frame.minX < scrollPosition {
            return .left
        } else if let documentView = scrollView.documentView,
                  maxVisiblePosition < documentView.frame.width && tab.frame.maxX > maxVisiblePosition {
            return .right
        }
        return .none
    }

    private func updateStickyState(_ newState: TabStickyPosition, for tab: AXHorizontalTabButton) {
        guard newState != currentStickyState else { return }

        if newState == .none {
            stickyDelegate?.tabBarShouldRemoveSticky()
        } else if let constraint = tabConstraints[tab], constraint.constant == minTabWidth {
            stickyDelegate?.tabBarShouldMakeTabSticky(tab, position: newState)
        }

        currentStickyState = newState
    }
}
