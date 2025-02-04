//
//  CRXDownloader.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-03.
//

import Foundation

private var extensionsFolder: URL? = {
    let appSupportURL = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
    ).first!

    let malvonURL = appSupportURL.appendingPathComponent(
        "Malvon", isDirectory: true)
    try? FileManager.default.createDirectory(
        at: malvonURL, withIntermediateDirectories: true)

    let directoryURL = malvonURL.appendingPathComponent(
        "Extensions", isDirectory: true)
    try? FileManager.default.createDirectory(
        at: directoryURL, withIntermediateDirectories: true)

    return directoryURL
}()

enum CRXDownloader {
    static func downloadExtensionAndInstall(crxURL: URL?) async {
        guard let url = crxURL,
            url.absoluteString.contains("chromewebstore.google.com/detail")
        else {
            return
        }

        guard let id = extractExtensionID(from: url.absoluteString),
            let name = extractExtensionName(from: url.absoluteString)
        else {
            return
        }

        let downloadURLString =
            "https://clients2.google.com/service/update2/crx?response=redirect&os=mac&arch=x86-64&nacl_arch=x86-64&prod=chromiumcrx&prodchannel=unknown&prodversion=126.0.0.0&acceptformat=crx2,crx3&x=id%3D\(id)%26installsource%3Dondemand%26uc"
        guard let downloadURL = URL(string: downloadURLString) else {
            print("Invalid download URL.")
            return
        }

        guard let extensionsFolder = extensionsFolder else {
            print("Extensions folder not found.")
            return
        }

        let crxFileURL = extensionsFolder.appendingPathComponent("\(id).crx")
        let unzippedFolderURL = extensionsFolder.appendingPathComponent(
            name, isDirectory: true)

        do {
            // Download the CRX file
            let (tempLocalURL, _) = try await URLSession.shared.download(
                from: downloadURL)

            // Move the downloaded file to the destination
            try await moveDownloadedFile(from: tempLocalURL, to: crxFileURL)

            // Prepare and unzip the contents
            try await prepareUnzipDirectory(at: unzippedFolderURL)
            try await unzipFile(at: crxFileURL, to: unzippedFolderURL)

            print(
                "Extension successfully installed at \(unzippedFolderURL.path)")
        } catch {
            print("Error: \(error.localizedDescription)")
        }

        try? FileManager.default.removeItem(at: crxFileURL)
    }

    private static func moveDownloadedFile(
        from sourceURL: URL, to destinationURL: URL
    ) async throws {
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
    }

    private static func prepareUnzipDirectory(at url: URL) async throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.createDirectory(
            at: url, withIntermediateDirectories: true)
    }

    private static func unzipFile(at sourceURL: URL, to destinationURL: URL)
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
                        continuation.resume(
                            throwing: NSError(
                                domain: "UnzipError",
                                code: Int(process.terminationStatus),
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Unzip failed with exit code \(process.terminationStatus)"
                                ]
                            ))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

private func extractExtensionID(from urlString: String) -> String? {
    let components = urlString.split(separator: "/")
    guard let possibleID = components.last, possibleID.count == 32 else {
        return nil
    }
    return String(possibleID)
}

private func extractExtensionName(from urlString: String) -> String? {
    let components = urlString.split(separator: "/")
    guard components.count > 3 else { return nil }
    return String(components[3])
}
