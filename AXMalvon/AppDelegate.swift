//
//  AppDelegate.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

var AXMalvon_WebViewConfiguration: WKWebViewConfiguration = WKWebViewConfiguration()

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var aboutView: AXAboutView? = nil
    
    lazy var aboutViewWindow: NSWindow = AXAboutView.createAboutViewWindow()
    
    lazy var preferenceWindow = AXPreferenceWindow()
    
    // MARK: - Delegates
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AXMalvon_WebViewConfiguration.websiteDataStore = .nonPersistent()
        
        let profileNames = UserDefaults.standard.stringArray(forKey: "Profiles") ?? [.init("Default"), .init("Secondary")]
        let profiles = profileNames.map { AXBrowserProfile(name: $0) }
        AX_profiles.append(contentsOf: profiles)
        
        // Insert code here to initialize your application
        let window = AXWindow()
        window.appProperties.profileManager.switchProfiles(to: 0)
        window.makeKeyAndOrderFront(nil)
        
        AXHistory.checkIfFileExists()
        // let window0 = NSWindow.create(styleMask: [.fullSizeContentView, .closable, .miniaturizable], size: .init(width: 500, height: 500))
        // window0.contentView = AXWelcomeView()
        // window0.makeKeyAndOrderFront(nil)
        //
        // Always show this dialogue at start, if they haven't purchased it of course!
        // let window1 = NSWindow.create(styleMask: [.fullSizeContentView, .closable, .miniaturizable], size: .init(width: 500, height: 500))
        // window1.contentView = AXPurchaseBrowserView()
        // window1.makeKeyAndOrderFront(nil)
        
        checkForUpdates()
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
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        let names = AX_profiles.map { $0.saveProperties(); return $0.name }
        UserDefaults.standard.set(names, forKey: "Profiles")
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
    
    // MARK: - Menu Bar Actions
    
    @IBAction func findInWebpage(_ sender: Any) {
        let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties
        appProperties?.webContainerView.showFindView()
    }
    
    @IBAction func toggleSidebar(_ sender: Any) {
        (NSApplication.shared.keyWindow as? AXWindow)?.appProperties.sidebarView.toggleSidebar()
    }
    
    @IBAction func createNewTab(_ sender: Any) {
        let tabManager = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties.tabManager
        tabManager?.openSearchBar()
    }
    
    @IBAction func removeCurrentTab(_ sender: Any) {
        guard let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties else { return }
        
        if appProperties.searchFieldShown {
            appProperties.popOver.close()
        } else {
            appProperties.tabManager.closeTab(appProperties.currentTab)
        }
    }
    
    @IBAction func createNewWindow(_ sender: Any) {
        let window = AXWindow()
        window.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func createNewPrivateWindow(_ sender: Any) {
        let window = AXWindow(isPrivate: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func restoreTab(_ sender: Any) {
        guard let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties else { return }
        appProperties.tabManager.restoreTab()
    }
    
    @IBAction func closeWindow(_ sender: Any) {
        if let window = NSApplication.shared.keyWindow {
            window.close()
        }
    }
    
    @IBAction func showHistory(_ sender: Any) {
        if let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties {
            let window = NSWindow.create(styleMask: [.closable, .miniaturizable, .resizable], size: .init(width: 500, height: 500))
            window.title = "History"
            window.contentView = AXHistoryView(appProperties: appProperties)
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    
    @IBAction func showSearchField(_ sender: Any) {
        let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties
        appProperties?.popOver.newTabMode = false
        appProperties?.tabManager.showSearchField()
    }
    
    @IBAction func customAboutView(_ sender: Any) {
        if aboutView == nil {
            aboutView = AXAboutView()
            aboutViewWindow.contentView = aboutView
        }
        
        aboutViewWindow.setFrameOriginToPositionWindowInCenterOfScreen()
        aboutViewWindow.makeKeyAndOrderFront(self)
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
    
    @IBAction func setAsDefaultBrowser(_ sender: Any) {
        setAsDefaultBrowser()
    }
    
    
    @IBAction func showPreferences(_ sender: Any) {
        preferenceWindow.makeKeyAndOrderFront(nil)
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
