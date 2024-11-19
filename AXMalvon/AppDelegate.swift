//
//  AppDelegate.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-15.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    let window = AXWindow()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        window.close()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool
    {
        return true
    }

}
