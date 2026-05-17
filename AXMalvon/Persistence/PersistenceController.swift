//
//  PersistenceController.swift
//  AXMalvon
//
//  Owns the app-wide SwiftData ``ModelContainer``. Use ``shared`` from
//  app code; ``preview`` from SwiftUI previews and tests.
//
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Foundation
import SwiftData

@MainActor
enum PersistenceController {
    /// Single source of truth for the SwiftData store. Configured once at first
    /// access; subsequent accesses return the same container.
    static let shared: ModelContainer = {
        do {
            return try makeContainer(inMemory: false)
        } catch {
            fatalError("Unable to create SwiftData container: \(error)")
        }
    }()

    /// In-memory container for SwiftUI previews and unit tests. Never persists.
    static let preview: ModelContainer = {
        do {
            return try makeContainer(inMemory: true)
        } catch {
            fatalError("Unable to create preview SwiftData container: \(error)")
        }
    }()

    /// Application Support directory for the current build. DEBUG builds write
    /// to `Malvon-Debug/` to avoid trampling a real install's data.
    static var applicationSupportDirectory: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        #if DEBUG
        let directory = base.appendingPathComponent("Malvon-Debug", isDirectory: true)
        #else
        let directory = base.appendingPathComponent("Malvon", isDirectory: true)
        #endif
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static let schema = Schema([
        MalvonProfile.self,
        MalvonTabGroup.self,
        MalvonTab.self,
        MalvonHistoryEntry.self,
        MalvonSearchFrequency.self,
    ])

    private static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(
                schema: schema, isStoredInMemoryOnly: true
            )
        } else {
            let storeURL = applicationSupportDirectory
                .appendingPathComponent("Malvon.store")
            configuration = ModelConfiguration(
                schema: schema, url: storeURL, cloudKitDatabase: .none
            )
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
