//
//  AppDelegate.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-15.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import SwiftUI
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindow: AXWindow?

    let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if launchedBefore {
            presentNewWindowIfNeeded()
        } else {
            // First Launch
            showWelcomeView()
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        }

        MainMenu.populateMainMenuAnimated()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard launchedBefore else { return }

        if let window = mainWindow {
            for url in urls {
                window.searchBarCreatesNewTab(with: url)
            }
        } else {
            let window = presentNewWindowIfNeeded()
            for url in urls {
                window.searchBarCreatesNewTab(with: url)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Save profiles
        //        for profile in AppDelegate.profiles {
        //            profile.saveTabGroups()
        //            profile.historyManager?.flushAndClose()
        //        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool
    {
        return false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication, hasVisibleWindows: Bool
    ) -> Bool {
        guard launchedBefore else { return false }

        if !hasVisibleWindows {
            presentNewWindowIfNeeded()
        }

        return true
    }

    @IBAction func newWindow(_ sender: Any?) {
        guard launchedBefore else { return }
        presentNewWindowIfNeeded()
    }

    //    var privateWindow: AXWindow?

    @IBAction func newPrivateWindow(_ sender: Any?) {
        guard launchedBefore else { return }

        let privateProfile = AXPrivateProfile()
        let privateWindow = AXWindow(with: [privateProfile])
        privateWindow.isReleasedWhenClosed = false
        privateWindow.makeKeyAndOrderFront(nil)
    }

    @IBAction func reportFeedback(_ sender: Any?) {
        createSwiftUIWindow(
            with: AXFeedbackReporterView(), title: "Feedback Reporter",
            size: .init(width: 600, height: 400))
    }

    @IBAction func showSettings(_ sender: Any?) {
        createSwiftUIWindow(
            with: AXSettingsView(), title: "Malvon Settings",
            size: .init(width: 600, height: 500))
    }

    @IBAction func showAboutView(_ sender: Any?) {
        createSwiftUIWindow(
            with: AXAboutView(), title: "About Malvon",
            size: .init(width: 450, height: 250))
    }

    private func showWelcomeView() {
        createSwiftUIWindow(with: AXWelcomeView(), title: "Welcome to Malvon")
    }

    // MARK: - Other Functions
    @discardableResult
    private func presentNewWindowIfNeeded() -> AXWindow {
        if let existingWindow = mainWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            return existingWindow
        } else {
            MainMenu.populateMainMenuAnimated()

            let profiles: [AXProfile] = [
                .init(name: "Default"),
                .init(name: "School"),
            ]

            let newWindow = AXWindow(with: profiles)
            newWindow.isReleasedWhenClosed = false
            newWindow.makeKeyAndOrderFront(nil)
            mainWindow = newWindow
            return newWindow
        }
    }

    private func createSwiftUIWindow(
        with view: some View, title: String,
        size: CGSize = .init(width: 600, height: 400)
    ) {
        // Create the NSWindow
        let window = NSWindow(
            contentRect: NSRect.init(origin: .zero, size: size),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.title = title

        // Embed the SwiftUI View
        let hostingView = NSHostingView(rootView: view)
        window.contentView = hostingView

        // Display the window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    @IBAction func checkForUpdates(_ sender: Any?) {
        ensureUpdaterExists()
        launchUpdater()
    }
}

// MARK: - Malvon Updater
extension AppDelegate {
    // Relaunch Malvon
    static func relaunchApplication() {
        guard let executablePath = Bundle.main.executablePath else {
            mxPrint("Could not find the executable path")
            exit(1)
        }

        // Launch a new instance of the app
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)

        do {
            try process.run()  // Start the new instance
        } catch {
            mxPrint("Failed to relaunch the application: \(error)")
            return
        }

        // Terminate the current instance
        exit(1)
    }

    /// Background Update Check
    private func bgU_Check() {
        DispatchQueue.global(qos: .background).async {
            guard
                let bgURL = URL(string: updateURLString)
            else { return }

            let content = try? String(contentsOf: bgURL, encoding: .utf8)

            guard
                let currentVersion = Bundle.main.infoDictionary?[
                    "CFBundleShortVersionString"] as? String,
                let latestVersion = content
            else { return }

            if currentVersion.trimmingCharacters(in: .whitespacesAndNewlines)
                != latestVersion.trimmingCharacters(in: .whitespacesAndNewlines)
            {
                DispatchQueue.main.async {
                    self.bgU_alert()
                }
            }
        }
    }

    /// Shows an alert asking the user if they would like to update.
    func bgU_alert() {
        let alert = NSAlert()
        alert.messageText = "New Version Available"
        alert.addButton(withTitle: "Update Now")  // Index 0
        alert.addButton(withTitle: "Cancel")  // Index 1
        alert.informativeText =
            "A new version of Malvon is available. Would you like to update now?"

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {  // First button is "Update Now"
            launchUpdater()
        }
    }

    // Launches the updater app from the Application Support directory
    private func launchUpdater() {
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let malvonDirectory = appSupportDirectory.appendingPathComponent(
            "Malvon",
            isDirectory: true
        )
        let updaterAppURL = malvonDirectory.appendingPathComponent(
            "Malvon-Updater.app")

        guard fileManager.fileExists(atPath: updaterAppURL.path) else {
            mxPrint("Updater.app not found in Application Support.")
            return
        }

        let workspace = NSWorkspace.shared
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        workspace.openApplication(
            at: updaterAppURL, configuration: configuration
        ) { success, error in
            if success != nil {
                mxPrint("Updater.app launched successfully.")
            } else if let error = error {
                mxPrint(
                    "Failed to launch Updater.app: \(error.localizedDescription)"
                )
            }
        }
    }

    // Ensures that the Malvon directory and the updater app exist in the Application Support directory
    private func ensureUpdaterExists() {
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let malvonDirectory = appSupportDirectory.appendingPathComponent(
            "Malvon",
            isDirectory: true
        )

        // Ensure the Malvon directory exists
        if !fileManager.fileExists(atPath: malvonDirectory.path) {
            try? fileManager.createDirectory(
                at: malvonDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        let updaterDestination = malvonDirectory.appendingPathComponent(
            "Malvon-Updater.app",
            isDirectory: true
        )

        guard
            let bundleUpdaterPath = Bundle.main.url(
                forAuxiliaryExecutable: "Malvon-Updater.app")
        else {
            mxPrint("Updater.app not found in bundle.")
            return
        }

        do {
            if !fileManager.fileExists(atPath: updaterDestination.path) {
                // Copy updater app if it doesn't exist in Application Support
                try fileManager.copyItem(
                    at: bundleUpdaterPath, to: updaterDestination)
                mxPrint("Updater.app copied to Application Support.")
            } else {
                // Replace existing updater app
                _ = try fileManager.replaceItemAt(
                    updaterDestination, withItemAt: bundleUpdaterPath)
                mxPrint("Updater.app replaced in Application Support.")
            }

            // Remove original updater app from bundle
            try fileManager.removeItem(at: bundleUpdaterPath)
        } catch {
            mxPrint(
                "Failed to manage Updater.app: \(error.localizedDescription)")
        }
    }
}

func mxPrint(
    _ items: Any..., separator: String = " ", terminator: String = "\n"
) {
    #if DEBUG
        Swift.print(items, separator: separator, terminator: terminator)
    #endif
}

private let updateURLString =
    "https://raw.githubusercontent.com/ashp0/malvon-website/refs/heads/main/.github/workflows/version.txt"
