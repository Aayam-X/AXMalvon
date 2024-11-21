//
//  AXExtensionsLoader.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-21.
//

import AppKit
import SwiftUI

class AXExtensionsLoader {
    func loadBundleAndCreateView(bundlePath: String) -> NSView? {
        // Load the bundle from the given path
        guard let bundle = Bundle(path: bundlePath) else {
            print("Failed to load bundle from path: \(bundlePath)")
            return nil
        }

        // Retrieve the principal class from the bundle
        guard let providerClass = bundle.principalClass as? NSObject.Type else {
            print("Failed to find principal class in bundle.")
            return nil
        }

        // Dynamically initialize the provider class
        let providerInstance = providerClass.init()

        // Perform the createView method dynamically using a selector
        let selector = NSSelectorFromString("createView")

        if providerInstance.responds(to: selector) {
            if let view = providerInstance.perform(selector).takeUnretainedValue() as? NSView
            {
                return view
            }
        }

        return nil
    }

    static func testBundle() -> NSView? {
        let loader = AXExtensionsLoader()
        if let friendsView = loader.loadBundleAndCreateView(
            bundlePath:
                "/Users/ashwinpaudel/Library/Developer/Xcode/DerivedData/MyExtension-gynaiylhtvzhxifwuecbhnjkotqo/Build/Products/Debug/MyExtension.bundle"
        ) {
            //someParentView.addSubview(friendsView)
            print("FOUND FRIENDS VIEWWWWWW")
            return friendsView
        }

        return nil
    }
}
