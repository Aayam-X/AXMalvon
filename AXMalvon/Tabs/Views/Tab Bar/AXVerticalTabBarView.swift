//
//  AXTabBarView.swift
//  AXTabSystem
//
//  Created by Ashwin Paudel on 2024-11-14.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXVerticalTabBarView: NSView, AXTabBarViewTemplate {
    weak var delegate: (any AXTabBarViewDelegate)?

    // Variables
    var selectedTabIndex: Int = 0 {
        didSet {
            updateTabSelection(from: oldValue, to: selectedTabIndex)
        }
    }

    /// Tracks the active tab group's color so newly-created buttons
    /// (e.g. via ``AXTabsManager/addTab(_:)`` after the user opens a new
    /// page) pick up the right tint even though they didn't go through
    /// ``updateTabGroup(_:)``.
    var accentColor: NSColor?

    // Views
    internal var tabStackView = NSStackView()
    private var clipView = AXFlippedClipView()
    private var scrollView: AXScrollView!

    required init() {
        super.init(frame: .zero)
        setupViews()
    }

    required convenience init?(coder: NSCoder) {
        self.init()
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

        // Scroll view fills the entire view
        scrollView.activateConstraints([
            .allEdges: .view(self)
        ])

        // Stack view dimensions
        tabStackView.activateConstraints([
            .horizontalEdges: .view(clipView),
            .top: .view(clipView),
            // Don't constrain the bottom - let it grow as needed
        ])

        // Bug-3 fix: `.inVisibleRect` tracking areas don't reliably fire
        // mouseExited when the content scrolls under a stationary cursor,
        // so hover state could stick on a button that scrolled out from
        // under the pointer. Listen for live-scroll notifications and
        // clear hover state on every button. The next mouse move will
        // re-establish hover on whichever button is actually under the
        // cursor.
        clipView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clipViewBoundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: clipView
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func clipViewBoundsDidChange(_ note: Notification) {
        for case let button as AXVerticalTabButton in tabStackView.arrangedSubviews {
            button.clearHoverState()
        }
    }

    @discardableResult
    func addTabButton() -> AXTabButton {
        let button = AXVerticalTabButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        button.accentColor = accentColor

        let newIndex = tabStackView.arrangedSubviews.count
        button.tag = newIndex

        addButtonToTabView(button)

        return button
    }
    
    func removeTabButton(at index: Int) {
        guard index >= 0, index < tabStackView.arrangedSubviews.count else {
            return
        }
        let button = tabStackView.arrangedSubviews[index]

        // Remove the button from the layout BEFORE the subsequent
        // selectedTabIndex update touches the bar. Previously this fired a
        // 0.05s fade-out animation that kept the button in arrangedSubviews
        // until the animation completed, which raced with
        // updateTabSelection — the bug was that the in-flight closing
        // button stayed visually selected, producing a double-highlight.
        button.removeFromSuperview()

        // Re-tag every button after this index so callers (close button,
        // selection events) keep agreeing on indices.
        updateButtonTags(startingAfter: index)
    }
    
    func tabButton(at index: Int) -> AXTabButton {
        return tabStackView.arrangedSubviews[index] as! AXTabButton
    }
}

// MARK: - Tab Button Delegate
extension AXVerticalTabBarView {
    func tabButtonDidSelect(_ tabButton: any AXTabButton) {
        self.delegate?.tabBarSwitchedTo(tabButton)
    }
    
    func tabButtonDidRequestClose(_ tabButton: any AXTabButton) {
        if let delegate, delegate.tabBarShouldClose(tabButton) {
            //self.removeTabButton(at: tabButton.tag)
            delegate.tabBarDidClose(tabButton.tag)
        }
    }
}

// MARK: - Private Methods
extension AXVerticalTabBarView {
    private func updateButtonTags(startingAfter index: Int) {
        for case let (i, button as AXTabButton) in tabStackView
            .arrangedSubviews.enumerated()
            where i >= index
        {
            button.tag = i
        }
    }

    private func updateTabSelection(from: Int, to index: Int) {
        let arrangedSubviews = tabStackView.arrangedSubviews
        let count = arrangedSubviews.count

        // Rapid closes can leave a stale selectedTabIndex setter pending
        // for a count that no longer exists; previously this hit a
        // fatalError. Bail out cleanly when the new index is out of range
        // — the next valid selection will rebuild state.
        guard count > 0, index >= 0, index < count else { return }

        if from >= 0, from < count, from != index,
            let previousButton = arrangedSubviews[from] as? AXTabButton
        {
            previousButton.isSelected = false
        }

        if let newButton = arrangedSubviews[index] as? AXTabButton {
            newButton.isSelected = true
        }
    }

    private func addButtonToTabView(_ button: NSView) {
        // Add the button off-screen by modifying its frame
        button.translatesAutoresizingMaskIntoConstraints = false

        // Configure button layout priorities
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(
            .defaultLow, for: .horizontal)

        tabStackView.addArrangedSubview(button)

        // Only constrain the horizontal margins
        button.activateConstraints([
            .left: .view(tabStackView, constant: 5),
            .right: .view(tabStackView, constant: -3),
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
