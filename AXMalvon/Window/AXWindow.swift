//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXWindow: NSWindow, NSWindowDelegate {
    lazy var trafficLightManager = AXTrafficLightOverlayManager(window: self)
    lazy var searchBar = AXSearchBarWindow(parentWindow1: self)
    let splitView = AXQuattroProgressSplitView()
    let containerView = AXWebContainerView()
    let sidebarView = AXSidebarView()

    var hiddenSidebarView = false

    var profiles: [AXProfile]

    var defaultProfile: AXProfile
    var profileIndex = 0 {
        didSet {
            defaultProfile = profiles[profileIndex]
            self.sidebarView(
                didSelectTabGroup: defaultProfile.currentTabGroupIndex)
        }
    }

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

    private lazy var visualEffectView: NSVisualEffectView = {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .sidebar
        visualEffectView.wantsLayer = true

        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true

        #if DEBUG
            tintView.layer?.backgroundColor =
                NSColor.systemGray.withAlphaComponent(0.2).cgColor
        #else
            tintView.layer?.backgroundColor =
                NSColor.systemPink.withAlphaComponent(0.2).cgColor
        #endif

        // Add tint view on top of the visual effect view
        visualEffectView.addSubview(tintView)
        NSLayoutConstraint.activate([
            tintView.leadingAnchor.constraint(
                equalTo: visualEffectView.leadingAnchor),
            tintView.trailingAnchor.constraint(
                equalTo: visualEffectView.trailingAnchor),
            tintView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            tintView.bottomAnchor.constraint(
                equalTo: visualEffectView.bottomAnchor),
        ])

        return visualEffectView
    }()

    init(with profiles: [AXProfile]) {
        self.profiles = profiles
        defaultProfile = profiles[profileIndex]  // 0

        super.init(
            contentRect: AXWindow.updateWindowFrame(),
            styleMask: [
                .closable, .titled, .resizable, .miniaturizable,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )

        configureWindow()
        setupComponents()
    }

    private func configureWindow() {
        self.animationBehavior = .documentWindow
        self.titlebarAppearsTransparent = true
        self.backgroundColor = .textBackgroundColor
        self.isReleasedWhenClosed = true
        self.delegate = self
    }

    private func setupComponents() {
        self.contentView = visualEffectView
        splitView.frame = visualEffectView.bounds
        visualEffectView.addSubview(splitView)
        splitView.autoresizingMask = [.height, .width]

        splitView.addArrangedSubview(sidebarView)
        splitView.addArrangedSubview(containerView)

        sidebarView.frame.size.width = 180

        sidebarView.delegate = self
        sidebarView.gestureView.delegate = self
        sidebarView.gestureView.popoverView.delegate = self
        containerView.delegate = self
        searchBar.searchBarDelegate = self

        trafficLightManager.updateTrafficLights()
        currentTabGroupIndex = 0
    }

    // MARK: Window Events
    func windowWillEnterFullScreen(_ notification: Notification) {
        sidebarView.gestureView.tabGroupInfoViewLeftConstraint?.constant = 5
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        sidebarView.gestureView.tabGroupInfoViewLeftConstraint?.constant = 80
    }

    func windowWillClose(_ notification: Notification) {
        for profile in profiles {
            profile.saveTabGroups()

            for tabGroup in profile.tabGroups {
                tabGroup.tabs.removeAll()
                tabGroup.tabBarView?.removeFromSuperview()
                tabGroup.tabBarView = nil
            }
        }
    }

    func windowDidResize(_ notification: Notification) {
        trafficLightManager.updateTrafficLights()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        let frameAsString = NSStringFromRect(self.frame)
        UserDefaults.standard.set(frameAsString, forKey: "windowFrame")
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

        currentTabGroup.addTab(
            .init(title: webView.title ?? "Untitled Tab", webView: webView))
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
    func webContainerViewRequestsSidebar() -> AXSidebarView {
        return sidebarView
    }

    func webViewContainerUserHoveredForSidebar() -> AXSidebarView {
        return sidebarView
    }

    func webViewCreateWebView(config: WKWebViewConfiguration) -> WKWebView {
        let newWebView = AXWebView(frame: .zero, configuration: config)
        let tab = AXTab(
            title: newWebView.title ?? "Untitled Popup", webView: newWebView)

        currentTabGroup.addTab(tab)

        return newWebView
    }

    func webViewStartedLoading(with progress: Double) {
        splitView.beginAnimation(with: progress)
    }

    func webViewDidFinishLoading() {
        splitView.finishAnimation()
    }
}

// MARK: - Sidebar View Delegate
// TODO: - Move this code to the popover view
extension AXWindow: AXSideBarViewDelegate {
    func deactivatedTab() -> WKWebViewConfiguration? {
        return defaultProfile.configuration
    }

    func sidebarSwitchedTab(at: Int) {
        guard let tabs = sidebarView.currentTabGroup?.tabs else { return }

        if at == -1 {
            containerView.removeAllWebViews()
        } else {
            containerView.updateView(webView: tabs[at].webView)
        }
    }

    func sidebarViewactiveTitle(changed to: String) {
        containerView.websiteTitleLabel.stringValue = to
    }

    func sidebarView(didSelectTabGroup tabGroupAt: Int) {
        self.currentTabGroupIndex = tabGroupAt
        sidebarView.changeShownTabBarGroup(currentTabGroup)

        print("SELECTED NEW TAB GROUP AT \(tabGroupAt)")
    }

    func toggleTabSidebar() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25  // Adjust duration as needed
            context.allowsImplicitAnimation = true

            let sideBarWillCollapsed = splitView.subviews.count == 2
            if sideBarWillCollapsed {
                hiddenSidebarView = true
                splitView.removeArrangedSubview(sidebarView)
                trafficLightManager.hideTrafficLights(true)
            } else {
                hiddenSidebarView = false
                splitView.insertArrangedSubview(sidebarView, at: 0)
                trafficLightManager.hideTrafficLights(false)
            }

            containerView.sidebarCollapsed(
                sideBarWillCollapsed,
                isFullScreen: self.styleMask.contains(.fullScreen))
            splitView.layoutSubtreeIfNeeded()
        }
    }
}

// MARK: - Gesture View Delegate
extension AXWindow: AXGestureViewDelegate {
    func gestureViewMouseDown() {
        if hiddenSidebarView {
            toggleTabSidebar()
        }
    }

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

// MARK: - Menu Bar Actions
extension AXWindow {
    @IBAction func find(_ sender: Any) {
        containerView.webViewPerformSearch()
    }

    @IBAction func backWebpage(_ sender: Any) {
        containerView.currentWebView?.goBack()
    }

    @IBAction func forwardWebpage(_ sender: Any) {
        containerView.currentWebView?.goForward()
    }

    @IBAction func reloadWebpage(_ sender: Any) {
        containerView.currentWebView?.reload()
    }

    @IBAction func downloadWebpage(_ sender: Any) {
        Task { @MainActor in
            if let webView = containerView.currentWebView, let url = webView.url
            {
                await webView.startDownload(using: URLRequest(url: url))
            }
        }
    }

    @IBAction func enableContentBlockers(_ sender: Any) {
        defaultProfile.enableContentBlockers()
    }

    @IBAction func enableYouTubeAdBlocker(_ sender: Any) {
        if let sender = sender as? NSMenuItem {
            sender.title = "Disable YouTube Ad Blocker (Restart App)"
        }

        defaultProfile.enableYouTubeAdBlocker()
    }

    @IBAction func toggleSearchField(_ sender: Any) {
        if currentTabGroup.selectedIndex < 0 {
            searchBar.show()
        } else {
            searchBar.showCurrentURL()
        }
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

    @IBAction func showHideSidebar(_ sender: Any) {
        toggleTabSidebar()
    }

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
                    padding: 20vh 20vw;
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
            case 23:  // '5' key
                switchToTab(index: 4)
            case 22:  // '6' key
                switchToTab(index: 5)
            case 26:  // '7' key
                switchToTab(index: 6)
            case 28:  // '8' key
                switchToTab(index: 7)
            case 25:  // '9' key
                switchToTab(index: 7)
            default:
                break
            }
        } else {
            super.keyDown(with: event)
        }
    }

    func switchToTab(index: Int) {
        let count = currentTabGroup.tabs.count

        // Check if the tab index is valid
        if index < count {
            // Hide all tabs
            currentTabGroup.switchTab(to: index)
        } else {
            guard count > 0 else { return }
            // Switch to the last tab if the index is out of range
            currentTabGroup.switchTab(to: count - 1)
        }
    }
}
