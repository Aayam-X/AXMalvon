//
//  AXFavouritesModel.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-03.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Foundation

struct AXNewTabFavouriteSite: Codable {
    let title: String
    let url: String
}

class AXNewTabFavouritesManager {
    static let shared = AXNewTabFavouritesManager()
    private var sites: [AXNewTabFavouriteSite] = []
    private let dbPath: String

    private init() {
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

        dbPath = directoryURL.appendingPathComponent("bookmarks.json").path
        loadSites()
    }

    private func loadSites() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: dbPath))
        else {
            // Initialize with default sites if file doesn't exist
            sites = [
                AXNewTabFavouriteSite(
                    title: "Google", url: "https://www.google.com"),
                AXNewTabFavouriteSite(
                    title: "Gmail", url: "https://mail.google.com"),
                AXNewTabFavouriteSite(
                    title: "Mathematics",
                    url: "https://pdsb.elearningontario.ca/d2l/home/26235716"),
                AXNewTabFavouriteSite(
                    title: "ManageBac",
                    url: "https://turnerfenton.managebac.com/student"),
                AXNewTabFavouriteSite(
                    title: "Classroom", url: "https://classroom.google.com/"),
                AXNewTabFavouriteSite(
                    title: "Kognity",
                    url: "https://app.kognity.com/study/app/dashboard"),
            ]
            saveSites()
            return
        }

        sites =
            (try? JSONDecoder().decode([AXNewTabFavouriteSite].self, from: data))
            ?? []
    }

    private func saveSites() {
        guard let data = try? JSONEncoder().encode(sites) else { return }
        try? data.write(to: URL(fileURLWithPath: dbPath))
    }

    func getAllSites() -> [AXNewTabFavouriteSite] {
        return sites
    }

    func addSite(_ site: AXNewTabFavouriteSite) {
        sites.append(site)
        saveSites()
    }

    func updateSite(at index: Int, with site: AXNewTabFavouriteSite) {
        guard index < sites.count else { return }
        sites[index] = site
        saveSites()
    }

    func deleteSite(at index: Int) {
        guard index < sites.count else { return }
        sites.remove(at: index)
        saveSites()
    }
}
