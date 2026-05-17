//
//  AXSearchDatabase.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-19.
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Foundation
import SwiftData

/// Cross-profile aggregate of "how often did a typed query resolve to this
/// URL." Powers the "Top searches" rail in the address bar.
///
/// Previously a raw-SQLite singleton; now a thin wrapper over SwiftData's
/// ``MalvonSearchFrequency`` model. API preserved for call-site compat.
@MainActor
final class AXSearchDatabase {
    static let shared = AXSearchDatabase()

    private init() {}

    /// Increments the visit count for `url`, or inserts a fresh record with
    /// `occurrences: 1` if this is the first time we've seen it.
    func incrementOccurrence(for url: String) {
        let context = PersistenceController.shared.mainContext

        let descriptor = FetchDescriptor<MalvonSearchFrequency>(
            predicate: #Predicate { $0.url == url }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.occurrences += 1
        } else {
            context.insert(MalvonSearchFrequency(url: url, occurrences: 1))
        }

        do {
            try context.save()
        } catch {
            mxPrint("AXSearchDatabase.incrementOccurrence save failed: \(error)")
        }
    }

    /// Top URLs whose prefix matches `prefix` and have been visited at
    /// least `minOccurrences` times, ordered by frequency. Defaults to a
    /// threshold of 1 so any URL the user has typed before is eligible —
    /// the previous default of 3 made first-time URLs invisible until
    /// they'd been visited multiple times across sessions.
    func getRelevantSearchSuggestions(
        prefix: String, limit: Int = 4, minOccurrences: Int = 1
    ) -> [String] {
        let context = PersistenceController.shared.mainContext

        var descriptor = FetchDescriptor<MalvonSearchFrequency>(
            predicate: #Predicate { entry in
                entry.occurrences >= minOccurrences
                    && entry.url.starts(with: prefix)
            },
            sortBy: [SortDescriptor(\.occurrences, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        guard let results = try? context.fetch(descriptor) else {
            return []
        }
        return results.map(\.url)
    }
}
