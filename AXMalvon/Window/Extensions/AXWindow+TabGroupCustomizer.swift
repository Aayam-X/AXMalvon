//
//  AXWindow+TabGroupCustomizer.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

extension AXWindow: AXTabGroupCustomizerViewDelegate {
    func tabGroupCustomizerActiveTabGroup() -> AXTabGroup? {
        return activeProfile.currentTabGroup
    }

    func tabGroupCustomizerDidUpdateName(_ tabGroup: AXTabGroup) {
        // No need to update profile name here, AXTabGroupCustomizerViewDelegate
        layoutManager.tabGroupInfoView.updateLabels(tabGroup: tabGroup)
    }

    func tabGroupCustomizerDidUpdateColor(_ tabGroup: AXTabGroup) {
        visualEffectTintView.layer?.backgroundColor = tabGroup.color.cgColor
        self.backgroundColor = tabGroup.color.withAlphaComponent(1)
    }

    func tabGroupCustomizerDidUpdateIcon(_ tabGroup: AXTabGroup) {
        layoutManager.tabGroupInfoView.updateIcon(tabGroup: tabGroup)
    }
}
