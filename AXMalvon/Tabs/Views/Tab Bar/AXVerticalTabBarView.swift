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
    }

    @discardableResult
    func addTabButton() -> AXTabButton {
        let button = AXVerticalTabButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        let newIndex = tabStackView.arrangedSubviews.count
        button.tag = newIndex

        addButtonToTabView(button)
        
        return button
    }
    
    func removeTabButton(at index: Int) {
        let button = tabStackView.arrangedSubviews[index] as! AXTabButton
        
        // FIXME: HELP
        /*
         Removing tabs: When the selectedTabIndex changes, it updates all the views. Only problem is that the VerticalTabBarView has a 0.05 second animation before removing the tabButton from SuperView. Meaning it would have highlighted the incorrect tab. I believe the fix to this is by sending the selectedTabIndex to the tab bar view, who then selects it AFTER the button has been removed from superView.
         */
        //button.removeFromSuperview()
        
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
            //self.updateButtonTags(startingAfter: index)
        }
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
        for case let (index, button as AXTabButton) in tabStackView
            .arrangedSubviews.enumerated().dropFirst(index) {
            mxPrint("DELETATION START INDEX = \(index)")
            button.tag = index
        }
    }

    private func updateTabSelection(from: Int, to index: Int) {
        let arragedSubviews = tabStackView.arrangedSubviews
        let arrangedSubviewsCount = arragedSubviews.count

        guard arrangedSubviewsCount > index else { fatalError("Nigga whattt") }

        if from >= 0 && from < arrangedSubviewsCount {
            let previousButton =
                arragedSubviews[from] as! AXTabButton
            previousButton.isSelected = false
        }

        let newButton = arragedSubviews[index] as! AXTabButton
        newButton.isSelected = true
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
