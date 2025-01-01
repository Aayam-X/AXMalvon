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
    lazy var splitView = NSSplitView()
    internal var layoutManager: AXWindowLayoutManaging!

    // Lazy loading to stop unnecesary initilizations
    lazy var tabBarView: AXTabBarViewTemplate = {
        if usesVerticalTabs {
            return AXVerticalTabBarView(tabGroup: currentTabGroup)
        } else {
            return AXHorizontalTabBarView(tabGroup: currentTabGroup)
        }
    }()

    internal lazy var visualEffectTintView: NSView = {
        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true

        return tintView
    }()

    internal lazy var visualEffectView: NSVisualEffectView = {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .popover
        visualEffectView.wantsLayer = true

        // Add tint view on top of the visual effect view
        visualEffectView.addSubview(visualEffectTintView)
        NSLayoutConstraint.activate([
            visualEffectTintView.leadingAnchor.constraint(
                equalTo: visualEffectView.leadingAnchor),
            visualEffectTintView.trailingAnchor.constraint(
                equalTo: visualEffectView.trailingAnchor),
            visualEffectTintView.topAnchor.constraint(
                equalTo: visualEffectView.topAnchor),
            visualEffectTintView.bottomAnchor.constraint(
                equalTo: visualEffectView.bottomAnchor)
        ])

        return visualEffectView
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
                .resizable
            ],
            backing: .buffered,
            defer: false
        )

        // Because app delegate references as a weak object already
        self.isReleasedWhenClosed = false

        configureWindow()
        setupComponents()
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

    var currentConfiguration: WKWebViewConfiguration {
        activeProfile.configuration
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
