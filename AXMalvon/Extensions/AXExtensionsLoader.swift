//
//  AXExtensionsLoader.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-21.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import SwiftUI

private let serviceName = "com.ayaamx.AXMalvon.WebExtensionKit"

class AXExtensionsLoader {
    internal var extensionBundlePath: String
    internal var service: WebExtensionKitProtocol?

    init(extensionBundlePath: String) {
        self.extensionBundlePath = extensionBundlePath

        // Establish an XPC connection
        let connection = NSXPCConnection(serviceName: serviceName)
        connection.remoteObjectInterface = NSXPCInterface(
            with: WebExtensionKitProtocol.self)

        connection.resume()

        // Create the proxy
        service =
            connection.remoteObjectProxyWithErrorHandler { error in
                print("XPC Service Error: \(error.localizedDescription)")
            } as? WebExtensionKitProtocol
    }

    func getContentBlockerURLPath(completion: @escaping (URL?) -> Void) {
        // Wrapper for the XPC proxy. Maybe this is not needed?
        service?.loadContentBlocker(
            at: extensionBundlePath,
            with: { contentBlockerJSONPath in
                completion(contentBlockerJSONPath)
            })
    }

    //    func loadContentBlocker(
    //    func loadBundleAndCreateView(bundlePath: String) -> NSView? {
    //        // Load the bundle from the given path
    //        guard let bundle = Bundle(path: bundlePath) else {
    //            print("Failed to load bundle from path: \(bundlePath)")
    //            return nil
    //        }
    //
    //        // Retrieve the principal class from the bundle
    //        guard let providerClass = bundle.principalClass as? NSObject.Type else {
    //            print("Failed to find principal class in bundle.")
    //            return nil
    //        }
    //
    //        // Dynamically initialize the provider class
    //        let providerInstance = providerClass.init()
    //
    //        // Perform the createView method dynamically using a selector
    //        let selector = NSSelectorFromString("createView")
    //
    //        if providerInstance.responds(to: selector) {
    //            if let view = providerInstance.perform(selector).takeUnretainedValue() as? NSView
    //            {
    //                return view
    //            }
    //        }
    //
    //        return nil
    //    }
    //
    //    static func testBundle() {
    //        AXExtensionsLoader.loadContentBlocker(bundlePath: "/Users/ashwinpaudel/Library/Developer/Xcode/DerivedData/MyExtension-gynaiylhtvzhxifwuecbhnjkotqo/Build/Products/Debug/MyExtension.bundle") { url in
    //            print("URL URL URL URL: \(url)")
    //        }
    //    }
    //
    //    static func loadContentBlocker(bundlePath: String, with reply: @escaping (URL?) -> Void) {
    //        let serviceName = "com.ayaamx.AXMalvon.WebExtensionKit"
    //
    //        do {
    //            // Connect to the XPC service
    //            let session = try XPCSession(xpcService: serviceName)
    //
    //            // Send request and receive reply
    //            let replyData = try session.sendSync(bundlePath)
    //
    //            if let response = try? replyData.decode(as: URL.self) {
    //                print("EXTENSION RESULT: \(response)")
    //                reply(response)
    //                return
    //            }
    //        } catch {
    //            print("Extension Error: \(error)")
    //            reply(nil)
    //        }
    //    }
}

// Try creating an ExtensionsManager class as a bonus :)
class AX_wBlockExtension: AXExtensionsLoader {
    init() {
        let fileURL = AX_wBlockExtension.fileURL

        // Check if bundle hasn't moved
        // FIXME: Instead download it from a repository rather than copying to bundle.
        if !FileManager.default.fileExists(atPath: fileURL.absoluteString) {
            let wBlockBundle = Bundle.main.resourceURL!.appendingPathComponent(
                "wBlock.mlx")

            try? FileManager.default.moveItem(at: wBlockBundle, to: fileURL)
            try? FileManager.default.removeItem(at: wBlockBundle)
        }

        super.init(extensionBundlePath: fileURL.path(percentEncoded: false))
    }

    override func getContentBlockerURLPath(completion: @escaping (URL?) -> Void)
    {
        print("PATH: \(extensionBundlePath)")
        service?.loadContentBlocker(
            at: extensionBundlePath,
            with: { contentBlockerJSONPath in
                completion(contentBlockerJSONPath)
            })
    }

    class var fileURL: URL {
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!

        let directoryURL = appSupportDirectory.appendingPathComponent(
            "Malvon", isDirectory: true)

        // Ensure the directory exists
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(
                at: directoryURL, withIntermediateDirectories: true,
                attributes: nil)
        }

        return directoryURL.appending(path: "wBlock.mlx")
    }

}
