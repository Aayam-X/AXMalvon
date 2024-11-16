//
//  AppDelegate.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let window = AXWindow()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.makeKeyAndOrderFront(nil)
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
//        window.sessionProperties.tabManager.profiles.forEach { profile in
//            profile.saveAllTabGroups()
//        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

