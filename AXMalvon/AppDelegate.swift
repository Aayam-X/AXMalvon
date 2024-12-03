//
//  AppDelegate.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-15.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Cocoa
import SwiftUI
import WebKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    let profiles: [AXProfile] = [
        .init(name: "Default"),
        .init(name: "School"),
    ]

    weak var window: AXWindow?
    static var searchBar = AXSearchBarWindow()
    let launchedBefore = UserDefaults.standard.bool(
        forKey: "launchedBefore")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if launchedBefore {
            window = AXWindow(with: profiles)
            window!.makeKeyAndOrderFront(nil)

            ev()
            bgU_Check()
        } else {
            // First Launch
            showWelcomeView()
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        }
    }

    // https://github.com/Lord-Kamina/SwiftDefaultApps#usage-notes
    func application(_ application: NSApplication, open urls: [URL]) {
        guard launchedBefore else { return }
        ev()

        // Reuse the existing window if it's already created.
        if let firstWindow = application.keyWindow as? AXWindow {
            for url in urls {
                firstWindow.searchBarCreatesNewTab(with: url)
            }
        }

        //        else {
        //            window = AXWindow(with: profiles)
        //            window!.makeKeyAndOrderFront(nil)
        //
        //            for url in urls {
        //                window!.searchBarCreatesNewTab(with: url)
        //            }
        //        }
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
        guard launchedBefore else { return false }
        if window == nil {
            newWindow(nil)

            return true
        }

        window!.makeKeyAndOrderFront(nil)
        return true
    }

    @IBAction func toggleSearchField(_ sender: Any) {
        guard let keyWindow = NSApplication.shared.keyWindow as? AXWindow else {
            return
        }
        AppDelegate.searchBar.parentWindow1 = keyWindow
        AppDelegate.searchBar.searchBarDelegate = keyWindow

        if keyWindow.currentTabGroup.selectedIndex < 0 {
            AppDelegate.searchBar.show()
        } else {
            AppDelegate.searchBar.showCurrentURL()
        }
    }

    @IBAction func toggleSearchBarForNewTab(_ sender: Any) {
        guard let keyWindow = NSApplication.shared.keyWindow as? AXWindow else {
            return
        }
        AppDelegate.searchBar.parentWindow1 = keyWindow
        AppDelegate.searchBar.searchBarDelegate = keyWindow

        AppDelegate.searchBar.show()
    }

    @IBAction func reportFeedback(_ sender: Any?) {
        // Define the window size and position
        let windowRect = NSRect(x: 100, y: 100, width: 600, height: 400)

        // Create the NSWindow
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false

        // Set the title of the window
        window.title = "Feedback Reporter"

        // Create the SwiftUI feedback reporter view
        let feedbackReporterView = AXFeedbackReporterView()
        let hostingView = NSHostingView(rootView: feedbackReporterView)

        // Embed the SwiftUI view in the NSWindow
        window.contentView = hostingView

        // Display the window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    @IBAction func newWindow(_ sender: Any?) {
        guard launchedBefore else { return }
        ev()

        if window == nil {
            for profile in profiles {
                profile.loadTabGroups()
            }

            self.window = AXWindow(with: profiles)

            window!.makeKeyAndOrderFront(nil)
        }
    }

    @IBAction func newPrivateWindow(_ sender: Any?) {
        guard launchedBefore else { return }
        ev()

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

    private func showWelcomeView() {
        // Define the window size and position
        let windowRect = NSRect(x: 100, y: 100, width: 600, height: 400)

        // Create the NSWindow
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false

        // Set the title of the window
        window.title = "Welcome to Malvon"

        // Create the SwiftUI feedback reporter view
        let aXWelcomeView = AXWelcomeView()
        let hostingView = NSHostingView(rootView: aXWelcomeView)

        // Embed the SwiftUI view in the NSWindow
        window.contentView = hostingView

        // Display the window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Other Functions

    /// Check if email address is valid:
    @MainActor
    private func ev() {
        Task {
            guard
                let emailAddress = UserDefaults.standard.string(
                    forKey: "emailAddress")
            else {
                ev_err()
                return
            }

            guard
                let url = URL(
                    string:
                        "https://malvon-beta.web.app/?user_exists=\(emailAddress)"
                )
            else {
                print("Invalid URL")
                ev_err()
                return
            }

            print("User Email Address is: \(emailAddress)")

            let webView = WKWebView()
            let request = URLRequest(url: url)
            webView.load(request)

            let timeout: TimeInterval = 30
            let startTime = Date()

            do {
                try await Task.sleep(for: .seconds(2))

                // Perform the checking process asynchronously
                while true {
                    let result = try await webView.evaluateJavaScript(
                        "document.body.innerText")

                    if let result = result as? String,
                        result.lowercased() == "yes"
                    {
                        print("Email is valid!!!")
                        break
                    } else {
                        print("Failed to verify email; try again.")
                    }

                    if Date().timeIntervalSince(startTime) > timeout {
                        print("Email Verification Process Timed Out.")
                        ev_err()
                        return
                    }

                    // Pause before trying again
                    try await Task.sleep(for: .seconds(3))
                }
            } catch {
                print("Error during JavaScript evaluation: \(error)")
                ev_err()
            }
        }
    }

    // Helper function to handle the email validation failure
    private func ev_err() {
        DispatchQueue.main.async {
            UserDefaults.standard.set(false, forKey: "launchedBefore")
            AppDelegate.relaunchApplication()
        }
    }

    @IBAction func checkForUpdates(_ sender: Any?) {
        ensureUpdaterExists()
        launchUpdater()
    }
}

extension AppDelegate {
    // Relaunch Malvon
    static func relaunchApplication() {
        guard let executablePath = Bundle.main.executablePath else {
            print("Could not find the executable path")
            exit(1)
        }

        // Launch a new instance of the app
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)

        do {
            try process.run()  // Start the new instance
        } catch {
            print("Failed to relaunch the application: \(error)")
            return
        }

        // Terminate the current instance
        exit(1)
    }

    /// Background Update Check
    private func bgU_Check() {
        DispatchQueue.global(qos: .background).async {
            guard
                let bgURL = URL(
                    string:
                        "https://raw.githubusercontent.com/ashp0/malvon-website/refs/heads/main/.github/workflows/version.txt"
                )
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
            print("Updater.app not found in Application Support.")
            return
        }

        let workspace = NSWorkspace.shared
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        workspace.openApplication(
            at: updaterAppURL, configuration: configuration
        ) { success, error in
            if success != nil {
                print("Updater.app launched successfully.")
            } else if let error = error {
                print(
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
            print("Updater.app not found in bundle.")
            return
        }

        do {
            if !fileManager.fileExists(atPath: updaterDestination.path) {
                // Copy updater app if it doesn't exist in Application Support
                try fileManager.copyItem(
                    at: bundleUpdaterPath, to: updaterDestination)
                print("Updater.app copied to Application Support.")
            } else {
                // Replace existing updater app
                _ = try fileManager.replaceItemAt(
                    updaterDestination, withItemAt: bundleUpdaterPath)
                print("Updater.app replaced in Application Support.")
            }

            // Remove original updater app from bundle
            try fileManager.removeItem(at: bundleUpdaterPath)
        } catch {
            print("Failed to manage Updater.app: \(error.localizedDescription)")
        }
    }
}
