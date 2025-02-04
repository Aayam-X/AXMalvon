//
//  CRXManifestModel.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-03.
//

import Foundation

struct CRXManifest: Codable {
    let manifestVersion: Int
    let name: String
    let version: String
    let description: String?

    // The background scripts/service worker definition.
    let background: Background?

    // Other optional fields (permissions, content_scripts, etc.) can be added here.

    // Map the JSON keys to Swift properties.
    enum CodingKeys: String, CodingKey {
        case manifestVersion = "manifest_version"
        case name
        case version
        case description
        case background
    }

    // Nested structure to represent background configuration.
    struct Background: Codable {
        // For Manifest V3, a single service worker script.
        let serviceWorker: String?
        // For Manifest V2, an array of scripts.
        let scripts: [String]?

        enum CodingKeys: String, CodingKey {
            case serviceWorker = "service_worker"
            case scripts
        }
    }
}
