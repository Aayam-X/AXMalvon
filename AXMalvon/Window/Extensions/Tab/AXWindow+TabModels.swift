//
//  AXWindow+TabModels.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//

extension AXWindow {
    func switchToTabGroup(_ tabGroup: AXTabGroup) {
        self.tabBarView.updateTabGroup(tabGroup)

        visualEffectTintView.layer?.backgroundColor = tabGroup.color.cgColor
        self.backgroundColor = tabGroup.color.withAlphaComponent(1)
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
