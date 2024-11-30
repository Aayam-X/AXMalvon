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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let launchedBefore = UserDefaults.standard.bool(
            forKey: "launchedBefore")

        if launchedBefore {
            window = AXWindow(with: profiles)
            window!.makeKeyAndOrderFront(nil)

            ev()
        } else {
            // First Launch
            showWelcomeView()
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        }
    }

    // https://github.com/Lord-Kamina/SwiftDefaultApps#usage-notes
    func application(_ application: NSApplication, open urls: [URL]) {
        if let window = window {
            for url in urls {
                window.searchBarCreatesNewTab(with: url)
            }
        } else {
            window = AXWindow(with: profiles)
            window!.makeKeyAndOrderFront(nil)

            for url in urls {
                window!.searchBarCreatesNewTab(with: url)
            }
        }
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

    @MainActor
    private func ev() {
        Task {  // This ensures the function itself runs asynchronously
            guard
                let emailAddress = UserDefaults.standard.string(
                    forKey: "emailAddress")
            else {
                await ev_err()
                return
            }

            guard
                let url = URL(
                    string:
                        "https://malvon-beta.web.app/?user_exists=\(emailAddress)"
                )
            else {
                print("Invalid URL")
                await ev_err()
                return
            }

            print("User Email Address is: \(emailAddress)")

            let webView = WKWebView()
            let request = URLRequest(url: url)
            webView.load(request)

            let timeout: TimeInterval = 30
            let startTime = Date()

            do {
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
                        await ev_err()
                        return
                    }

                    // Pause before trying again
                    try await Task.sleep(for: .seconds(3))
                }
            } catch {
                print("Error during JavaScript evaluation: \(error)")
                await ev_err()
            }
        }
    }

    // Helper function to handle the email validation failure
    private func ev_err() async {
        await MainActor.run {
            UserDefaults.standard.set(false, forKey: "launchedBefore")
            AppDelegate.relaunchApplication()
        }
    }

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

    @IBAction func checkForUpdates(_ sender: Any?) {
        let fileManager = FileManager.default

        // Define the Application Support directory for Malvon
        let appSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let malvonDirectory = appSupportDirectory.appendingPathComponent(
            "Malvon", isDirectory: true)

        // Ensure the Malvon directory exists
        if !fileManager.fileExists(atPath: malvonDirectory.path) {
            try? fileManager.createDirectory(
                at: malvonDirectory, withIntermediateDirectories: true,
                attributes: nil)
        }

        // Define the destination path for Updater.app in the Application Support directory
        let updaterDestination = malvonDirectory.appendingPathComponent(
            "Malvon-Updater.app", isDirectory: true)

        guard
            let bundleUpdaterPath = Bundle.main.url(
                forAuxiliaryExecutable: "Malvon-Updater.app")
        else {
            print("Updater.app not found in the bundle's XPC folder.")
            return
        }

        // Check if the Updater.app exists in Application Support
        if !fileManager.fileExists(atPath: updaterDestination.path) {
            // If it doesn't exist, copy it from the bundle's XPC folder
            do {
                try fileManager.copyItem(
                    at: bundleUpdaterPath, to: updaterDestination)
                try fileManager.removeItem(at: bundleUpdaterPath)
                print("Updater.app copied to Application Support.")
            } catch {
                print(
                    "Failed to copy Malvon-Updater.app: \(error.localizedDescription)"
                )
                return
            }
        } else {
            do {
                _ = try fileManager.replaceItemAt(
                    updaterDestination, withItemAt: bundleUpdaterPath)
                try fileManager.removeItem(at: bundleUpdaterPath)
            } catch {
                print(
                    "Problem with replacing updater service: \(error.localizedDescription)"
                )
            }
        }

        let workspace = NSWorkspace.shared
        let updaterAppURL = updaterDestination

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        workspace.openApplication(
            at: updaterAppURL, configuration: configuration
        ) { _, _ in

        }
        print("Updater.app deleted from Application Support.")
    }

}
