//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import SwiftData
import WebKit

/// Runtime representation of a browsing profile. Wraps a SwiftData
/// ``MalvonProfile`` for persistent state and a ``WKWebViewConfiguration``
/// (with an isolated ``WKWebsiteDataStore``) for the live browser.
@MainActor
class AXProfile {
    /// SwiftData-backed twin. `nil` for ``AXPrivateProfile`` where everything
    /// stays in memory. The model owns canonical state — `name`,
    /// `dataStoreUUID`, `selectedTabGroupIndex` are read through to it.
    let model: MalvonProfile?

    let baseConfiguration: WKWebViewConfiguration

    /// Display name. Reads from (and writes through to) the SwiftData model
    /// so renames are persisted automatically. Private profile is always
    /// "Private" and ignores writes.
    var name: String {
        get { model?.name ?? "Private" }
        set { model?.name = newValue }
    }

    var tabGroups: [AXTabGroup] = []
    weak var currentTabGroup: AXTabGroup!

    var historyManager: AXHistoryManager?
    var hasLoadedTabs: Bool = false

    var currentTabGroupIndex: Int {
        didSet {
            guard currentTabGroupIndex >= 0,
                  currentTabGroupIndex < tabGroups.count else { return }
            currentTabGroup = tabGroups[currentTabGroupIndex]
            model?.selectedTabGroupIndex = currentTabGroupIndex
        }
    }

    /// Look up or create a profile by name in the shared SwiftData store.
    convenience init(name: String) {
        let context = PersistenceController.shared.mainContext
        let model = AXProfile.fetchOrCreate(name: name, in: context)
        self.init(model: model, baseConfiguration: AXProfile.makeConfig(for: model))
    }

    /// Designated init. Pass `model: nil` from ``AXPrivateProfile``.
    fileprivate init(
        model: MalvonProfile?,
        baseConfiguration: WKWebViewConfiguration
    ) {
        self.model = model
        self.baseConfiguration = baseConfiguration
        self.currentTabGroupIndex = model?.selectedTabGroupIndex ?? 0
        self.historyManager = model.map { AXHistoryManager(profile: $0) }

        loadTabGroups()
    }

    // MARK: - Tab groups

    /// Reconstruct ``tabGroups`` from the SwiftData store. Subclasses may
    /// override to provide in-memory-only behavior (e.g. private browsing).
    func loadTabGroups() {
        hasLoadedTabs = true
        guard let model else { return }

        let sortedGroups = model.tabGroups.sorted { $0.position < $1.position }
        tabGroups = sortedGroups.map { groupModel in
            let group = AXTabGroup(name: groupModel.name)
            group.color = NSColor(hex: groupModel.colorHex)
            group.icon = groupModel.icon
            group.selectedIndex = max(0, groupModel.selectedTabIndex)

            let sortedTabs = groupModel.tabs.sorted { $0.position < $1.position }
            group.tabs = sortedTabs.map { tabModel in
                AXTab(
                    restoredURL: tabModel.url,
                    title: tabModel.title,
                    configuration: baseConfiguration
                )
            }
            return group
        }

        if tabGroups.isEmpty {
            tabGroups = [AXTabGroup(name: "Untitled Tab Group")]
        }

        let clamped = min(max(0, currentTabGroupIndex), tabGroups.count - 1)
        currentTabGroupIndex = clamped
        currentTabGroup = tabGroups[clamped]
    }

    /// Persist the in-memory ``tabGroups`` to SwiftData. Replaces the previous
    /// per-profile JSON encoder. Subclasses may override to no-op (private
    /// browsing).
    func saveTabGroups() {
        guard hasLoadedTabs, let model else { return }
        let context = PersistenceController.shared.mainContext

        // The previous tab groups for this profile are deleted wholesale and
        // replaced. Tab counts are small (typically < 100) so the simplicity
        // of a clean rewrite beats diff-tracking individual mutations.
        for oldGroup in model.tabGroups {
            context.delete(oldGroup)
        }

        for (groupPosition, axGroup) in tabGroups.enumerated() {
            let groupModel = MalvonTabGroup(
                name: axGroup.name,
                colorHex: axGroup.color.toHex() ?? "CCCCCCCC",
                icon: axGroup.icon,
                position: groupPosition,
                selectedTabIndex: axGroup.selectedIndex
            )
            groupModel.profile = model
            context.insert(groupModel)

            for (tabPosition, axTab) in axGroup.tabs.enumerated() {
                let url = axTab.webView?.url ?? axTab.url
                let tabModel = MalvonTab(
                    url: url,
                    title: axTab.title,
                    position: tabPosition
                )
                tabModel.group = groupModel
                context.insert(tabModel)
            }
        }

        model.selectedTabGroupIndex = currentTabGroupIndex

        do {
            try context.save()
        } catch {
            mxPrint("Failed to save profile \(name): \(error)")
        }
    }

    // MARK: - Helpers

    private static func fetchOrCreate(
        name: String, in context: ModelContext
    ) -> MalvonProfile {
        let descriptor = FetchDescriptor<MalvonProfile>(
            predicate: #Predicate { $0.name == name }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let count = (try? context.fetchCount(FetchDescriptor<MalvonProfile>())) ?? 0
        let new = MalvonProfile(name: name, position: count)
        context.insert(new)
        try? context.save()
        return new
    }

    private static func makeConfig(for model: MalvonProfile) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore(forIdentifier: model.dataStoreUUID)
        config.enableDefaultMalvonPreferences()
        return config
    }
}

/// Private-browsing profile. Uses a non-persistent ``WKWebsiteDataStore`` and
/// never touches SwiftData; everything is in-memory and discarded on close.
@MainActor
final class AXPrivateProfile: AXProfile {
    init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.enableDefaultMalvonPreferences()
        super.init(model: nil, baseConfiguration: config)
    }

    override func loadTabGroups() {
        hasLoadedTabs = true
        let group = AXTabGroup(name: "Private Tab Group")
        group.color = .black
        tabGroups = [group]
        currentTabGroupIndex = 0
        currentTabGroup = group
    }

    override func saveTabGroups() { /* private mode never persists */ }
}
