//
//  AXStickyHorizontalTabBarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

//class AXStickyHorizontalTabBarView: NSView {
//    var tabBarView: AXHorizontalTabBarView
//
//    // The tab that is being stickied
//    private weak var stickyTab: AXTabButton?
//
//    private lazy var leftStickyTab: AXHorizontalTabButton =
//        createConfiguredStickyTab()
//    private lazy var rightStickyTab: AXHorizontalTabButton =
//        createConfiguredStickyTab()
//
//    // MARK: - Initializers
//    required init(tabBarView: AXHorizontalTabBarView) {
//        self.tabBarView = tabBarView
//        super.init(frame: .zero)
//        setupViews()
//    }
//
//    required init?(coder: NSCoder) {
//        guard let tabBarView = AXHorizontalTabBarView(coder: coder) else {
//            fatalError("Failed to initialize AXHorizontalTabBarView")
//        }
//        self.tabBarView = tabBarView
//        super.init(coder: coder)
//        setupViews()
//    }
//
//    // MARK: - View Setup
//    private func setupViews() {
//        addSubview(tabBarView)
//        addSubview(leftStickyTab, positioned: .above, relativeTo: tabBarView)
//        addSubview(rightStickyTab, positioned: .above, relativeTo: tabBarView)
//
//        setupConstraints()
//    }
//
//    private func setupConstraints() {
//        tabBarView.translatesAutoresizingMaskIntoConstraints = false
//        leftStickyTab.translatesAutoresizingMaskIntoConstraints = false
//        rightStickyTab.translatesAutoresizingMaskIntoConstraints = false
//
//        self.activateConstraints([
//            .height: .constant(40)
//        ])
//
//        tabBarView.activateConstraints([
//            .allEdges: .view(self)
//        ])
//
//        leftStickyTab.activateConstraints([
//            .left: .view(self),
//            .centerY: .view(self),
//            .width: .constant(90),
//        ])
//
//        rightStickyTab.activateConstraints([
//            .right: .view(self),
//            .centerY: .view(self),
//            .width: .constant(90),
//        ])
//
//        tabBarView.stickyDelegate = self
//    }
//
//    // MARK: - Sticky Tab Methods
//    private func createConfiguredStickyTab() -> AXHorizontalTabButton {
//        let view = AXHorizontalTabButton(tab: nil)
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.wantsLayer = true
//        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
//        view.layer?.shadowColor = NSColor.black.cgColor
//        view.layer?.shadowOpacity = 0.3
//        view.layer?.shadowRadius = 10
//
//        view.isHidden = true
//        return view
//    }
//}
//
//// MARK: - AXHorizontalTabBarViewDelegate
//extension AXStickyHorizontalTabBarView: AXHorizontalTabBarViewDelegate {
//    func tabBarShouldMakeTabSticky(
//        _ tab: AXTabButton, position: TabStickyPosition
//    ) {
//        stickyTab = tab
//
//        leftStickyTab.isHidden = true
//        rightStickyTab.isHidden = true
//
//        let stickyTab = position == .left ? leftStickyTab : rightStickyTab
//        stickyTab.isHidden = false
//        stickyTab.tab = tab.tab
//        stickyTab.webTitle = tab.webTitle
//        stickyTab.favicon = tab.favicon
//        stickyTab.tag = tab.tag
//        stickyTab.isSelected = true
//        stickyTab.startObserving()
//    }
//
//    func tabBarShouldRemoveSticky() {
//        leftStickyTab.isHidden = true
//        rightStickyTab.isHidden = true
//        [leftStickyTab, rightStickyTab].forEach { $0.tab = nil }
//
//        stickyTab?.startObserving()
//    }
//
//    func tabBarRemovedTab() {
//        leftStickyTab.isHidden = true
//        rightStickyTab.isHidden = true
//        [leftStickyTab, rightStickyTab].forEach { $0.tab = nil }
//    }
//}
