//
//  AXWindow+TabHosting.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

extension AXWindow: AXTabHostingViewDelegate {
    func tabHostingViewCreatedNewTab() {
        toggleSearchBarForNewTab(nil)
    }

    func tabHostingViewReloadCurrentPage() {
        layoutManager.containerView.reload()
    }

    func tabHostingViewNavigateForward() {
        layoutManager.containerView.forward()
    }

    func tabHostingViewNavigateBackwards() {
        layoutManager.containerView.back()
    }

    func tabHostingViewDisplaysTabGroupCustomizationPanel(_ sender: NSView) {
        browserSpaceSharedPopover.contentViewController?.view =
            tabCustomizationView

        browserSpaceSharedPopover.show(
            relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    func tabHostingViewDisplaysWorkspaceSwapperPanel(_ sender: NSView) {
        workspaceSwapperView.reloadTabGroups()
        browserSpaceSharedPopover.contentViewController?.view =
            workspaceSwapperView

        browserSpaceSharedPopover.show(
            relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
}
