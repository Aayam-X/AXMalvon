//
//  Helpers.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-29.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

// MARK: Extensions
extension URL {
    func fixURL() -> URL {
        var newURL = ""

        if isFileURL || (host != nil && scheme != nil) {
            return self
        }

        if scheme == nil {
            newURL += "https://"
        }

        if let host = host, host.contains("www") {
            newURL += "www.\(host)"
        }

        newURL += path
        newURL += query ?? ""
        return URL(string: newURL)!
    }
}

extension String {
    func isValidURL() -> Bool {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        if let match = detector.firstMatch(
            in: self, options: [],
            range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }

    func hasWhitespace() -> Bool {
        return rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }

    func string(after: Int) -> String {
        let index = self.index(startIndex, offsetBy: after)
        return String(self[index...])
    }
}
