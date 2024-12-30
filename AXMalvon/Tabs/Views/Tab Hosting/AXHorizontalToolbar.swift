//
//  AXHorizontalToolbar.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-29.
//

import AppKit

class MainWindowToolbar: NSToolbar, NSToolbarDelegate, AXTabHostingViewProtocol {
    internal var tabBarView: AXTabBarViewTemplate
    var stickyTabBarView: AXStickyHorizontalTabBarView

    required init(tabBarView: any AXTabBarViewTemplate) {
        guard let tabBarView = tabBarView as? AXHorizontalTabBarView else {
            fatalError(
                #function + ": \(tabBarView) is not an AXHorizontalTabBarView")
        }
        self.tabBarView = tabBarView
        self.stickyTabBarView = AXStickyHorizontalTabBarView(
            tabBarView: tabBarView)
        super.init(identifier: "AXMalvonBrowserToolbar")
        self.delegate = self
        self.allowsUserCustomization = true
        self.displayMode = .iconOnly

        centeredItemIdentifiers = [tabBarIdentifier]
    }

    weak var tabHostingDelegate: AXTabHostingViewDelegate?

    internal lazy var tabGroupInfoView: AXTabGroupInfoView = {
        let view = AXTabGroupInfoView()
        view.onLeftMouseDown = tabGroupInfoViewLeftDown
        view.onRightMouseDown = tabGroupInfoViewRightDown

        return view
    }()

    internal lazy var searchButton: AXSidebarSearchButton = {
        let button = AXSidebarSearchButton()
        return button
    }()

    private lazy var browserNavigationStackView: AXGestureStackView = {
        let stackView = AXGestureStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.distribution = .gravityAreas
        stackView.spacing = 3
        stackView.gestureDelegate = self

        stackView.addArrangedSubview(tabGroupInfoView)

        return stackView
    }()

    private lazy var addNewTabButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.addTemplateName)!, target: self, action: #selector(addNewTab))
        button.title = ""
        button.bezelStyle = .texturedRounded
        return button
    }()

    // Toolbar item identifiers
    private let searchIdentifier = NSToolbarItem.Identifier("search")
    private let navigationIdentifier = NSToolbarItem.Identifier("navigation")
    private let tabBarIdentifier = NSToolbarItem.Identifier("tabBar")
    private let addNewTabIdentifier = NSToolbarItem.Identifier("addNewTab")

    // MARK: - NSToolbarDelegate
    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)

        switch itemIdentifier {
        case searchIdentifier:
            item.view = searchButton
            item.label = "Search"
            item.paletteLabel = "Search"
            item.isNavigational = true

        case navigationIdentifier:
            item.view = browserNavigationStackView
            item.label = "Navigation"
            item.paletteLabel = "Navigation"
            item.isNavigational = true

        case tabBarIdentifier:
            item.view = stickyTabBarView
            item.visibilityPriority = .high
            item.label = "Tabs"
            item.paletteLabel = "Tabs"
            item.isNavigational = true

        case addNewTabIdentifier:
            item.view = addNewTabButton
            item.label = "Add Tab"
            item.paletteLabel = "Add Tab"
            item.isNavigational = false

        case .flexibleSpace:
            break

        default:
            return nil
        }

        return item
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem
        .Identifier] {
            return [navigationIdentifier, searchIdentifier, tabBarIdentifier, addNewTabIdentifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem
        .Identifier] {
            return [navigationIdentifier, .space, searchIdentifier, tabBarIdentifier, .flexibleSpace, addNewTabIdentifier]
    }

    @objc
    private func addNewTab() {
        tabHostingDelegate?.tabHostingViewCreatedNewTab()
    }

    func tabGroupInfoViewLeftDown() {
        tabHostingDelegate?.tabHostingViewDisplaysWorkspaceSwapperPanel(
            tabGroupInfoView)
    }

    func tabGroupInfoViewRightDown() {
        tabHostingDelegate?.tabHostingViewDisplaysTabGroupCustomizationPanel(
            tabGroupInfoView)
    }
}

extension MainWindowToolbar: AXGestureViewDelegate {
    func gestureView(didSwipe direction: AXGestureViewSwipeDirection!) {
        switch direction {
        case .backwards:
            tabHostingDelegate?.tabHostingViewNavigateBackwards()
        case .reload:
            tabHostingDelegate?.tabHostingViewReloadCurrentPage()
        case .forwards:
            tabHostingDelegate?.tabHostingViewNavigateForward()
        case .nothing, .none:
            break
        }
    }
}
