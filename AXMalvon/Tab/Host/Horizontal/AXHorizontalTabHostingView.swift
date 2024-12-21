//
//  AXHorizontalTabHostingView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//

import AppKit

class AXHorizontalTabHostingView: NSView, AXTabHostingViewProtocol,
    AXHorizontalToolbarViewDelegate
{

    var delegate: (any AXTabHostingViewDelegate)?
    private var hasDrawn: Bool = false

    var tabGroupInfoView: AXTabGroupInfoView = AXTabGroupInfoView()
    var searchButton: AXSidebarSearchButton = AXSidebarSearchButton()

    var horizontalToolbar: AXHorizontalToolbarView!

    override func viewWillDraw() {
        guard !hasDrawn else { return }
        defer { hasDrawn = true }

        // TabGroup Information View
        tabGroupInfoView.onLeftMouseDown =
            delegate?.tabHostingViewDisplaysWorkspaceSwapperPanel
        tabGroupInfoView.onRightMouseDown =
            delegate?.tabHostingViewDisplaysTabGroupCustomizationPanel

        // Horizontal Toolbar
        self.horizontalToolbar = AXHorizontalToolbarView(
            tabGroupInfoView: tabGroupInfoView, searchButton: searchButton)
        self.horizontalToolbar.translatesAutoresizingMaskIntoConstraints = false
        self.horizontalToolbar.delegate = self

        addSubview(horizontalToolbar)

        NSLayoutConstraint.activate([
            // Room to accomodate for the tab view
            horizontalToolbar.topAnchor.constraint(
                equalTo: topAnchor, constant: 45),
            horizontalToolbar.leftAnchor.constraint(equalTo: leftAnchor),
            horizontalToolbar.rightAnchor.constraint(equalTo: rightAnchor),
            horizontalToolbar.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    // MARK: - Tab Hosting View Functions
    func insertTabBarView(tabBarView: any AXTabBarViewTemplate) {
        addSubview(tabBarView)

        NSLayoutConstraint.activate([
            tabBarView.topAnchor.constraint(equalTo: topAnchor),
            tabBarView.leftAnchor.constraint(equalTo: leftAnchor),
            tabBarView.rightAnchor.constraint(equalTo: rightAnchor),
            tabBarView.heightAnchor.constraint(equalToConstant: 45),
        ])
    }

    // MARK: - Toolbar Delegate
    func didTapBackButton() {
        delegate?.tabHostingViewNavigateBackwards()
    }

    func didTapForwardButton() {
        delegate?.tabHostingViewNavigateForward()
    }
}
