//
//  AXSearchQueryToURL.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-01.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Foundation

private let fallbackURL = URL(string: "https://www.apple.com")!

class AXSearchQueryToURL {
    static let shared = AXSearchQueryToURL()
    weak var activeProfile: AXProfile?

    func convert(query: String) -> URL {
        // Section 1: Handle File URLs
        if query.starts(with: "malvon?") {
            return searchActionMalvonURL(query)
        } else if query.starts(with: "file:///") {
            return searchActionFileURL(query)
        } else if query.isValidURL() && !query.hasWhitespace() {
            /* Section 2: Handle Regular Search Terms */
            return searchActionURL(query, activeProfile: activeProfile)
        } else {
            return searchActionSearchTerm(query)
        }
    }
}

/// URL: malvon?
private func searchActionMalvonURL(_ value: String) -> URL {
    // FIXME: File URL Implementation
    /*
    if let resourceURL = Bundle.main.url(
        forResource: value.string(after: 7), withExtension: "html")
    {
        // appProperties.tabManager.createNewTab(fileURL: resourceURL)
    }
     */

    return fallbackURL
}

/// URL: file:///
private func searchActionFileURL(_ value: String) -> URL {
    return URL(string: value) ?? fallbackURL
}

/// URL: https://www.apple.com
private func searchActionURL(_ value: String, activeProfile: AXProfile?) -> URL
{
    guard let url = URL(string: value) else { return fallbackURL }

    if let activeProfile, activeProfile.name != "Private" {
        Task(priority: .background) {
            AXSearchDatabase.shared.incrementOccurrence(for: value)
        }
    }

    return url.fixURL()
}

/// Google Search Term
private func searchActionSearchTerm(_ value: String) -> URL {
    let searchQuery =
        value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        ?? ""
    let searchURL = URL(
        string:
            "https://www.google.com/search?client=Malvon&q=\(searchQuery)"
    )!.fixURL()

    return searchURL
}
