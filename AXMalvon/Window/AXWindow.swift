//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXWindow: NSWindow, NSWindowDelegate {
    lazy var trafficLightManager = AXTrafficLightOverlayManager(window: self)
    let splitView = AXQuattroProgressSplitView()
    let containerView = AXWebContainerView()
    let sidebarView = AXSidebarView()

    lazy var searchBar = AXSearchBarWindow(parentWindow1: self)

    var profiles: [AXProfile] = [.init(name: "Default"), .init(name: "School")]
    var profileIndex = 0 {
        didSet {
            defaultProfile = profiles[profileIndex]
            self.sidebarView(didSelectTabGroup: 0)
        }
    }

    var defaultProfile: AXProfile

    var currentConfiguration: WKWebViewConfiguration {
        defaultProfile.configuration
    }

    var tabGroups: [AXTabGroup] {
        defaultProfile.tabGroups
    }

    var currentTabGroupIndex: Int {
        get {
            defaultProfile.currentTabGroupIndex
        }
        set {
            defaultProfile.currentTabGroupIndex = newValue
        }
    }

    var currentTabGroup: AXTabGroup {
        defaultProfile.currentTabGroup
    }

    init() {
        defaultProfile = profiles[profileIndex]
        super.init(
            contentRect: AXWindow.updateWindowFrame(),
            styleMask: [
                .closable, .titled, .resizable, .miniaturizable,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )
        self.animationBehavior = .documentWindow
        // Window Configurations
        self.titlebarAppearsTransparent = true
        trafficLightManager.updateTrafficLights()
        self.delegate = self
        backgroundColor = .textBackgroundColor  // NSWindow has hidden NSVisualEffectView, to remove we must use this code

        // Other Configurations
        splitView.addArrangedSubview(sidebarView)
        splitView.addArrangedSubview(containerView)
        sidebarView.delegate = self
        sidebarView.gestureView.delegate = self
        sidebarView.gestureView.popoverView.delegate = self
        containerView.delegate = self

        self.contentView = splitView
        sidebarView.frame.size.width = 180

        searchBar.searchBarDelegate = self
        self.sidebarView(didSelectTabGroup: 0)
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        let frameAsString = NSStringFromRect(self.frame)
        UserDefaults.standard.set(frameAsString, forKey: "windowFrame")
    }

    func toggleTabSidebar() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25  // Adjust duration as needed
            context.allowsImplicitAnimation = true

            if splitView.subviews.count == 2 {
                splitView.removeArrangedSubview(sidebarView)
                trafficLightManager.hideTrafficLights(true)
            } else {
                splitView.insertArrangedSubview(sidebarView, at: 0)
                trafficLightManager.hideTrafficLights(false)
            }

            splitView.layoutSubtreeIfNeeded()
        }
    }

    // MARK: Window Events
    func windowWillClose(_ notification: Notification) {
        defaultProfile.saveTabGroups()

        // Close all tabs
        tabGroups.forEach {
            $0.tabs.removeAll()
            $0.tabBarView?.removeFromSuperview()
            $0.tabBarView = nil
        }
    }

    func windowDidResize(_ notification: Notification) {
        trafficLightManager.updateTrafficLights()
    }

    override func mouseUp(with event: NSEvent) {
        // Double-click in title bar
        if event.clickCount >= 2
            && isPointInTitleBar(point: event.locationInWindow)
        {
            self.zoom(nil)
        }
        super.mouseUp(with: event)
    }

    override func otherMouseDown(with event: NSEvent) {
        let buttonNumber = event.buttonNumber

        switch buttonNumber {
        case 3:
            gestureView(didSwipe: .backwards)
        case 4:
            gestureView(didSwipe: .forwards)
        default: break
        }
    }

    fileprivate func isPointInTitleBar(point: CGPoint) -> Bool {
        if let windowFrame = self.contentView?.frame {
            let titleBarRect = NSRect(
                x: self.contentLayoutRect.origin.x,
                y: self.contentLayoutRect.origin.y
                    + self.contentLayoutRect.height,
                width: self.contentLayoutRect.width,
                height: windowFrame.height - self.contentLayoutRect.height)
            return titleBarRect.contains(point)
        }
        return false
    }

    static private func updateWindowFrame() -> NSRect {
        if let savedFrameString = UserDefaults.standard.string(
            forKey: "windowFrame")
        {
            return NSRectFromString(savedFrameString)
        } else {
            guard let screenFrame = NSScreen.main?.frame else {
                return NSMakeRect(100, 100, 800, 600)  // Default size
            }
            return NSMakeRect(
                100, 100, screenFrame.width / 2, screenFrame.height / 2)
        }
    }
}

// MARK: - Menu Bar Item Actions
extension AXWindow {
    @IBAction func downloadWebpage(_ sender: Any) {
        Task { @MainActor in
            if let webView = containerView.currentWebView, let url = webView.url {
                await webView.startDownload(using: URLRequest(url: url))
            }
        }
    }
    
    @IBAction func toggleSearchField(_ sender: Any) {
        searchBar.showCurrentURL()
    }

    @IBAction func toggleSearchBarForNewTab(_ sender: Any) {
        searchBar.show()
    }

    @IBAction func closeTab(_ sender: Any) {
        currentTabGroup.removeCurrentTab()
    }

    @IBAction func closeWindow(_ sender: Any) {
        self.close()
    }

    /// When creating a new window, a new tab group must be created. But the option to switch tab groups is always there. In addition, I believe that the [profiles] must be a static/singleton variable for the entire app. (not just local to the window).
    ///  We'll work on this later
    //    @IBAction func createNewWindow(_ sender: Any) {
    //        let window = AXWindow()
    //        window.makeKeyAndOrderFront(nil)
    //    }

    @IBAction func showReaderView(_ sender: Any) {
        // This code crashes the browser for some reason: toggleTabSidebar()
        guard let webView = containerView.currentWebView else { return }
        
        let readerScript = """
        (function() {
            let article = document.querySelector('article') ||
                          document.querySelector('main') ||
                          document.querySelector('[role="main"]') ||
                          document.body;
            return article ? article.innerHTML : null;
        })();
        """
        
        let css = """
        <style>
            body {
                font-family: -apple-system, Helvetica, Arial, sans-serif;
                line-height: 1.6;
                margin: 20px;
                background-color: #f8f8f8;
                color: #333;
            }
            img {
                max-width: 100%;
                height: auto;
            }
        </style>
        """

        webView.evaluateJavaScript(readerScript) { result, error in
            if let content = result as? String {
                //self.showReaderView(content: content)
                print("WebView reader content: \(content)")
                
                if let currentURL = webView.url {
                    webView.loadHTMLString(css + content, baseURL: currentURL)
                }
            } else {
                print("Error extracting content: \(String(describing: error))")
            }
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.keyCode {
            case 18:  // '1' key
                switchToTab(index: 0)
            case 19:  // '2' key
                switchToTab(index: 1)
            case 20:  // '3' key
                switchToTab(index: 2)
            case 21:  // '4' key
                switchToTab(index: 3)
            case 22:  // '5' key
                switchToTab(index: 4)
            case 23:  // '6' key
                switchToTab(index: 5)
            case 26:  // '7' key
                switchToTab(index: 6)
            default:
                break
            }
        } else {
            super.keyDown(with: event)
        }
    }

    func switchToTab(index: Int) {
        print("TAB GROUP COUNT: \(tabGroups.count)")

        // Check if the tab index is valid
        if index < currentTabGroup.tabs.count {
            // Hide all tabs
            currentTabGroup.switchTab(to: index)
        } else {
            guard currentTabGroup.tabs.count > 0 else { return }
            // Switch to the last tab if the index is out of range
            currentTabGroup.switchTab(to: currentTabGroup.tabs.count - 1)
        }
    }
}

// MARK: - Search Bar Delegate
extension AXWindow: AXSearchBarWindowDelegate {
    func searchBarDidAppear() {
        // Change contentView alpha value to 0.5
        splitView.alphaValue = 0.5
    }

    func searchBarDidDisappear() {
        // Change contentView alpha value to 1.0
        splitView.alphaValue = 1.0
    }

    func searchBarCreatesNewTab(with url: URL) {
        let webView = AXWebView(
            frame: .zero, configuration: currentConfiguration)
        webView.load(URLRequest(url: url))

        currentTabGroup.addTab(.init(title: "Google", webView: webView))
    }

    func searchBarUpdatesCurrentTab(with url: URL) {
        // Change current webview's url to new url
        currentTabGroup.tabs[currentTabGroup.selectedIndex].webView.load(
            URLRequest(url: url))
    }

    func searchBarCurrentWebsiteURL() -> String {
        // Returns the current web view's url
        self.containerView.currentWebView?.url?.absoluteString ?? ""
    }
}

// MARK: - WebContainer View Delegate
extension AXWindow: AXWebContainerViewDelegate {
    func webViewCreateWebView(config: WKWebViewConfiguration) -> WKWebView {
        let newWebView = AXWebView(frame: .zero, configuration: config)
        let tab = AXTab(
            title: newWebView.title ?? "Untitled Popup", webView: newWebView)

        currentTabGroup.addTab(tab)

        return newWebView
    }

    func webViewProgressDidChange(to: Double, _ smooth: Bool) {
        sidebarView.gestureView.progress = to

        if smooth {
            splitView.smoothProgress(to)
        } else {
            splitView.updateProgress(to)
        }
    }
}

// MARK: - Sidebar View Delegate
// TODO: - Move this code to the popover view
extension AXWindow: AXSideBarViewDelegate {
    func sidebarViewactiveTitle(changed to: String) {
        containerView.websiteTitleLabel.stringValue = to
    }
    
    func sidebarView(didSelectTabGroup tabGroupAt: Int) {
        self.currentTabGroupIndex = tabGroupAt
        sidebarView.changeShownTabBarGroup(currentTabGroup)

        print("SELECTED NEW TAB GROUP AT \(tabGroupAt)")
    }
}

// MARK: - Gesture View Delegate
extension AXWindow: AXGestureViewDelegate {
    func gestureView(didSwipe direction: AXGestureViewSwipeDirection!) {
        switch direction {
        case .backwards:
            containerView.currentWebView?.goBack()
        case .forwards:
            containerView.currentWebView?.goForward()
        case .reload:
            containerView.currentWebView?.reload()
        case .nothing, nil:
            break
        }
    }
}

// MARK: - Popover View Delegate
extension AXWindow: AXSidebarPopoverViewDelegate {
    func didSwitchProfile(to index: Int) {
        profileIndex = profileIndex == 1 ? 0 : 1
    }

    func popoverViewTabGroups() -> [AXTabGroup] {
        return self.defaultProfile.tabGroups
    }

    func updatedTabGroupName(at: Int, to: String) {
        tabGroups[at].name = to
    }

    func didSwitchTabGroup(to index: Int) {
        self.sidebarView(didSelectTabGroup: index)
    }

    func didAddTabGroup(_ newGroup: AXTabGroup) {
        // Switch to the new tab group
        self.defaultProfile.tabGroups.append(newGroup)
    }
}
