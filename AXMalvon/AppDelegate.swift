//
//  AppDelegate.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var aboutView: AXAboutView? = nil
    
    lazy var aboutViewWindow: NSWindow = AXAboutView.createAboutViewWindow()
    
    lazy var preferenceWindow = AXPreferenceWindow()
    
    // MARK: - App Delegates
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initializers
        AXHistory.checkIfFileExists()
        AXDownload.checkIfFileExists()
        checkForUpdates()
        
        // Create a window
        let window = AXWindow()
        window.makeKeyAndOrderFront(nil)
        window.appProperties.AX_profiles.forEach { profile in
            profile.retriveTabs()
        }
        
        if AXGlobalProperties.shared.userEmail == "" || AXGlobalProperties.shared.userPassword == "" {
            let welcomeWindow = NSWindow.create(styleMask: [.fullSizeContentView, .closable, .miniaturizable], size: .init(width: 500, height: 500))
            welcomeWindow.contentView = AXWelcomeView()
            window.beginSheet(welcomeWindow)
        } else {
            window.appProperties.contentView.checkIfBought()
        }
        //
        // Always show this dialogue at start, if they haven't purchased it of course!
        // let window1 = NSWindow.create(styleMask: [.fullSizeContentView, .closable, .miniaturizable], size: .init(width: 500, height: 500))
        // window1.contentView = AXPurchaseBrowserView()
        // window1.makeKeyAndOrderFront(nil)
    }
    
    func application(_ app: NSApplication, didDecodeRestorableState coder: NSCoder) {
        if let window = app.keyWindow as? AXWindow {
            window.appProperties.tabManager.updateAll()
        }
    }
    
    func application(_ app: NSApplication, willEncodeRestorableState coder: NSCoder) {
        if let window = app.keyWindow as? AXWindow {
            window.appProperties.saveProperties()
        }
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let appProperties = (NSApplication.shared.mainWindow as? AXWindow)?.appProperties {
            let names = appProperties.AX_profiles.map { $0.saveProperties(); return $0.name }
            UserDefaults.standard.set(names, forKey: "Profiles")
            
            appProperties.popOver.saveMostVisitedSites()
        }
        
        let alert = NSAlert()
        alert.messageText = "Do you want to quit Malvon"
        alert.informativeText = "Option to remove this alert will come in the future"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal() == .alertFirstButtonReturn
        
        // Testing2
        return response ? .terminateNow : .terminateCancel
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        AXHistory.removeDuplicates()
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        if let profiles = (NSApplication.shared.mainWindow as? AXWindow)?.appProperties.AX_profiles {
            let names = profiles.map { $0.saveProperties(); return $0.name }
            UserDefaults.standard.set(names, forKey: "Profiles")
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            createNewWindow(self)
            return true
        }
        
        return false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if application.windows.count != 0 {
            if let window = application.keyWindow as? AXWindow {
                for url in urls {
                    window.appProperties.tabManager.createNewTab(url: url)
                }
            }
        } else {
            let window = AXWindow()
            window.makeKeyAndOrderFront(nil)
            for url in urls {
                window.appProperties.tabManager.createNewTab(url: url)
            }
        }
    }
    
    // MARK: - Menu Bar Item Actions
    @IBAction func closeWindow(_ sender: Any) {
        if let window = NSApplication.shared.keyWindow {
            window.close()
        }
    }
    
    @IBAction func createNewPrivateWindow(_ sender: Any) {
        let window = AXWindow(isPrivate: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func createNewTab(_ sender: Any) {
        let tabManager = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties.tabManager
        tabManager?.openSearchBar()
    }
    
    @IBAction func createNewWindow(_ sender: Any) {
        let window = AXWindow()
        window.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func customAboutView(_ sender: Any) {
        if aboutView == nil {
            aboutView = AXAboutView()
            aboutViewWindow.contentView = aboutView
        }
        aboutViewWindow.center()
        aboutViewWindow.makeKeyAndOrderFront(self)
    }
    
    @IBAction func findInWebpage(_ sender: Any) {
        let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties
        appProperties?.webContainerView.showFindView()
    }
    
    @IBAction func keepWindowOnTop(_ sender: Any) {
        if let window = (NSApplication.shared.keyWindow as? AXWindow) {
            if window.level == .floating {
                window.level = .normal
            } else {
                window.level = .floating
            }
        }
    }
    
    @IBAction func removeCurrentTab(_ sender: Any) {
        guard let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties else { return }
        
        if appProperties.searchFieldShown {
            appProperties.popOver.close()
        } else {
            appProperties.tabManager.closeTab(appProperties.currentProfile.currentTab)
        }
    }
    
    @IBAction func restoreTab(_ sender: Any) {
        guard let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties else { return }
        appProperties.tabManager.restoreTab()
    }
    
    @IBAction func setAsDefaultBrowser(_ sender: Any) {
        setAsDefaultBrowser()
    }
    
    @IBAction func showHistory(_ sender: Any) {
        if let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties {
            let window = NSWindow.create(styleMask: [.closable, .miniaturizable, .resizable], size: .init(width: 500, height: 500))
            window.title = "History"
            window.contentView = AXHistoryView(appProperties: appProperties)
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @IBAction func showDownloads(_ sender: Any) {
        if let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties {
            let window = NSWindow.create(styleMask: [.closable, .miniaturizable, .resizable], size: .init(width: 500, height: 500))
            window.title = "Downloads"
            window.contentView = AXDownloadView(appProperties: appProperties)
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @IBAction func showPreferences(_ sender: Any) {
        preferenceWindow.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func showSearchField(_ sender: Any) {
        let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties
        appProperties?.popOver.newTabMode = false
        appProperties?.tabManager.showSearchField()
    }
    
    @IBAction func toggleSidebar(_ sender: Any) {
        (NSApplication.shared.keyWindow as? AXWindow)?.appProperties.sidebarView.toggleSidebar()
    }
    
    // MARK: - Functions
    
    func checkForUpdates() {
#if !DEBUG
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        
        if let url = URL(string: "https://raw.githubusercontent.com/pdlashwin/update/main/latest.txt") {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        let contents = String(data: data, encoding: .utf8)
                        let trimmed = contents!.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if trimmed != appVersion {
                            self.showAlert(title: "New Update Avaliable!", description: "Version: \(trimmed)")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Unable to check for updates", description: "Invalid Data")
                    }
                }
            }.resume()
        } else {
            showAlert(title: "Could not check for updates", description: "Developer used faulty URL string")
        }
#endif
    }
    
    func showAlert(title: String, description: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = description
        alert.addButton(withTitle: "Ok")
        alert.runModal()
    }
    
    func setAsDefaultBrowser() {
        let bundleID = Bundle.main.bundleIdentifier as CFString?
        
        if let bundleID = bundleID {
            LSSetDefaultHandlerForURLScheme("http" as CFString, bundleID)
            LSSetDefaultHandlerForURLScheme("https" as CFString, bundleID)
            LSSetDefaultHandlerForURLScheme("HTML document" as CFString, bundleID)
            LSSetDefaultHandlerForURLScheme("XHTML document" as CFString, bundleID)
        }
    }
}

extension AppDelegate: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(setAsDefaultBrowser(_:)) {
            let url = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://www.google.com")!)
            return url?.lastPathComponent != "Malvon.app"
        }
        
        return true
    }
}
