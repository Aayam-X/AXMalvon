//
//  AXHistoryDatabase.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-25.
//

import Foundation
import SQLite3

class AXHistoryItem {
    var id: Int64?
    var title: String
    var address: String
    var timestamp: Date
    var timesAccessed: Int

    init(
        id: Int64? = nil, title: String, address: String,
        timestamp: Date = Date(), timesAccessed: Int = 1
    ) {
        self.id = id
        self.title = title
        self.address = address
        self.timestamp = timestamp
        self.timesAccessed = timesAccessed
    }
}

class AXHistoryManager {
    private var historyDB: OpaquePointer?
    private let dbPath: String
    private let batchSize = 100
    private var pendingItems: [AXHistoryItem] = []
    private let queue = DispatchQueue(
        label: "com.axhistorymanager.database", attributes: .concurrent)

    lazy var dateString: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: .now)
    }()

    init(fileName: String) {
        let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!

        #if DEBUG
            let directoryURL = appSupportURL.appendingPathComponent(
                "AXMalvon", isDirectory: true)
        #else
            let directoryURL = appSupportURL.appendingPathComponent(
                "Malvon", isDirectory: true)
        #endif

        try? FileManager.default.createDirectory(
            at: directoryURL, withIntermediateDirectories: true)

        dbPath = directoryURL.appendingPathComponent("\(fileName).sqlite").path
        setupDatabase()
    }

    private func setupDatabase() {
        if sqlite3_open(dbPath, &historyDB) == SQLITE_OK {
            let createTableQuery = """
                    CREATE TABLE IF NOT EXISTS history (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        title TEXT NOT NULL,
                        address TEXT NOT NULL,
                        timestamp DATETIME NOT NULL,
                        times_accessed INTEGER DEFAULT 1,
                        date_string TEXT NOT NULL
                    );
                """

            var createTableStatement: OpaquePointer?
            if sqlite3_prepare_v2(
                historyDB, createTableQuery, -1, &createTableStatement, nil)
                == SQLITE_OK {
                if sqlite3_step(createTableStatement) == SQLITE_DONE {
                    print("History table created successfully")
                }
            }
            sqlite3_finalize(createTableStatement)
        }
    }

    func insert(item: AXHistoryItem) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.pendingItems.append(item)

            if self.pendingItems.count >= self.batchSize {
                self.flushPendingItems()
            }
        }
    }

    private func flushPendingItems() {
        guard !pendingItems.isEmpty else { return }

        sqlite3_exec(historyDB, "BEGIN TRANSACTION", nil, nil, nil)

        defer {
            sqlite3_exec(historyDB, "COMMIT", nil, nil, nil)
        }

        guard prepareStatements() else {
            sqlite3_exec(historyDB, "ROLLBACK", nil, nil, nil)
            return
        }

        for item in pendingItems {
            processItem(item)
        }

        finalizeStatements()
    }

    // MARK: - Helper Methods

    private var checkStatement: OpaquePointer?
    private var updateStatement: OpaquePointer?
    private var insertStatement: OpaquePointer?

    private func prepareStatements() -> Bool {
        let checkQuery = """
            SELECT id, times_accessed FROM history WHERE address = ?
        """
        let updateQuery = """
            UPDATE history SET times_accessed = ?, timestamp = ? WHERE id = ?
        """
        let insertQuery = """
            INSERT INTO history (title, address, timestamp, times_accessed, date_string)
            VALUES (?, ?, ?, ?, ?)
        """

        if sqlite3_prepare_v2(historyDB, checkQuery, -1, &checkStatement, nil) != SQLITE_OK ||
           sqlite3_prepare_v2(historyDB, updateQuery, -1, &updateStatement, nil) != SQLITE_OK ||
           sqlite3_prepare_v2(historyDB, insertQuery, -1, &insertStatement, nil) != SQLITE_OK {
            print("Error preparing statements")
            return false
        }

        return true
    }

    private func processItem(_ item: AXHistoryItem) {
        // Check for duplicates
        sqlite3_bind_text(checkStatement, 1, (item.address as NSString).utf8String, -1, nil)

        if sqlite3_step(checkStatement) == SQLITE_ROW {
            updateExistingRecord(item)
        } else {
            insertNewRecord(item)
        }

        sqlite3_reset(checkStatement)
    }

    private func updateExistingRecord(_ item: AXHistoryItem) {
        let id = sqlite3_column_int64(checkStatement, 0)
        let existingTimesAccessed = sqlite3_column_int(checkStatement, 1)

        sqlite3_bind_int(updateStatement, 1, existingTimesAccessed + Int32(item.timesAccessed))
        sqlite3_bind_double(updateStatement, 2, item.timestamp.timeIntervalSince1970)
        sqlite3_bind_int64(updateStatement, 3, id)

        if sqlite3_step(updateStatement) != SQLITE_DONE {
            print("Error updating record")
        }

        sqlite3_reset(updateStatement)
    }

    private func insertNewRecord(_ item: AXHistoryItem) {
        sqlite3_bind_text(insertStatement, 1, (item.title as NSString).utf8String, -1, nil)
        sqlite3_bind_text(insertStatement, 2, (item.address as NSString).utf8String, -1, nil)
        sqlite3_bind_double(insertStatement, 3, item.timestamp.timeIntervalSince1970)
        sqlite3_bind_int(insertStatement, 4, Int32(item.timesAccessed))
        sqlite3_bind_text(insertStatement, 5, (dateString as NSString).utf8String, -1, nil)

        if sqlite3_step(insertStatement) != SQLITE_DONE {
            print("Error inserting record")
        }

        sqlite3_reset(insertStatement)
    }

    private func finalizeStatements() {
        sqlite3_finalize(checkStatement)
        sqlite3_finalize(updateStatement)
        sqlite3_finalize(insertStatement)
    }

    func search(query: String) -> [AXHistoryItem] {
        var results: [AXHistoryItem] = []

        // Search the database
        let searchQuery = """
                SELECT title, address, timestamp, times_accessed
                FROM history
                WHERE (title LIKE ? OR address LIKE ?) AND times_accessed > 4
                ORDER BY times_accessed DESC
            """

        var searchStatement: OpaquePointer?

        defer {
            sqlite3_finalize(searchStatement)
        }

        if sqlite3_prepare_v2(historyDB, searchQuery, -1, &searchStatement, nil)
            == SQLITE_OK {
            let searchPattern = "%\(query)%"
            sqlite3_bind_text(
                searchStatement, 1, (searchPattern as NSString).utf8String, -1,
                nil)
            sqlite3_bind_text(
                searchStatement, 2, (searchPattern as NSString).utf8String, -1,
                nil)

            while sqlite3_step(searchStatement) == SQLITE_ROW {
                let title = String(
                    cString: sqlite3_column_text(searchStatement, 0))
                let address = String(
                    cString: sqlite3_column_text(searchStatement, 1))
                let timestamp = Date(
                    timeIntervalSince1970: sqlite3_column_double(
                        searchStatement, 2))
                let timesAccessed = Int(sqlite3_column_int(searchStatement, 3))

                results.append(
                    AXHistoryItem(
                        title: title,
                        address: address,
                        timestamp: timestamp,
                        timesAccessed: timesAccessed
                    )
                )
            }
        } else {
            print("Error preparing search query")
        }

        // Search the pending items
        let filteredPendingItems = pendingItems.filter { item in
            item.title.contains(query) || item.address.contains(query)
        }

        // Combine the results from the database and pending items
        results.append(contentsOf: filteredPendingItems)

        // Sort the combined results by times accessed (descending)
        results.sort { $0.timesAccessed > $1.timesAccessed }

        return results
    }

    func flushAndClose() {
        queue.sync(flags: .barrier) {
            flushPendingItems()
        }
        sqlite3_close(historyDB)
    }

    deinit {
        flushAndClose()
    }
}
