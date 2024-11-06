//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

class AXWindow: NSWindow, NSWindowDelegate {
    var sessionProperties = AXSessionProperties()
    
    init() {
        super.init(
            contentRect: sessionProperties.windowFrame,
            styleMask: [.closable, .titled, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        // Window Configurations
        self.titlebarAppearsTransparent = true
        self.updateTrafficLights()
        self.delegate = self
        
        // Other Configurations
        sessionProperties.window = self
        
        let splitView = AXSplitView()
        splitView.addArrangedSubview(sessionProperties.sidebarView)
        splitView.addArrangedSubview(sessionProperties.containerView)
        
        self.contentView = splitView
        sessionProperties.sidebarView.frame.size.width = 180
    }
    
    // MARK: Window Events
    func windowDidResize(_ notification: Notification) {
        updateTrafficLights()
    }
    
    override func mouseUp(with event: NSEvent) {
        // Double-click in title bar
        if event.clickCount >= 2 && isPointInTitleBar(point: event.locationInWindow) {
            self.performZoom(nil)
        }
        super.mouseUp(with: event)
    }

    fileprivate func isPointInTitleBar(point: CGPoint) -> Bool {
        if let windowFrame = self.contentView?.frame {
            let titleBarRect = NSRect(x: self.contentLayoutRect.origin.x, y: self.contentLayoutRect.origin.y+self.contentLayoutRect.height, width: self.contentLayoutRect.width, height: windowFrame.height-self.contentLayoutRect.height)
            return titleBarRect.contains(point)
        }
        return false
    }
    
    // MARK: Traffic Light Functions
    fileprivate func hideTrafficLights(_ b: Bool) {
        standardWindowButton(.closeButton)?.isHidden = b
        standardWindowButton(.miniaturizeButton)!.isHidden = b
        standardWindowButton(.zoomButton)!.isHidden = b
    }
    
    
    fileprivate func updateTrafficLights() {
        let closeButton = standardWindowButton(.closeButton)!
        closeButton.frame.origin.x = 13.0
        closeButton.frame.origin.y = 0
        
        let miniaturizeButton = standardWindowButton(.miniaturizeButton)!
        miniaturizeButton.frame.origin.x = 33.0
        miniaturizeButton.frame.origin.y = 0
        
        let zoomButton = standardWindowButton(.zoomButton)!
        zoomButton.frame.origin.x = 53.0
        zoomButton.frame.origin.y = 0
    }
}

private class AXSplitView: NSSplitView, NSSplitViewDelegate {
    init() {
        super.init(frame: .zero)
        
        delegate = self
        isVertical = true
        dividerStyle = .thin
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 160
    }
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 500
    }
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        return view.tag == 0x01 ? false : true
    }
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }
}

extension AXWindow {
    // MARK: - Menu Bar Item Actions
    @IBAction func closeWindow(_ sender: Any) {
        self.close()
    }
    
    @IBAction func createNewTab(_ sender: Any) {
        sessionProperties.searchBarWindow.show()
    }
    
    @IBAction func createNewWindow(_ sender: Any) {
        let window = AXWindow()
        
        // Create new window and create blank window
//        window.sessionProperties.profiles.forEach { $0.retriveTabs() }
        
        window.makeKeyAndOrderFront(nil)
    }
//    
//    @IBAction func createNewBlankWindow(_ sender: Any) {
//        let window = AXWindow()
//        window.makeKeyAndOrderFront(nil)
//    }
//    
//    @IBAction func createNewPrivateWindow(_ sender: Any) {
//        let window = AXWindow(isPrivate: true)
//        window.makeKeyAndOrderFront(nil)
//    }
//    
//    @IBAction func customAboutView(_ sender: Any) {
//        if aboutView == nil {
//            aboutView = AXAboutView()
//            aboutViewWindow.contentView = aboutView
//        }
//        aboutViewWindow.center()
//        aboutViewWindow.makeKeyAndOrderFront(self)
//    }
//    
//    @IBAction func findInWebpage(_ sender: Any) {
//        let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.sessionProperties
//        appProperties?.webContainerView.showFindView()
//    }
//    
//    @IBAction func keepWindowOnTop(_ sender: Any) {
//        if let window = (NSApplication.shared.keyWindow as? AXWindow) {
//            if window.level == .floating {
//                window.level = .normal
//            } else {
//                window.level = .floating
//            }
//        }
//    }
//    
//    @IBAction func removeCurrentTab(_ sender: Any) {
//        guard let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.sessionProperties else { return }
//        
//        if appProperties.searchFieldShown {
//            appProperties.popOver.close()
//        } else {
//            appProperties.tabManager.closeTab(appProperties.currentProfile.currentTab)
//        }
//    }
//    
//    @IBAction func restoreTab(_ sender: Any) {
//        guard let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.sessionProperties else { return }
//        appProperties.tabManager.restoreTab()
//    }
//    
//    @IBAction func setAsDefaultBrowser(_ sender: Any) {
//        setAsDefaultBrowser()
//    }
//    
//    @IBAction func showHistory(_ sender: Any) {
//        if let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.sessionProperties {
//            let window = NSWindow.create(styleMask: [.closable, .miniaturizable, .resizable], size: .init(width: 500, height: 500))
//            window.title = "History"
//            window.contentView = AXHistoryView(appProperties: appProperties)
//            window.makeKeyAndOrderFront(nil)
//        }
//    }
//    
//    @IBAction func showDownloads(_ sender: Any) {
//        if let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.sessionProperties {
//            let window = NSWindow.create(styleMask: [.closable, .miniaturizable, .resizable], size: .init(width: 500, height: 500))
//            window.title = "Downloads"
//            window.contentView = AXDownloadView(appProperties: appProperties)
//            window.makeKeyAndOrderFront(nil)
//        }
//    }
//    
//    @IBAction func showPreferences(_ sender: Any) {
//        preferenceWindow.makeKeyAndOrderFront(nil)
//    }
//    
//    @IBAction func showSearchField(_ sender: Any) {
//        let appProperties = (NSApplication.shared.keyWindow as? AXWindow)?.sessionProperties
//        appProperties?.popOver.newTabMode = false
//        appProperties?.tabManager.showSearchField()
//    }
//    
//    @IBAction func toggleSidebar(_ sender: Any) {
//        (NSApplication.shared.keyWindow as? AXWindow)?.sessionProperties.sidebarView.toggleSidebar()
//    }
}
