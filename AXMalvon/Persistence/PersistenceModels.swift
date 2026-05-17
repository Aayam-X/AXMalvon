//
//  PersistenceModels.swift
//  AXMalvon
//
//  SwiftData entity definitions. A single store backs every profile, with
//  relationships replacing the previous per-profile SQLite/JSON files.
//
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Foundation
import SwiftData

/// A browsing profile. Each profile gets its own `WKWebsiteDataStore`
/// (identified by ``dataStoreUUID``) so cookies and storage stay isolated.
@Model
final class MalvonProfile {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    var dataStoreUUID: UUID
    var selectedTabGroupIndex: Int
    var position: Int

    @Relationship(deleteRule: .cascade, inverse: \MalvonTabGroup.profile)
    var tabGroups: [MalvonTabGroup] = []

    @Relationship(deleteRule: .cascade, inverse: \MalvonHistoryEntry.profile)
    var historyEntries: [MalvonHistoryEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        dataStoreUUID: UUID = UUID(),
        selectedTabGroupIndex: Int = 0,
        position: Int = 0
    ) {
        self.id = id
        self.name = name
        self.dataStoreUUID = dataStoreUUID
        self.selectedTabGroupIndex = selectedTabGroupIndex
        self.position = position
    }
}

/// A workspace within a profile. Holds an ordered list of tabs plus
/// customization (color, SF Symbol icon, name).
@Model
final class MalvonTabGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    /// 8-character RRGGBBAA hex (no `#`), matching ``NSColor.toHex()``.
    var colorHex: String
    /// SF Symbol identifier.
    var icon: String
    var position: Int
    /// Index of the currently-selected tab within ``tabs``; `-1` if none.
    var selectedTabIndex: Int

    var profile: MalvonProfile?

    @Relationship(deleteRule: .cascade, inverse: \MalvonTab.group)
    var tabs: [MalvonTab] = []

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "CCCCCCCC",
        icon: String = "square.3.layers.3d",
        position: Int = 0,
        selectedTabIndex: Int = -1
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.position = position
        self.selectedTabIndex = selectedTabIndex
    }
}

/// A persisted tab. Runtime state (the `WKWebView`, favicon image, etc.)
/// is owned by a separate non-persisted wrapper; only what survives a
/// relaunch lives here.
@Model
final class MalvonTab {
    @Attribute(.unique) var id: UUID
    var url: URL?
    var title: String
    var position: Int
    var isPinned: Bool
    var lastVisited: Date?

    var group: MalvonTabGroup?

    init(
        id: UUID = UUID(),
        url: URL? = nil,
        title: String,
        position: Int = 0,
        isPinned: Bool = false,
        lastVisited: Date? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.position = position
        self.isPinned = isPinned
        self.lastVisited = lastVisited
    }
}

/// A single visited-URL record. Replaces the per-profile `history` SQLite
/// table; `dateString` is kept for compatibility with downstream search UI
/// that groups history by day.
@Model
final class MalvonHistoryEntry {
    @Attribute(.unique) var id: UUID
    var title: String
    var address: String
    var timestamp: Date
    var timesAccessed: Int
    /// `yyyy-MM-dd` of `timestamp`, denormalized for cheap day-grouping queries.
    var dateString: String

    var profile: MalvonProfile?

    init(
        id: UUID = UUID(),
        title: String,
        address: String,
        timestamp: Date = .now,
        timesAccessed: Int = 1
    ) {
        self.id = id
        self.title = title
        self.address = address
        self.timestamp = timestamp
        self.timesAccessed = timesAccessed
        self.dateString = MalvonHistoryEntry.dateFormatter.string(from: timestamp)
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

/// Cross-profile aggregate of how often the user has resolved a typed
/// query into a given URL. Powers the "Top searches" rail in the address bar.
@Model
final class MalvonSearchFrequency {
    @Attribute(.unique) var url: String
    var occurrences: Int

    init(url: String, occurrences: Int = 1) {
        self.url = url
        self.occurrences = occurrences
    }
}
