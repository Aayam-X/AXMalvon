//
//  AppDelegate.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-15.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    let profiles: [AXProfile] = [
        .init(name: "Default"),
        .init(name: "School"),
    ]

    weak var window: AXWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Show Window
        window = AXWindow(with: profiles)
        window!.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        for profile in profiles {
            profile.saveTabGroups()
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool
    {
        return true
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication, hasVisibleWindows: Bool
    ) -> Bool {
        if window == nil {
            newWindow(nil)

            return true
        }

        window!.makeKeyAndOrderFront(nil)
        return true
    }

    @IBAction func newWindow(_ sender: Any?) {
        if window == nil {
            for profile in profiles {
                profile.loadTabGroups()
            }

            self.window = AXWindow(with: profiles)

            window!.makeKeyAndOrderFront(nil)
        }
    }

    @IBAction func newPrivateWindow(_ sender: Any?) {
        let window = AXWindow(with: [AXPrivateProfile()])
        window.makeKeyAndOrderFront(nil)
    }

    @IBAction func showAboutView(_ sender: Any?) {
        // Create the SwiftUI view
        let aboutView = AXAboutView()
        let hostingView = NSHostingView(rootView: aboutView)

        // Define the window size
        let windowWidth: CGFloat = 450
        let windowHeight: CGFloat = 250

        // Initialize the window
        let myWindow = NSWindow(
            contentRect: NSRect(
                x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.closable, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        // Set window properties
        myWindow.titlebarAppearsTransparent = true
        myWindow.contentView = hostingView
        myWindow.center()
        myWindow.makeKeyAndOrderFront(nil)
        myWindow.isReleasedWhenClosed = false
    }
}
