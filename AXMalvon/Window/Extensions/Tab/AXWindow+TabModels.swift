//
//  AXWindow+TabModels.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

extension AXWindow {
    func switchToTabGroup(_ tabGroup: AXTabGroup) {
        self.tabBarView.updateTabGroup(tabGroup)

        layoutManager.updatedTabGroupColor(in: self, color: tabGroup.color)
        layoutManager.tabGroupInfoView.updateLabels(tabGroup: tabGroup)

        mxPrint("Changed to Tab Group \(tabGroup.name), unknown index.")
    }

    func switchToTabGroup(_ atIndex: Int) {
        let tabGroup = activeProfile.tabGroups[atIndex]
        self.currentTabGroupIndex = atIndex

        switchToTabGroup(tabGroup)

        mxPrint(
            "Changed to Tab Group \(tabGroup.name), known index: \(self.currentTabGroupIndex). Ignore top message."
        )
    }
}
