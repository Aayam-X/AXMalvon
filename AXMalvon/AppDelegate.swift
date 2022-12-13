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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        window.makeKeyAndOrderFront(nil)
        checkForUpdates()
    }
    
    func checkForUpdates() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        
        if let url = URL(string: "https://raw.githubusercontent.com/pdlashwin/update/main/latest.txt") {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        let contents = String(data: data, encoding: .utf8)
                        let trimmed = contents!.trimmingCharacters(in: .whitespacesAndNewlines)
                        
#if !DEBUG
                        if trimmed != appVersion {
                            self.showAlert(title: "New Update Avaliable!", description: "Version: \(trimmed)")
                        }
#endif
                    }
                } else {
                    self.showAlert(title: "Unable to check for updates", description: "Invalid Data")
                }
            }.resume()
        } else {
            showAlert(title: "Could not check for updates", description: "Developer used faulty URL string")
        }
    }
    
    func showAlert(title: String, description: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = description
        alert.addButton(withTitle: "Ok")
        alert.runModal()
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
    
    @IBAction func toggleSidebar(_ sender: Any) {
        (NSApplication.shared.keyWindow as? AXWindow)?.appProperties.sidebarView.toggleSidebar()
    }
    
    @IBAction func createNewTab(_ sender: Any) {
        let tabManager = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties.tabManager
        tabManager?.createNewTab()
    }
    
    @IBAction func removeCurrentTab(_ sender: Any) {
        let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.appProperties
        appProperties?.tabManager.removeTab(appProperties!.currentTab)
    }
    
    @IBAction func createNewWindow(_ sender: Any) {
        let window = AXWindow()
        window.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func createNewPrivateWindow(_ sender: Any) {
        let window = AXWindow()
        window.appProperties.isPrivate = true
        window.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func closeWindow(_ sender: Any) {
        if let window = NSApplication.shared.keyWindow {
            window.close()
        }
    }
    
}
