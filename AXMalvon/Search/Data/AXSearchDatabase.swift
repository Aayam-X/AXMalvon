//
//  AXSearchDatabase.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-19.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Foundation
import SQLite3

// Perhaps convert this to Core Data rather than SQLite?
class AXSearchDatabase {
    private var dbPointer: OpaquePointer?
    static var shared = AXSearchDatabase()

    init() {
        // Set the path to the Application Support directory
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
        let fileURL = directoryURL.appendingPathComponent("searchData.sqlite")
        mxPrint("Database file path: \(fileURL)")

        if sqlite3_open(fileURL.path, &dbPointer) != SQLITE_OK {
            mxPrint(
                "Error opening database: \(String(cString: sqlite3_errmsg(dbPointer)))"
            )
            return
        }

        // Create the table if it does not exist
        let createTableQuery =
            "CREATE TABLE IF NOT EXISTS SearchOccurrences (url TEXT PRIMARY KEY, occurrences INTEGER)"
        if sqlite3_exec(dbPointer, createTableQuery, nil, nil, nil) != SQLITE_OK
        {
            mxPrint(
                "Error creating table: \(String(cString: sqlite3_errmsg(dbPointer)))"
            )
        }
    }

    func incrementOccurrence(for url: String) {
        let selectQuery =
            "SELECT occurrences FROM SearchOccurrences WHERE url = ?"
        let updateQuery =
            "UPDATE SearchOccurrences SET occurrences = occurrences + 1 WHERE url = ?"
        let insertQuery =
            "INSERT INTO SearchOccurrences (url, occurrences) VALUES (?, 1)"
        var statement: OpaquePointer?

        // Check if the URL exists
        if sqlite3_prepare_v2(dbPointer, selectQuery, -1, &statement, nil)
            == SQLITE_OK
        {
            sqlite3_bind_text(
                statement, 1, (url as NSString).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                // URL exists, update occurrences
                sqlite3_finalize(statement)
                if sqlite3_prepare_v2(
                    dbPointer, updateQuery, -1, &statement, nil)
                    == SQLITE_OK
                {
                    sqlite3_bind_text(
                        statement, 1, (url as NSString).utf8String, -1, nil)
                    if sqlite3_step(statement) != SQLITE_DONE {
                        mxPrint(
                            "Error updating occurrence: \(String(cString: sqlite3_errmsg(dbPointer)))"
                        )
                    }
                }
            } else {
                // URL does not exist, insert it
                sqlite3_finalize(statement)
                if sqlite3_prepare_v2(
                    dbPointer, insertQuery, -1, &statement, nil)
                    == SQLITE_OK
                {
                    sqlite3_bind_text(
                        statement, 1, (url as NSString).utf8String, -1, nil)
                    if sqlite3_step(statement) != SQLITE_DONE {
                        mxPrint(
                            "Error inserting new URL: \(String(cString: sqlite3_errmsg(dbPointer)))"
                        )
                    }
                }
            }
        } else {
            mxPrint(
                "Error preparing select statement: \(String(cString: sqlite3_errmsg(dbPointer)))"
            )
        }
        sqlite3_finalize(statement)
    }

    func getRelevantSearchSuggestions(
        prefix: String, limit: Int = 4, minOccurrences: Int = 3
    ) -> [String] {
        let query = """
                SELECT url FROM SearchOccurrences
                WHERE url LIKE ? AND occurrences >= ?
                ORDER BY occurrences DESC
                LIMIT ?
            """
        var statement: OpaquePointer?
        var suggestions: [String] = []

        if sqlite3_prepare_v2(dbPointer, query, -1, &statement, nil)
            == SQLITE_OK
        {
            let prefixWithWildcard = "\(prefix)%"
            sqlite3_bind_text(
                statement, 1, (prefixWithWildcard as NSString).utf8String, -1,
                nil)
            sqlite3_bind_int(statement, 2, Int32(minOccurrences))
            sqlite3_bind_int(statement, 3, Int32(limit))

            while sqlite3_step(statement) == SQLITE_ROW {
                if let urlCStr = sqlite3_column_text(statement, 0) {
                    suggestions.append(String(cString: urlCStr))
                }
            }
        } else {
            mxPrint(
                "Error preparing query: \(String(cString: sqlite3_errmsg(dbPointer)))"
            )
        }
        sqlite3_finalize(statement)
        return suggestions
    }

    deinit {
        sqlite3_close(dbPointer)
    }
}
