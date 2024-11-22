//
//  WebExtensionKit.swift
//  WebExtensionKit
//
//  Created by Ashwin Paudel on 2024-11-21.
//

import AppKit
import Foundation

/// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
class WebExtensionKit: NSObject, WebExtensionKitProtocol {
    func loadContentBlocker(
        at bundlePath: String, with reply: @escaping (URL?) -> Void
    ) {
        guard let bundle = Bundle(path: bundlePath) else {
            logAndReply(
                "Failed to load bundle from path: \(bundlePath)", reply: reply)
            return
        }

        guard let providerClass = bundle.principalClass as? NSObject.Type else {
            logAndReply("No principal class found in bundle.", reply: reply)
            return
        }

        let providerInstance = providerClass.init()
        let selector = NSSelectorFromString("blockerListPath")

        guard providerInstance.responds(to: selector),
            let result = providerInstance.perform(selector)?
                .takeUnretainedValue() as? URL?
        else {
            logAndReply(
                "Selector `blockerListPath` is missing or returned invalid data.",
                reply: reply)
            return
        }

        print("Found blocker list URL path: \(result)")
        reply(result)
    }

    private func logAndReply(_ message: String, reply: @escaping (URL?) -> Void)
    {
        print(message)
        reply(nil)
    }

    private func logAndReply(
        _ message: String, reply: @escaping (NSView?) -> Void
    ) {
        print(message)
        reply(nil)
    }

    //    func loadViewFromBundle(bundlePath: String, reply: @escaping (NSView?) -> Void) {
    //        guard let bundle = Bundle(path: bundlePath) else {
    //            print("Failed to load bundle at path: \(bundlePath)")
    //            reply(nil)
    //            return
    //        }
    //
    //        guard let providerClass = bundle.principalClass as? NSObject.Type else {
    //            print("Failed to find principal class in bundle.")
    //            reply(nil)
    //            return
    //        }
    //
    //        // Instantiate the provider class
    //        let providerInstance = providerClass.init()
    //
    //        // Perform the createView method dynamically using a selector
    //        let selector = NSSelectorFromString("createView")
    //
    //        if providerInstance.responds(to: selector) {
    //            if let view = providerInstance.perform(selector)?.takeUnretainedValue() as? NSView {
    //                reply(view)
    //                return
    //            }
    //        }
    //
    //        reply(nil)
    //    }
}
