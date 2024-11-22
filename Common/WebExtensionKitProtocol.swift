//
//  WebExtensionKitProtocol.swift
//  WebExtensionKit
//
//  Created by Ashwin Paudel on 2024-11-21.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

/// The protocol that this service will vend as its API. This protocol will also need to be visible to the process hosting the service.
@objc protocol WebExtensionKitProtocol {

    /// Replies with the contentBlocker.json path
    func loadContentBlocker(
        at bundlePath: String, with reply: @escaping (URL?) -> Void)
}

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     connectionToService = NSXPCConnection(serviceName: "com.ayaamx.AXMalvon.WebExtensionKit")
     connectionToService.remoteObjectInterface = NSXPCInterface(with: WebExtensionKitProtocol.self)
     connectionToService.resume()

 Once you have a connection to the service, you can use it like this:

     if let proxy = connectionToService.remoteObjectProxy as? WebExtensionKitProtocol {
         proxy.performCalculation(firstNumber: 23, secondNumber: 19) { result in
             NSLog("Result of calculation is: \(result)")
         }
     }

 And, when you are finished with the service, clean up the connection like this:

     connectionToService.invalidate()
*/
