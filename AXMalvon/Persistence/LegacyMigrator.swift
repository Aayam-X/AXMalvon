//
//  LegacyMigrator.swift
//  AXMalvon
//
//  One-shot migration from pre-SwiftData persistence into the unified store.
//  Reads:
//   - `UserDefaults["Profiles"]` for profile metadata (configID + selected
//     tab-group index)
//   - `~/.../Malvon/<name>-TabGroups.json` per profile (Codable tab groups)
//   - `~/.../Malvon/<configID>.sqlite` per profile (history table)
//   - `~/.../Malvon/searchData.sqlite` (global SearchOccurrences table)
//
//  Migration is gated on a UserDefaults flag and runs at most once. Old files
//  are left in place after import so the user can verify and clean up by hand.
//
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Foundation
import SQLite3
import SwiftData

@MainActor
enum LegacyMigrator {
    private static let migrationFlagKey = "swiftDataMigrationV1Complete"

    /// `true` if the one-shot importer has not yet run on this install.
    static var needsMigration: Bool {
        !UserDefaults.standard.bool(forKey: migrationFlagKey)
    }

    /// `true` if at least one legacy artifact (JSON tab groups, history
    /// sqlite, or search sqlite) is present on disk.
    static var hasLegacyData: Bool {
        let dir = PersistenceController.applicationSupportDirectory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            atPath: dir.path
        ) else { return false }
        return contents.contains { name in
            name.hasSuffix("-TabGroups.json")
                || name == "searchData.sqlite"
                || name.hasSuffix(".sqlite")
        }
    }

    /// Run the one-shot migration if it hasn't run yet. Marks the migration
    /// complete in `UserDefaults` either way so we don't keep retrying on
    /// every launch — there's no useful retry path when legacy data is absent
    /// or malformed.
    static func runIfNeeded(context: ModelContext) {
        guard needsMigration else { return }
        if hasLegacyData {
            do {
                try migrate(context: context)
                mxPrint("[LegacyMigrator] Imported legacy data into SwiftData.")
            } catch {
                mxPrint("[LegacyMigrator] Failed: \(error)")
            }
        }
        UserDefaults.standard.set(true, forKey: migrationFlagKey)
    }

    // MARK: - Migration body

    private static func migrate(context: ModelContext) throws {
        let defaults = UserDefaults.standard
        let profiles = (defaults.dictionary(forKey: "Profiles")
            as? [String: [String: Any]]) ?? [:]

        // Stable iteration order so positions are reproducible.
        let names = profiles.isEmpty
            ? ["Default", "School"]  // matches the previous AppDelegate hardcoding
            : profiles.keys.sorted()

        for (position, name) in names.enumerated() {
            let entry = profiles[name] ?? [:]
            let configIDString = entry["id"] as? String ?? ""
            let selectedIndex = entry["i"] as? Int ?? 0
            let dataStoreUUID = UUID(uuidString: configIDString) ?? UUID()

            let profile = MalvonProfile(
                name: name,
                dataStoreUUID: dataStoreUUID,
                selectedTabGroupIndex: selectedIndex,
                position: position
            )
            context.insert(profile)

            importTabGroups(forProfile: profile, profileName: name, context: context)
            if !configIDString.isEmpty {
                importHistory(forProfile: profile, configID: configIDString, context: context)
            }
        }

        importSearchFrequencies(context: context)
        try context.save()
    }

    // MARK: - Tab groups

    private struct LegacyTabGroup: Decodable {
        let name: String
        let selectedIndex: Int
        let color: String?
        let icon: String?
        let tabs: [LegacyTab]
    }

    private struct LegacyTab: Decodable {
        let title: String
        let url: URL?
    }

    private static func importTabGroups(
        forProfile profile: MalvonProfile,
        profileName: String,
        context: ModelContext
    ) {
        let fileURL = PersistenceController.applicationSupportDirectory
            .appendingPathComponent("\(profileName)-TabGroups.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        let groups: [LegacyTabGroup]
        do {
            let data = try Data(contentsOf: fileURL)
            groups = try JSONDecoder().decode([LegacyTabGroup].self, from: data)
        } catch {
            mxPrint("[LegacyMigrator] Tab-groups decode failed for \(profileName): \(error)")
            return
        }

        for (groupPosition, legacy) in groups.enumerated() {
            let group = MalvonTabGroup(
                name: legacy.name,
                colorHex: legacy.color ?? "CCCCCCCC",
                icon: legacy.icon ?? "square.3.layers.3d",
                position: groupPosition,
                selectedTabIndex: legacy.selectedIndex
            )
            group.profile = profile
            context.insert(group)

            for (tabPosition, legacyTab) in legacy.tabs.enumerated() {
                let tab = MalvonTab(
                    url: legacyTab.url,
                    title: legacyTab.title,
                    position: tabPosition
                )
                tab.group = group
                context.insert(tab)
            }
        }
    }

    // MARK: - History

    private static func importHistory(
        forProfile profile: MalvonProfile,
        configID: String,
        context: ModelContext
    ) {
        let dbPath = PersistenceController.applicationSupportDirectory
            .appendingPathComponent("\(configID).sqlite").path
        guard FileManager.default.fileExists(atPath: dbPath) else { return }

        var handle: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let db = handle else {
            sqlite3_close(handle)
            return
        }
        defer { sqlite3_close(db) }

        let query = "SELECT title, address, timestamp, times_accessed FROM history"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK,
              let stmt = statement else {
            sqlite3_finalize(statement)
            return
        }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let title = String(cString: sqlite3_column_text(stmt, 0))
            let address = String(cString: sqlite3_column_text(stmt, 1))
            let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 2))
            let timesAccessed = Int(sqlite3_column_int(stmt, 3))

            let entry = MalvonHistoryEntry(
                title: title,
                address: address,
                timestamp: timestamp,
                timesAccessed: timesAccessed
            )
            entry.profile = profile
            context.insert(entry)
        }
    }

    // MARK: - Search frequencies

    private static func importSearchFrequencies(context: ModelContext) {
        let dbPath = PersistenceController.applicationSupportDirectory
            .appendingPathComponent("searchData.sqlite").path
        guard FileManager.default.fileExists(atPath: dbPath) else { return }

        var handle: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let db = handle else {
            sqlite3_close(handle)
            return
        }
        defer { sqlite3_close(db) }

        let query = "SELECT url, occurrences FROM SearchOccurrences"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK,
              let stmt = statement else {
            sqlite3_finalize(statement)
            return
        }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let url = String(cString: sqlite3_column_text(stmt, 0))
            let occurrences = Int(sqlite3_column_int(stmt, 1))
            context.insert(MalvonSearchFrequency(url: url, occurrences: occurrences))
        }
    }
}
