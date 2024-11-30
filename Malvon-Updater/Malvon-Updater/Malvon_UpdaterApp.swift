//
//  Malvon_UpdaterApp.swift
//  Malvon-Updater
//
//  Created by Ashwin Paudel on 2024-11-29.
//

import SwiftUI

@main
struct Malvon_UpdaterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onDisappear {
                    if NSApplication.shared.windows.isEmpty {
                        NSApplication.shared.terminate(nil)
                    }
                }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        return true
    }
}
