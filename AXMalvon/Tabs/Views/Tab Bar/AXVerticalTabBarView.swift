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

    func addTabButton() {
        let button = AXVerticalTabButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self

        let newIndex = tabStackView.arrangedSubviews.count
        button.tag = newIndex

        addButtonToTabView(button)
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
            self.updateIndicesBeforeTabDelete(at: index)
            self.tabStackView.layoutSubtreeIfNeeded()
        }
    }
    
    func updateButton(title: String, at index: Int) {
        for tabButton in tabStackView.arrangedSubviews as! [AXTabButton] {
            if tabButton.tag == index {
                tabButton.webTitle = title
                break
            }
        }
    }
    
    func updateButton(icon: NSImage, at index: Int) {
        for tabButton in tabStackView.arrangedSubviews as! [AXTabButton] {
            if tabButton.tag == index {
                tabButton.favicon = icon
                break
            }
        }
    }
}

// MARK: - Tab Button Delegate
extension AXVerticalTabBarView {
    func tabButtonDidSelect(_ tabButton: any AXTabButton) {
        self.delegate?.tabBarSwitchedTo(tabButton)
    }
    
    func tabButtonDidRequestClose(_ tabButton: any AXTabButton) {
        if let delegate, delegate.tabBarShouldClose(tabButton) {
            self.removeTabButton(at: tabButton.tag)
            delegate.tabBarDidClose(tabButton.tag)
        }
    }
}

// MARK: - Private Methods
extension AXVerticalTabBarView {
    private func updateIndicesBeforeTabDelete(at index: Int) {
        for case let (index, button as AXTabButton) in tabStackView
            .arrangedSubviews.enumerated().dropFirst(index)
        {
            mxPrint("DELETATION START INDEX = \(index)")
            button.tag = index
        }

        updateSelectedItemIndex(before: index)
    }

    private func updateSelectedItemIndex(before index: Int) {
//        // Handle when there are no more tabs left
//        if tabGroup.tabs.isEmpty {
//            mxPrint("No tabs left")
//            tabGroup.selectedIndex = -1
//            previousTabIndex = -1
//            delegate?.tabBarSwitchedTo(tabAt: -1)
//            return
//        }
//
//        // If the selected tab is the one being deleted, adjust the index
//        if tabGroup.selectedIndex == index {
//            // If the removed tab was selected, select the next one or the last one
//            if previousTabIndex == -1 {
//                tabGroup.selectedIndex = tabGroup.tabs.count - 1
//            } else {
//                tabGroup.selectedIndex = min(
//                    previousTabIndex, tabGroup.tabs.count - 1)
//            }
//        } else if tabGroup.selectedIndex > index {
//            // If a tab before the selected one is removed, shift the selected index
//            tabGroup.selectedIndex -= 1
//        }
//
//        mxPrint("Updated Tab Index: \(tabGroup.selectedIndex)")
//
//        // Select the appropriate tab button
//        if let button = tabStackView.arrangedSubviews[tabGroup.selectedIndex]
//            as? AXTabButton
//        {
//            button.isSelected = true
//        }
    }

    private func updateTabSelection(from: Int, to index: Int) {
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

/*
 func addTabButton(for tab: AXTab) {
     let button = AXVerticalTabButton()
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

 func tabButtonDidSelect(_ tabButton: AXTabButton) {
     let previousTag = tabGroup.selectedIndex

     let newTag = tabButton.tag
     tabGroup.selectedIndex = newTag

     // Update the active tab
     updateTabSelection(from: previousTag, to: newTag)
 }

 func tabButtonWillClose(_ tabButton: AXTabButton) {
     guard let delegate = self.delegate, delegate.tabBarWillDelete(tabButton: tabButton) else {
         return
     }
     
     let index = tabButton.tag
     
     tabButton.removeFromSuperview()
     updateIndicesBeforeTabDelete(at: index)
     
     tabGroup.tabContentView.tabViewItems.remove(at: index)
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
         self.updateIndicesBeforeTabDelete(at: index)
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

 */
