//
//  AXImageCache.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-03.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

@MainActor
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, NSImage>()

    private init() {}

    func getImage(forKey key: String) -> NSImage? {
        return cache.object(forKey: key as NSString)
    }

    func setImage(_ image: NSImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
