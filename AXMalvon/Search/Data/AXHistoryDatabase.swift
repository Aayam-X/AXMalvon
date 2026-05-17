//
//  AXHistoryDatabase.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-25.
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Foundation
import SwiftData

/// In-memory representation of a single history record. Returned by
/// ``AXHistoryManager/search(query:)`` and accepted by
/// ``AXHistoryManager/insert(item:)``. Mirrors the shape of the legacy
/// SQLite row for callsite compatibility.
final class AXHistoryItem {
    var id: Int64?
    var title: String
    var address: String
    var timestamp: Date
    var timesAccessed: Int

    init(
        id: Int64? = nil,
        title: String,
        address: String,
        timestamp: Date = Date(),
        timesAccessed: Int = 1
    ) {
        self.id = id
        self.title = title
        self.address = address
        self.timestamp = timestamp
        self.timesAccessed = timesAccessed
    }
}

/// Per-profile history store. Previously a raw-SQLite database; now a thin
/// wrapper over the shared SwiftData store, scoped by ``MalvonProfile``.
///
/// API surface (`insert`, `search`, `recentlyClosedTabs`, `flushAndClose`)
/// is preserved so call sites in ``AXWindow+WebContainer`` and
/// ``SuggestionsManager`` don't change.
@MainActor
final class AXHistoryManager {
    let profile: MalvonProfile

    /// Stack of URLs the user has recently closed; ``AXWindow`` pops from
    /// it for ⌘⇧T. Purely in-memory, by design.
    var recentlyClosedTabs: [URL] = []

    init(profile: MalvonProfile) {
        self.profile = profile
    }

    // MARK: - Insert

    /// Upserts a history record for the active profile. If an entry with the
    /// same address already exists, its `timesAccessed` is incremented and
    /// the timestamp refreshed; otherwise a new entry is created.
    func insert(item: AXHistoryItem) {
        let context = PersistenceController.shared.mainContext
        let address = item.address
        let profileID = profile.id

        let descriptor = FetchDescriptor<MalvonHistoryEntry>(
            predicate: #Predicate { entry in
                entry.address == address && entry.profile?.id == profileID
            }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.timesAccessed += item.timesAccessed
            existing.timestamp = item.timestamp
            existing.title = item.title
        } else {
            let entry = MalvonHistoryEntry(
                title: item.title,
                address: item.address,
                timestamp: item.timestamp,
                timesAccessed: item.timesAccessed
            )
            entry.profile = profile
            context.insert(entry)
        }

        do {
            try context.save()
        } catch {
            mxPrint("AXHistoryManager.insert save failed: \(error)")
        }
    }

    // MARK: - Search

    /// Returns history entries for this profile matching `query` (case-
    /// insensitive substring in title or address) whose `timesAccessed > 4`,
    /// sorted by access frequency.
    ///
    /// SwiftData predicates have limited string-comparison support; we fetch
    /// the candidate set (filtered by profile + access threshold) and refine
    /// in Swift. History entry counts per profile are small enough that this
    /// is fine.
    func search(query: String) -> [AXHistoryItem] {
        let context = PersistenceController.shared.mainContext
        let profileID = profile.id

        let descriptor = FetchDescriptor<MalvonHistoryEntry>(
            predicate: #Predicate { entry in
                entry.profile?.id == profileID && entry.timesAccessed > 4
            },
            sortBy: [SortDescriptor(\.timesAccessed, order: .reverse)]
        )

        guard let candidates = try? context.fetch(descriptor) else {
            return []
        }

        let needle = query.lowercased()
        return candidates
            .filter { entry in
                entry.title.lowercased().contains(needle)
                    || entry.address.lowercased().contains(needle)
            }
            .map { entry in
                AXHistoryItem(
                    title: entry.title,
                    address: entry.address,
                    timestamp: entry.timestamp,
                    timesAccessed: entry.timesAccessed
                )
            }
    }

    /// Kept for API compatibility with the previous SQLite implementation
    /// (which buffered inserts and flushed on close). SwiftData saves
    /// inline, so this is a no-op.
    func flushAndClose() {}
}
