//
//  AppDelegate.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-15.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import SwiftData
import SwiftUI
import WebKit

@MainActor
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
        guard let window = mainWindow else { return }
        for profile in window.profiles {
            profile.saveTabGroups()
        }
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
            with: AXSettingsView()
                .modelContainer(PersistenceController.shared),
            title: "Malvon Settings",
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
        }

        MainMenu.populateMainMenuAnimated()

        let newWindow = AXWindow(with: loadOrCreateProfiles())
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        mainWindow = newWindow
        return newWindow
    }

    /// Profiles come from SwiftData on launch. On a fresh install the
    /// store is empty, so we seed a single "Default" profile and let the
    /// user add more from Settings.
    private func loadOrCreateProfiles() -> [AXProfile] {
        let context = PersistenceController.shared.mainContext
        let descriptor = FetchDescriptor<MalvonProfile>(
            sortBy: [SortDescriptor(\.position)]
        )
        let models = (try? context.fetch(descriptor)) ?? []

        if models.isEmpty {
            return [AXProfile(name: "Default")]
        }
        return models.map { AXProfile(existing: $0) }
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

    /// Re-launches Malvon by spawning a new instance of the current executable
    /// and terminating this one. Used after settings flows (welcome, cookie import)
    /// that require a clean process state.
    static func relaunchApplication() {
        guard let executablePath = Bundle.main.executablePath else {
            mxPrint("Could not find the executable path")
            exit(1)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)

        do {
            try process.run()
        } catch {
            mxPrint("Failed to relaunch the application: \(error)")
            return
        }

        exit(0)
    }
}

func mxPrint(
    _ items: Any..., separator: String = " ", terminator: String = "\n"
) {
    #if DEBUG
        Swift.print(items, separator: separator, terminator: terminator)
    #endif
}
