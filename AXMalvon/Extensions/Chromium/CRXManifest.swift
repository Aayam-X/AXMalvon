//
//  CRXManifest.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-03.
//

import Foundation

/*

 {
   "name": "Hello Extensions",
   "description": "Base Level Extension",
   "version": "1.0",
   "manifest_version": 3,
   "action": {
     "default_popup": "hello.html",
     "default_icon": "hello_extensions.png"
   }
 }

 */

struct CRXManifest: Codable {
    let manifestVersion: Int
    let name: String
    let version: String
    let description: String?

    // Additional Chrome manifest properties
    let background: Background?
    let permissions: [String]?
    let hostPermissions: [String]?
    let contentScripts: [ContentScript]?
    let icons: [String: String]?
    let action: Action?
    let optionsUI: OptionsUI?

    enum CodingKeys: String, CodingKey {
        case manifestVersion = "manifest_version"
        case name, version, description, background, permissions
        case hostPermissions = "host_permissions"
        case contentScripts = "content_scripts"
        case icons, action
        case optionsUI = "options_ui"
    }

    // Background configuration supports both MV3 (service_worker) and MV2 (scripts)
    struct Background: Codable {
        let serviceWorker: String?
        let scripts: [String]?

        enum CodingKeys: String, CodingKey {
            case serviceWorker = "service_worker"
            case scripts
        }
    }

    // Content script definition
    struct ContentScript: Codable {
        let matches: [String]
        let js: [String]?
        let css: [String]?
        let runAt: String?
        let allFrames: Bool?

        enum CodingKeys: String, CodingKey {
            case matches, js, css
            case runAt = "run_at"
            case allFrames = "all_frames"
        }
    }

    // Action (browser or page action) definition
    struct Action: Codable {
        let defaultIcon: DefaultIcon?
        let defaultTitle: String?
        let defaultPopup: String?

        enum CodingKeys: String, CodingKey {
            case defaultIcon = "default_icon"
            case defaultTitle = "default_title"
            case defaultPopup = "default_popup"
        }

        enum DefaultIcon: Codable {
            case string(String)
            case dictionary([String: String])

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                // Try to decode as dictionary first
                if let dict = try? container.decode([String: String].self) {
                    self = .dictionary(dict)
                    return
                }
                // Otherwise, try to decode as string
                if let str = try? container.decode(String.self) {
                    self = .string(str)
                    return
                }
                // If neither works, throw an error
                throw DecodingError.typeMismatch(
                    DefaultIcon.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription:
                            "Expected either a String or a [String: String] for default_icon."
                    ))
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let str):
                    try container.encode(str)
                case .dictionary(let dict):
                    try container.encode(dict)
                }
            }
        }
    }

    // Options UI configuration
    struct OptionsUI: Codable {
        let page: String?
        let openInTab: Bool?

        enum CodingKeys: String, CodingKey {
            case page
            case openInTab = "open_in_tab"
        }
    }
}
