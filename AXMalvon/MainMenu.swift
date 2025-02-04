//
//  MainMenu.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-01.
//

import AppKit

// Code from: https://www.lapcatsoftware.com/articles/working-without-a-nib-part-10.html

let applicationName = "Malvon"

// Apparently these aren't declared anywhere
@objc private protocol EditMenuActions {
    func redo(_ sender:AnyObject)
    func undo(_ sender:AnyObject)
}

// Define an array of tuples that contain the menu title and its corresponding population function.
// Adjust the submenu titles as needed (note that the Application menu might not display its title).
let menus: [(title: String, localizedTitle: String, populate: (NSMenu) -> Void)] = [
    ("File", NSLocalizedString("File", comment: "File menu"), MainMenu.populateFileMenu),
    ("Edit", NSLocalizedString("Edit", comment: "Edit menu"), MainMenu.populateEditMenu),
    ("View", NSLocalizedString("View", comment: "View menu"), MainMenu.populateViewMenu),
    ("Window", NSLocalizedString("Window", comment: "Window menu"), MainMenu.populateWindowMenu),
    ("Help", NSLocalizedString("Help", comment: "Help menu"), MainMenu.populateHelpMenu)
]

enum MainMenu {
    static func removeAllMainMenuItems() {
        NSApp.mainMenu?.removeAllItems()
        
        NSApp.mainMenu = createBaseMainMenu()
    }
    
    static func createBaseMainMenu(createsFileMenu: Bool = true) -> NSMenu {
        let mainMenu = NSMenu(title: "MainMenu")
        let menuItem = mainMenu.addItem(withTitle: "Application", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Application")
        MainMenu.populateApplicationMenu(submenu)
        mainMenu.setSubmenu(submenu, for: menuItem)
        
        if createsFileMenu {
            let fileItem = mainMenu.addItem(withTitle: "File", action: nil, keyEquivalent: "")
            let submenuFile = NSMenu(title: "File")
            MainMenu.populateFileMenu(submenuFile)
            mainMenu.setSubmenu(submenuFile, for: fileItem)
        }
        
        return mainMenu
    }
    
    static func populateMainMenuAnimated() {
        // Create an empty main menu and assign it immediately.
        let mainMenu = createBaseMainMenu(createsFileMenu: false)
        NSApp.mainMenu = mainMenu
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            for (index, menuInfo) in menus.enumerated() {
                let delay = DispatchTime.now() + 0.03 * Double(index)
                DispatchQueue.main.asyncAfter(deadline: delay) {
                    // Add the menu item to the main menu.
                    let menuItem = mainMenu.addItem(withTitle: menuInfo.title, action: nil, keyEquivalent: "")
                    
                    // Create and populate the submenu.
                    let submenu = NSMenu(title: menuInfo.localizedTitle)
                    menuInfo.populate(submenu)
                    mainMenu.setSubmenu(submenu, for: menuItem)
                    
                    // Special case: if this is the Window menu, set it as the application's windows menu.
                    if menuInfo.title == "Window" {
                        NSApp.windowsMenu = submenu
                    }
                }
            }
        }
    }
    
    
    static func populateApplicationMenu(_ menu: NSMenu) {
        // About AXMalvon
        var title = NSLocalizedString("About Malvon", comment: "About menu item")
        var menuItem = menu.addItem(withTitle: title, action: #selector(AppDelegate.showAboutView(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Check for Updates...
        title = NSLocalizedString("Check for Updates...", comment: "Check for Updates menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(AppDelegate.checkForUpdates(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Preferences…
        title = NSLocalizedString("Preferences…", comment: "Preferences menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(AppDelegate.showSettings(_:)), keyEquivalent: ",")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Services
        title = NSLocalizedString("Services", comment: "Services menu item")
        menuItem = menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: "Services")
        menu.setSubmenu(servicesMenu, for: menuItem)
        NSApp.servicesMenu = servicesMenu
        
        menu.addItem(NSMenuItem.separator())
        
        // Hide Malvon
        title = NSLocalizedString("Hide Malvon", comment: "Hide menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        menuItem.target = nil
        
        // Hide Others
        title = NSLocalizedString("Hide Others", comment: "Hide Others menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        menuItem.keyEquivalentModifierMask = [.command, .option]
        menuItem.target = nil
        
        // Show All
        title = NSLocalizedString("Show All", comment: "Show All menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit AXMalvon
        title = NSLocalizedString("Quit Malvon", comment: "Quit menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menuItem.target = nil
    }
    
    static func populateFileMenu(_ menu: NSMenu) {
        // New Tab
        var title = NSLocalizedString("New Tab", comment: "New Tab menu item")
        var menuItem = menu.addItem(withTitle: title, action: #selector(AXWindow.toggleSearchBarForNewTab(_:)), keyEquivalent: "t")
        menuItem.target = nil
        
        // Restore Tab
        title = NSLocalizedString("Restore Tab", comment: "Restore Tab menu item")
        menuItem = menu.addItem(withTitle: title, action: nil, keyEquivalent: "T")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // New Window
        title = NSLocalizedString("New Window", comment: "New Window menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(AppDelegate.newWindow(_:)), keyEquivalent: "n")
        menuItem.target = nil
        
        // New Private Window
        title = NSLocalizedString("New Private Window", comment: "New Private Window menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(AppDelegate.newPrivateWindow(_:)), keyEquivalent: "N")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Close Tab
        title = NSLocalizedString("Close Tab", comment: "Close Tab menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(AXWindow.closeTab(_:)), keyEquivalent: "w")
        menuItem.target = nil
        
        // Close Window
        title = NSLocalizedString("Close Window", comment: "Close Window menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(AXWindow.closeWindow(_:)), keyEquivalent: "W")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Open…
        title = NSLocalizedString("Open…", comment: "Open menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
        menuItem.target = nil
        
        // Open Recent
        title = NSLocalizedString("Open Recent", comment: "Open Recent menu item")
        menuItem = menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
        let openRecentMenu = NSMenu(title: "Open Recent")
        menu.setSubmenu(openRecentMenu, for: menuItem)
        let clearTitle = NSLocalizedString("Clear Menu", comment: "Clear Menu item")
        let clearItem = openRecentMenu.addItem(withTitle: clearTitle, action: #selector(NSDocumentController.clearRecentDocuments(_:)), keyEquivalent: "")
        clearItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Close
        title = NSLocalizedString("Close", comment: "Close menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        menuItem.target = nil
        
        // Save…
        title = NSLocalizedString("Save…", comment: "Save menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(AXWindow.downloadWebpage(_:)), keyEquivalent: "s")
        menuItem.target = nil
        
        // Save As…
        title = NSLocalizedString("Save As…", comment: "Save As menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSDocument.saveAs(_:)), keyEquivalent: "S")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Page Setup…
        title = NSLocalizedString("Page Setup…", comment: "Page Setup menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSApplication.runPageLayout(_:)), keyEquivalent: "P")
        menuItem.keyEquivalentModifierMask = [.command, .shift]
        menuItem.target = nil
        
        // Import from Chrome
        title = NSLocalizedString("Install Chrome Extension", comment: "Import from Chrome menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(AXWindow.installChromeExtension(_:)), keyEquivalent: "")
    }
    
    static func populateEditMenu(_ menu: NSMenu) {
        // Undo
        var title = NSLocalizedString("Undo", comment: "Undo menu item")
        var menuItem = menu.addItem(withTitle: title, action: #selector(EditMenuActions.undo(_:)), keyEquivalent: "z")
        menuItem.target = nil
        
        // Redo
        title = NSLocalizedString("Redo", comment: "Redo menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(EditMenuActions.redo(_:)), keyEquivalent: "Z")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Cut
        title = NSLocalizedString("Cut", comment: "Cut menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menuItem.target = nil
        
        // Copy
        title = NSLocalizedString("Copy", comment: "Copy menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menuItem.target = nil
        
        // Paste
        title = NSLocalizedString("Paste", comment: "Paste menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menuItem.target = nil
        
        // Paste and Match Style
        title = NSLocalizedString("Paste and Match Style", comment: "Paste and Match Style menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.pasteAsPlainText(_:)), keyEquivalent: "V")
        menuItem.keyEquivalentModifierMask = [.command, .option]
        menuItem.target = nil
        
        // Delete
        title = NSLocalizedString("Delete", comment: "Delete menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSText.delete(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Select All
        title = NSLocalizedString("Select All", comment: "Select All menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Find submenu
        title = NSLocalizedString("Find", comment: "Find menu item")
        menuItem = menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
        let findMenu = NSMenu(title: "Find")
        populateFindMenu(findMenu)
        menu.setSubmenu(findMenu, for: menuItem)
        
        // Spelling and Grammar submenu
        title = NSLocalizedString("Spelling and Grammar", comment: "Spelling and Grammar menu item")
        menuItem = menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
        let spellingMenu = NSMenu(title: "Spelling")
        populateSpellingMenu(spellingMenu)
        menu.setSubmenu(spellingMenu, for: menuItem)
        
        // Substitutions submenu
        title = NSLocalizedString("Substitutions", comment: "Substitutions menu item")
        menuItem = menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
        let substitutionsMenu = NSMenu(title: "Substitutions")
        populateSubstitutionsMenu(substitutionsMenu)
        menu.setSubmenu(substitutionsMenu, for: menuItem)
        
        // Transformations submenu
        title = NSLocalizedString("Transformations", comment: "Transformations menu item")
        menuItem = menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
        let transformationsMenu = NSMenu(title: "Transformations")
        populateTransformationsMenu(transformationsMenu)
        menu.setSubmenu(transformationsMenu, for: menuItem)
        
        // Speech submenu
        title = NSLocalizedString("Speech", comment: "Speech menu item")
        menuItem = menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
        let speechMenu = NSMenu(title: "Speech")
        populateSpeechMenu(speechMenu)
        menu.setSubmenu(speechMenu, for: menuItem)
    }
    
    static func populateFindMenu(_ menu: NSMenu) {
        var title = NSLocalizedString("Find…", comment:"Find… menu item")
        var menuItem = menu.addItem(withTitle:title, action:#selector(NSResponder.performTextFinderAction(_:)), keyEquivalent:"f")
        menuItem.tag = NSTextFinder.Action.showFindInterface.rawValue
        
        title = NSLocalizedString("Find Next", comment:"Find Next menu item")
        menuItem = menu.addItem(withTitle:title, action:#selector(NSResponder.performTextFinderAction(_:)), keyEquivalent:"g")
        menuItem.tag = NSTextFinder.Action.nextMatch.rawValue
        
        title = NSLocalizedString("Find Previous", comment:"Find Previous menu item")
        menuItem = menu.addItem(withTitle:title, action:#selector(NSResponder.performTextFinderAction(_:)), keyEquivalent:"G")
        menuItem.tag = NSTextFinder.Action.previousMatch.rawValue
        
        title = NSLocalizedString("Use Selection for Find", comment:"Use Selection for Find menu item")
        menuItem = menu.addItem(withTitle:title, action:#selector(NSResponder.performTextFinderAction(_:)), keyEquivalent:"e")
        menuItem.tag = NSTextFinder.Action.setSearchString.rawValue
        
        title = NSLocalizedString("Jump to Selection", comment:"Jump to Selection menu item")
        menu.addItem(withTitle:title, action:#selector(NSResponder.centerSelectionInVisibleArea(_:)), keyEquivalent:"j")
    }
    
    static func populateSpellingMenu(_ menu: NSMenu) {
        // Show Spelling and Grammar
        var title = NSLocalizedString("Show Spelling and Grammar", comment: "Show Spelling and Grammar menu item")
        var menuItem = menu.addItem(withTitle: title, action: #selector(NSText.showGuessPanel(_:)), keyEquivalent: ":")
        menuItem.target = nil
        
        // Check Document Now
        title = NSLocalizedString("Check Document Now", comment: "Check Document Now menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSText.checkSpelling(_:)), keyEquivalent: ";")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Check Spelling While Typing
        title = NSLocalizedString("Check Spelling While Typing", comment: "Check Spelling While Typing menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.toggleContinuousSpellChecking(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Check Grammar With Spelling
        title = NSLocalizedString("Check Grammar With Spelling", comment: "Check Grammar With Spelling menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.toggleGrammarChecking(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Correct Spelling Automatically
        title = NSLocalizedString("Correct Spelling Automatically", comment: "Correct Spelling Automatically menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.toggleAutomaticSpellingCorrection(_:)), keyEquivalent: "")
        menuItem.target = nil
    }
    
    static func populateSubstitutionsMenu(_ menu: NSMenu) {
        // Show Substitutions
        var title = NSLocalizedString("Show Substitutions", comment: "Show Substitutions menu item")
        var menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.orderFrontSubstitutionsPanel(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        menu.addItem(NSMenuItem.separator())
        
        // Smart Copy/Paste
        title = NSLocalizedString("Smart Copy/Paste", comment: "Smart Copy/Paste menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.toggleSmartInsertDelete(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Smart Quotes
        title = NSLocalizedString("Smart Quotes", comment: "Smart Quotes menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.toggleAutomaticQuoteSubstitution(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Smart Dashes
        title = NSLocalizedString("Smart Dashes", comment: "Smart Dashes menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.toggleAutomaticDashSubstitution(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Smart Links
        title = NSLocalizedString("Smart Links", comment: "Smart Links menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.toggleAutomaticLinkDetection(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Data Detectors
        title = NSLocalizedString("Data Detectors", comment: "Data Detectors menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.toggleAutomaticDataDetection(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Text Replacement
        title = NSLocalizedString("Text Replacement", comment: "Text Replacement menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.toggleAutomaticTextReplacement(_:)), keyEquivalent: "")
        menuItem.target = nil
    }
    
    static func populateTransformationsMenu(_ menu: NSMenu) {
        // Make Upper Case
        var title = NSLocalizedString("Make Upper Case", comment: "Make Upper Case menu item")
        var menuItem = menu.addItem(withTitle: title, action: #selector(NSResponder.uppercaseWord(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Make Lower Case
        title = NSLocalizedString("Make Lower Case", comment: "Make Lower Case menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSResponder.lowercaseWord(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Capitalize
        title = NSLocalizedString("Capitalize", comment: "Capitalize menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSResponder.capitalizeWord(_:)), keyEquivalent: "")
        menuItem.target = nil
    }
    
    static func populateSpeechMenu(_ menu: NSMenu) {
        // Start Speaking
        var title = NSLocalizedString("Start Speaking", comment: "Start Speaking menu item")
        var menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.startSpeaking(_:)), keyEquivalent: "")
        menuItem.target = nil
        
        // Stop Speaking
        title = NSLocalizedString("Stop Speaking", comment: "Stop Speaking menu item")
        menuItem = menu.addItem(withTitle: title, action: #selector(NSTextView.stopSpeaking(_:)), keyEquivalent: "")
        menuItem.target = nil
    }
    
    static func populateViewMenu(_ menu:NSMenu) {
        var title = NSLocalizedString("Show Toolbar", comment:"Show Toolbar menu item")
        var menuItem = menu.addItem(withTitle:title, action:#selector(NSWindow.toggleToolbarShown(_:)), keyEquivalent:"t")
        menuItem.keyEquivalentModifierMask = [.command, .option]
        
        title = NSLocalizedString("Customize Toolbar…", comment:"Customize Toolbar… menu item")
        menu.addItem(withTitle:title, action:#selector(NSWindow.runToolbarCustomizationPalette(_:)), keyEquivalent:"")
        
        title = NSLocalizedString("Toggle Sidebar", comment:"Show sidebar menu item")
        menuItem = menu.addItem(withTitle:title, action:#selector(NSSplitViewController.toggleSidebar(_:)), keyEquivalent:"s")
        menuItem.keyEquivalentModifierMask = [.command, .control]
        
        menu.addItem(NSMenuItem.separator())
        
        // Reload Webpage
        title = NSLocalizedString("Reload Webpage", comment:"Reloads the current webpage")
        menuItem = menu.addItem(withTitle:title, action:#selector(AXWindow.reloadWebpage(_:)), keyEquivalent:"r")
        menuItem.keyEquivalentModifierMask = [.command]
        
        // Backwards
        title = NSLocalizedString("Back", comment:"Current webpage will go back.")
        menuItem = menu.addItem(withTitle:title, action:#selector(AXWindow.backWebpage(_:)), keyEquivalent:"[")
        menuItem.keyEquivalentModifierMask = [.command]
        
        // Forwards
        title = NSLocalizedString("Forward", comment:"Current webpage will go forward.")
        menuItem = menu.addItem(withTitle:title, action:#selector(AXWindow.forwardWebpage(_:)), keyEquivalent:"]")
        menuItem.keyEquivalentModifierMask = [.command]
        
        // Forwards
        title = NSLocalizedString("Enable Content Blockers", comment:"This will turn on ad blockers for a better browsing experience.")
        menuItem = menu.addItem(withTitle:title, action:#selector(AXWindow.disableContentBlockers(_:)), keyEquivalent:"")
        
        menu.addItem(NSMenuItem.separator())
        
        // Open Location
        title = NSLocalizedString("Open Location", comment:"This will put the keyboard focus on the address bar")
        menuItem = menu.addItem(withTitle:title, action:#selector(AXWindow.toggleSearchField(_:)), keyEquivalent:"l")
        menuItem.keyEquivalentModifierMask = [.command]
        
        menu.addItem(NSMenuItem.separator())
        
        // Switch Tab Layout
        title = NSLocalizedString("Switch Tab Layout", comment:"This switches between vertical and horizontal tab layouts.")
        menuItem = menu.addItem(withTitle:title, action:#selector(AXWindow.switchViewLayout(_:)), keyEquivalent:"")
        
        // Enter full screen
        title = NSLocalizedString("Enter Full Screen", comment:"Enter Full Screen menu item")
        menuItem = menu.addItem(withTitle:title, action:#selector(NSWindow.toggleFullScreen(_:)), keyEquivalent:"f")
        menuItem.keyEquivalentModifierMask = [.command, .control]
    }
    
    static func populateWindowMenu(_ menu:NSMenu) {
        var title = NSLocalizedString("Minimize", comment:"Minimize menu item")
        menu.addItem(withTitle:title, action:#selector(NSWindow.performMiniaturize(_:)), keyEquivalent:"m")
        
        title = NSLocalizedString("Zoom", comment:"Zoom menu item")
        menu.addItem(withTitle:title, action:#selector(NSWindow.performZoom(_:)), keyEquivalent:"")
        
        menu.addItem(NSMenuItem.separator())
        
        title = NSLocalizedString("Bring All to Front", comment:"Bring All to Front menu item")
        let menuItem = menu.addItem(withTitle:title, action:#selector(NSApplication.arrangeInFront(_:)), keyEquivalent:"")
        menuItem.target = NSApp
    }
    
    static func populateHelpMenu(_ menu:NSMenu) {
        let title = applicationName + " " + NSLocalizedString("Help", comment:"Help menu item")
        let menuItem = menu.addItem(withTitle:title, action:#selector(NSApplication.showHelp(_:)), keyEquivalent:"?")
        menuItem.target = NSApp
    }
}
