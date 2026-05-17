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
    internal var malvonTabManager: AXTabsManager!
    internal var layoutManager: AXWindowLayoutManaging!

    // Lazy loading to stop unnecesary initilizations
    lazy var tabBarView: AXTabBarViewTemplate = {
//        if usesVerticalTabs {
//            return AXVerticalTabBarView(tabGroup: currentTabGroup)
//        } else {
//            return AXHorizontalTabBarView(tabGroup: currentTabGroup)
//        }
        
        return AXVerticalTabBarView()
    }()

    init(with profiles: [AXProfile]) {
        self.profiles = profiles
        activeProfile = profiles[activeProfileIndex]  // 0

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

        // Seed the search singleton with the active profile so URL
        // commits (and the search-frequency increment) know which
        // profile to attribute to. This previously only ran on the
        // didSwitchProfile path, leaving a freshly-launched window
        // with no profile context.
        AXSearchQueryToURL.shared.activeProfile = activeProfile

        setupNSWindowStyle()
        setupBrowserElements()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let frame = AXWindow.updateWindowFrame()
            self?.setFrame(frame, display: true, animate: true)
        }
    }

    // MARK: - Profile/Groups Tab Functions
    var profiles: [AXProfile]

    var activeProfile: AXProfile
    var activeProfileIndex = 0

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

    /// Floating command bar (⌘T / ⌘L). Lazily constructed and reused
    /// across invocations so its layer cache survives between presents.
    lazy var commandBarPanel: AXCommandBarPanel = {
        let panel = AXCommandBarPanel()
        panel.onCommit = { [weak self] url in
            guard let self else { return }
            if self.commandBarPrefilledFromCurrentURL {
                self.searchBarUpdatesCurrentTab(with: url)
            } else {
                self.searchBarCreatesNewTab(with: url)
            }
        }
        return panel
    }()

    private var commandBarPrefilledFromCurrentURL: Bool = false

    /// Present the command bar over this window.
    /// - Parameter prefillingCurrentURL: ⌘L mode — the input is seeded
    ///   with the current tab's address (all selected) and committing
    ///   replaces the current tab's URL instead of opening a new tab.
    func showCommandBar(prefillingCurrentURL: Bool) {
        commandBarPrefilledFromCurrentURL = prefillingCurrentURL
        let prefill: String
        if prefillingCurrentURL,
            let url = layoutManager.containerView.currentPageAddress
        {
            prefill = url.absoluteString
        } else {
            prefill = ""
        }
        let suggestions = SuggestionsManager(
            historyManager: activeProfile.historyManager)
        commandBarPanel.present(
            in: self, prefill: prefill, suggestionsManager: suggestions)
    }
}
