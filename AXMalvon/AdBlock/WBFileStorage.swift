//
//  WBFileStorage.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-02.
//

import Foundation

class WBFileStorage {
    static let shared = WBFileStorage()

    lazy var cachedContainerURL: URL? = {
        let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!

        let malvonURL = appSupportURL.appendingPathComponent(
            "Malvon", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: malvonURL, withIntermediateDirectories: true)

        let directoryURL = malvonURL.appendingPathComponent(
            "wBlock", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directoryURL, withIntermediateDirectories: true)

        return directoryURL
    }()

    private let fileManager = FileManager.default
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    private init() {}

    func getContainerURL() -> URL? {
        return cachedContainerURL
    }

    func saveJSON(_ jsonString: String, filename: String) throws {
        guard let containerURL = cachedContainerURL else {
            throw NSError(
                domain: "FileStorage",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Cannot access app group container"
                ])
        }

        let fileURL = containerURL.appendingPathComponent(filename)

        try jsonString.write(
            to: fileURL,
            atomically: true,
            encoding: .utf8)
    }

    func loadJSON(filename: String) throws -> String {
        guard let containerURL = cachedContainerURL else {
            throw NSError(
                domain: "FileStorage",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Cannot access app group container"
                ])
        }

        let fileURL = containerURL.appendingPathComponent(filename)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    func clearCache() {
        // Method to clear cached URLs if needed
        if let containerURL = cachedContainerURL {
            try? fileManager.removeItem(at: containerURL)
        }
    }
}
