//
//  AXExtensionsLoader.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-21.
//

import AppKit
import SwiftUI

class AXExtensionsLoader {
    static let shared = AXExtensionsLoader(
        extensionBundlePath: Bundle.main.resourceURL!.appendingPathComponent(
            "wBlock.mlx"
        ).absoluteString.replacingOccurrences(of: "file://", with: "")
    )

    private var service: WebExtensionKitProtocol?
    private var extensionBundlePath: String

    init(extensionBundlePath: String) {
        self.extensionBundlePath = extensionBundlePath

        let serviceName = "com.ayaamx.AXMalvon.WebExtensionKit"

        let connection = NSXPCConnection(serviceName: serviceName)
        connection.remoteObjectInterface = NSXPCInterface(
            with: WebExtensionKitProtocol.self)

        connection.resume()

        service =
            connection.remoteObjectProxyWithErrorHandler { error in
                print("XPC Service Error: \(error.localizedDescription)")
            } as? WebExtensionKitProtocol
    }

    func getContentBlockerURLPath(completion: @escaping (URL?) -> Void) {
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

    func createXPCConnection() {
        service?.performCalculation(
            firstNumber: 20, secondNumber: 10,
            with: { num in
                print("XPC Number Result: \(num)")
            })
    }

    func performCalculation(with message: XPCReceivedMessage) -> Encodable? {
        guard let request = try? message.decode(as: CalculationRequest.self)
        else { return nil }
        return CalcuationResponse(
            result: request.firstNumber + request.secondNumber)
    }
}

// A codable type that contains two numbers to add together.
struct CalculationRequest: Codable {
    let firstNumber: Int
    let secondNumber: Int
}

// A codable type that contains the result of the calculation.
struct CalcuationResponse: Codable {
    let result: Int
}
