//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

// MARK: - AXWindow
class AXWindow: NSWindow {
    // Window Defaults
    lazy var usesVerticalTabs = UserDefaults.standard.bool(
        forKey: "verticalTabs")
    var hiddenSidebarView = false
    internal var trafficLightButtons: [NSButton]!

    // Other Views
    internal var layoutManager: AXWindowLayoutManaging!

    // Lazy loading to stop unnecesary initilizations
    lazy var tabBarView: AXTabBarViewTemplate = {
        if usesVerticalTabs {
            return AXVerticalTabBarView(tabGroup: currentTabGroup)
        } else {
            return AXHorizontalTabBarView(tabGroup: currentTabGroup)
        }
    }()

    init(with profiles: [AXProfile]) {
        self.profiles = profiles
        activeProfile = profiles[profileIndex]  // 0

        super.init(
            contentRect: AXWindow.updateWindowFrame(),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
            ],
            backing: .buffered,
            defer: false
        )

        setupNSWindowStyle()
        setupBrowserElements()
    }

    // MARK: - Profile/Groups Tab Functions
    var profiles: [AXProfile]
    var activeProfile: AXProfile

    var profileIndex = 0 {
        didSet {
            activeProfile = profiles[profileIndex]
            self.switchToTabGroup(activeProfile.currentTabGroupIndex)
        }
    }

    var tabGroups: [AXTabGroup] {
        activeProfile.tabGroups
    }

    var currentTabGroupIndex: Int {
        get {
            activeProfile.currentTabGroupIndex
        }
        set {
            activeProfile.currentTabGroupIndex = newValue
        }
    }

    var currentTabGroup: AXTabGroup {
        activeProfile.currentTabGroup
    }

    // MARK: - Workspace Variables
    lazy var workspaceSwapperView: AXWorkspaceSwapperView = {
        let view = AXWorkspaceSwapperView()
        view.delegate = self
        return view
    }()

    lazy var tabCustomizationView: AXTabGroupCustomizerView = {
        let view = AXTabGroupCustomizerView()
        view.delegate = self
        return view
    }()

    lazy var browserSpaceSharedPopover: NSPopover = {
        let popover = NSPopover()
        popover.contentViewController = .init()
        popover.behavior = .transient
        return popover
    }()
}
