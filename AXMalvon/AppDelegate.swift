//
//  AppDelegate.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let window = AXWindow()
    
    var aboutView: AXAboutView? = nil
    
    lazy var aboutViewWindow: NSWindow = AXAboutView.createAboutViewWindow()
    
    lazy var preferenceWindow = AXPreferenceWindow()
    
    // MARK: - Delegates
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        window.makeKeyAndOrderFront(nil)
        checkForUpdates()
    }
    
    func application(_ app: NSApplication, didDecodeRestorableState coder: NSCoder) {
        window.appProperties.tabManager.updateAll()
    }
    
    func application(_ app: NSApplication, willEncodeRestorableState coder: NSCoder) {
        if let window = app.keyWindow as? AXWindow {
            window.appProperties.saveProperties()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        if let window = NSApplication.shared.keyWindow as? AXWindow {
            window.appProperties.windowFrame = window.frame
            window.appProperties.saveProperties()
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
        if application.windows.count > 1 {
            if let window = application.keyWindow as? AXWindow {
                for url in urls {
                    window.appProperties.tabManager.createNewTab(url: url)
                }
            }
        } else {
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
            appProperties.tabManager.removeTab(appProperties.currentTab)
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
    
    @IBAction func closeWindow(_ sender: Any) {
        if let window = NSApplication.shared.keyWindow {
            window.close()
        }
    }
    
    // TODO: MINIMIZE BUTTON FUNCTIONALITY
    // https://stackoverflow.com/questions/33045075/minimize-miniaturize-cocoa-nswindow-without-titlebar
    @IBAction func minimizeWindow(_ sender: Any) {
        guard let window = NSApplication.shared.keyWindow as? AXWindow else { return }
        window.styleMask = window.styleMask.union(.miniaturizable)
        
        
        window.miniaturize(self)
        //        window.setIsMiniaturized(true)
        //        window.performMiniaturize(nil)
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
