//
//  CRXExtension.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-04.
//

import Foundation
import WebKit

struct CRXExtension {
    let id: String
    let name: String
    let crxURL: URL

    init?(crxURL: URL) {
        guard
            crxURL.absoluteString.contains("chromewebstore.google.com/detail"),
            let id = Self.extractExtensionID(from: crxURL.absoluteString),
            let name = Self.extractExtensionName(from: crxURL.absoluteString)
        else {
            return nil
        }

        self.crxURL = crxURL
        self.id = id
        self.name = name
    }
}

// MARK: - Core Functionality
extension CRXExtension {
    var extensionFolder: URL? {
        guard let baseURL = FileManager.mavlonExtensionsDirectory else {
            return nil
        }
        return baseURL.appendingPathComponent(name, isDirectory: true)
    }

    func parseManifest() -> CRXManifest? {
        guard let extensionFolder = extensionFolder else {
            print("Extension folder not available")
            return nil
        }

        let manifestURL = extensionFolder.appendingPathComponent(
            "manifest.json")

        do {
            let data = try Data(contentsOf: manifestURL)
            return try JSONDecoder().decode(CRXManifest.self, from: data)
        } catch {
            print("Error parsing manifest: \(error.localizedDescription)")
            return nil
        }
    }

    func download() async {
        guard let extensionsDirectory = FileManager.mavlonExtensionsDirectory
        else {
            print("Extensions directory unavailable")
            return
        }

        let downloadURLString =
            "https://clients2.google.com/service/update2/crx?response=redirect&os=mac&arch=x86-64&nacl_arch=x86-64&prod=chromiumcrx&prodchannel=unknown&prodversion=126.0.0.0&acceptformat=crx2,crx3&x=id%3D\(id)%26installsource%3Dondemand%26uc"

        guard let downloadURL = URL(string: downloadURLString) else {
            print("Invalid download URL constructed")
            return
        }

        let crxFileURL = extensionsDirectory.appendingPathComponent("\(id).crx")
        let unzippedFolderURL = extensionsDirectory.appendingPathComponent(
            name, isDirectory: true)

        do {
            let (tempLocalURL, _) = try await URLSession.shared.download(
                from: downloadURL)
            try await Self.moveDownloadedFile(
                from: tempLocalURL, to: crxFileURL)
            try await Self.prepareUnzipDirectory(at: unzippedFolderURL)
            try await Self.unzipFile(at: crxFileURL, to: unzippedFolderURL)
            print(
                "Extension successfully installed at \(unzippedFolderURL.path)")
        } catch {
            print("Download failed: \(error.localizedDescription)")
        }

        try? FileManager.default.removeItem(at: crxFileURL)
    }
}

extension CRXExtension {
    func remove() {
        guard let path = extensionFolder?.path else { return }
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}

// MARK: - Private Helpers
extension CRXExtension {
    fileprivate static func extractExtensionID(from urlString: String)
        -> String?
    {
        if let id = urlString.split(separator: "/").last?.prefix(32) {
            return String(id)
        }
        return nil
    }

    fileprivate static func extractExtensionName(from urlString: String)
        -> String?
    {
        let components = urlString.split(separator: "/")
        return components.count > 3 ? String(components[3]) : nil
    }

    fileprivate static func moveDownloadedFile(
        from sourceURL: URL, to destinationURL: URL
    ) async throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
    }

    fileprivate static func prepareUnzipDirectory(at url: URL) async throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        try fileManager.createDirectory(
            at: url, withIntermediateDirectories: true)
    }

    fileprivate static func unzipFile(at sourceURL: URL, to destinationURL: URL)
        async throws
    {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
                process.arguments = [
                    "-o", sourceURL.path, "-d", destinationURL.path,
                ]

                do {
                    try process.run()
                    process.waitUntilExit()

                    if process.terminationStatus == 0 {
                        continuation.resume()
                    } else {
                        let error = NSError(
                            domain: "UnzipError",
                            code: Int(process.terminationStatus),
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "Unzip failed with exit code \(process.terminationStatus)"
                            ]
                        )
                        continuation.resume(throwing: error)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - FileManager Extension
extension FileManager {
    static var mavlonExtensionsDirectory: URL? {
        guard
            let appSupportURL = self.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else { return nil }

        let malvonURL = appSupportURL.appendingPathComponent(
            "Malvon", isDirectory: true)
        try? self.default.createDirectory(
            at: malvonURL, withIntermediateDirectories: true)

        let directoryURL = malvonURL.appendingPathComponent(
            "Extensions", isDirectory: true)
        try? self.default.createDirectory(
            at: directoryURL, withIntermediateDirectories: true)

        return directoryURL
    }
}
