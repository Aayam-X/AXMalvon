//
//  AXWindow+WorkspaceSwapper.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

extension AXWindow: AXWorkspaceSwapperViewDelegate {
    func didEditTabGroup(at index: Int) {
        browserSpaceSharedPopover.contentViewController?.view =
            tabCustomizationView

        let sender = layoutManager.tabGroupInfoView

        browserSpaceSharedPopover.show(
            relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    func didDeleteTabGroup(index: Int) {
        activeProfile.tabGroups.remove(at: index)

        if activeProfile.tabGroups.isEmpty {
            let newTabGroup = AXTabGroup(name: "New Tab Group")
            activeProfile.tabGroups.append(newTabGroup)
        }

        if currentTabGroupIndex >= index {
            currentTabGroupIndex = 0
        }

        switchToTabGroup(currentTabGroupIndex)
    }

    func currentProfileName() -> String {
        activeProfile.name
    }

    func didSwitchProfile(to index: Int) {
        profileIndex = profileIndex == 1 ? 0 : 1

        // Update to let it know if it's working with a private window or not
        AXSearchQueryToURL.shared.activeProfile = activeProfile

        layoutManager.tabGroupInfoView.updateLabels(
            tabGroup: currentTabGroup, profileName: activeProfile.name)
    }

    func popoverViewTabGroups() -> [AXTabGroup] {
        return self.activeProfile.tabGroups
    }

    func didSwitchTabGroup(to index: Int) {
        let tabGroup = self.activeProfile.tabGroups[index]
        self.currentTabGroupIndex = index

        visualEffectTintView.layer?.backgroundColor = tabGroup.color.cgColor

        self.switchToTabGroup(tabGroup)
    }

    func didAddTabGroup(_ newGroup: AXTabGroup) {
        // Switch to the new tab group
        self.activeProfile.tabGroups.append(newGroup)
    }
}
