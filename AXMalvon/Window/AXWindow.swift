//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import SecurityInterface
import WebKit

// MARK: - AXWindow
class AXWindow: NSWindow, NSWindowDelegate,
    AXWebContainerViewDelegate, AXTabBarViewDelegate, AXTabHostingViewDelegate
{
    // Window Defaults
    lazy var usesVerticalTabs = UserDefaults.standard.bool(
        forKey: "verticalTabs")
    var hiddenSidebarView = false
    private var trafficLightButtons: [NSButton]!

    // Other Views
    lazy var splitView = AXQuattroProgressSplitView()
    lazy var containerView = AXWebContainerView(isVertical: usesVerticalTabs)

    // Lazy loading to stop unnecesary initilizations
    lazy var tabBarView: AXTabBarViewTemplate = {
        if usesVerticalTabs {
            return AXVerticalTabBarView()
        } else {
            return AXHorizontalTabBarView()
        }
    }()

    private var layoutManager: AXWindowLayoutManaging!

    private lazy var visualEffectTintView: NSView = {
        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true

        return tintView
    }()

    lazy var visualEffectView: NSVisualEffectView = {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .popover
        visualEffectView.wantsLayer = true

        // Add tint view on top of the visual effect view
        visualEffectView.addSubview(visualEffectTintView)
        NSLayoutConstraint.activate([
            visualEffectTintView.leadingAnchor.constraint(
                equalTo: visualEffectView.leadingAnchor),
            visualEffectTintView.trailingAnchor.constraint(
                equalTo: visualEffectView.trailingAnchor),
            visualEffectTintView.topAnchor.constraint(
                equalTo: visualEffectView.topAnchor),
            visualEffectTintView.bottomAnchor.constraint(
                equalTo: visualEffectView.bottomAnchor),
        ])

        return visualEffectView
    }()

    init(with profiles: [AXProfile]) {
        self.profiles = profiles
        activeProfile = profiles[profileIndex]  // 0

        super.init(
            contentRect: AXWindow.updateWindowFrame(),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable,
                //.fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )

        configureWindow()
        setupComponents()
    }

    private func configureWindow() {
        self.animationBehavior = .documentWindow
        // self.titlebarAppearsTransparent = true
        self.backgroundColor = .textBackgroundColor
        self.isReleasedWhenClosed = true
        self.delegate = self

        if usesVerticalTabs {
            configureTrafficLights()
        }
    }

    // MARK: - Content View
    private func setupComponents() {
        // Visual Effect View
        self.contentView = visualEffectView
        containerView.translatesAutoresizingMaskIntoConstraints = false

        layoutManager =
            usesVerticalTabs
            ? AXVerticalLayoutManager(tabBarView: tabBarView)
            : AXHorizontalLayoutManager(tabBarView: tabBarView)

        layoutManager.tabHostingDelegate = self
        layoutManager.setupLayout(in: self)
        layoutManager.searchButton.delegate = self

        tabBarView.delegate = self
        containerView.delegate = self

        currentTabGroupIndex = 0
        tabBarView.updateTabGroup(currentTabGroup)
        visualEffectTintView.layer?.backgroundColor =
            currentTabGroup.color.cgColor
    }

    // MARK: Window Events
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
        trafficLightsPosition()
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

        // Logitech MX Master 3S mouse keymapping.
        switch buttonNumber {
        case 3:
            tabHostingViewNavigateBackwards()
        case 4:
            tabHostingViewNavigateForward()
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

    // MARK: - Traffic Lights
    func configureTrafficLights() {
        self.trafficLightButtons = [
            self.standardWindowButton(.closeButton)!,
            self.standardWindowButton(.miniaturizeButton)!,
            self.standardWindowButton(.zoomButton)!,
        ]

        trafficLightsPosition()
    }

    func trafficLightsPosition() {
        guard let trafficLightButtons else { return }
        // Update positioning
        for (index, button) in trafficLightButtons.enumerated() {
            button.frame.origin = NSPoint(
                x: 13.0 + CGFloat(index) * 20.0, y: -0.5)
        }
    }

    func trafficLightsHide() {
        trafficLightButtons?.forEach { button in
            button.isHidden = true
        }
    }

    func trafficLightsShow() {
        trafficLightButtons?.forEach { button in
            button.isHidden = false
        }
    }

    // MARK: - Content View Events
    func toggleTabSidebar() {
        guard let verticalTabHostingView = layoutManager.layoutView else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25  // Adjust duration as needed
            context.allowsImplicitAnimation = true

            let sideBarWillCollapsed = splitView.subviews.count == 2
            if sideBarWillCollapsed {
                hiddenSidebarView = true
                splitView.removeArrangedSubview(verticalTabHostingView)
                containerView.websiteTitleLabel.isHidden = true
            } else {
                hiddenSidebarView = false
                splitView.insertArrangedSubview(verticalTabHostingView, at: 0)
                containerView.websiteTitleLabel.isHidden = false
            }

            containerView.sidebarCollapsed(
                sideBarWillCollapsed,
                isFullScreen: self.styleMask.contains(.fullScreen))
            splitView.layoutSubtreeIfNeeded()
        }
    }

    // MARK: - Profile/Groups Tab Functions
    var profiles: [AXProfile]
    var activeProfile: AXProfile

    var profileIndex = 0 {
        didSet {
            activeProfile = profiles[profileIndex]
            self.switchToTabGroup(activeProfile.currentTabGroupIndex)
        }
    }

    var currentConfiguration: WKWebViewConfiguration {
        activeProfile.configuration
    }

    var tabGroups: [AXTabGroup] {
        activeProfile.tabGroups
    }

    var currentTabGroupIndex: Int {
        get {
            activeProfile.currentTabGroupIndex
        }
        set {
            activeProfile.currentTabGroupIndex = newValue
        }
    }

    var currentTabGroup: AXTabGroup {
        activeProfile.currentTabGroup
    }

    func switchToTabGroup(_ tabGroup: AXTabGroup) {
        self.tabBarView.updateTabGroup(tabGroup)

        visualEffectTintView.layer?.backgroundColor = tabGroup.color.cgColor
        layoutManager.tabGroupInfoView.updateLabels(tabGroup: tabGroup)

        mxPrint("Changed to Tab Group \(tabGroup.name), unknown index.")
    }

    func switchToTabGroup(_ at: Int) {
        let tabGroup = activeProfile.tabGroups[at]
        self.currentTabGroupIndex = at

        switchToTabGroup(tabGroup)

        mxPrint(
            "Changed to Tab Group \(tabGroup.name), known index: \(self.currentTabGroupIndex). Ignore top message."
        )
    }

    // MARK: - Workspace Variables
    lazy var workspaceSwapperView: AXWorkspaceSwapperView = {
        let view = AXWorkspaceSwapperView()
        view.delegate = self
        return view
    }()

    lazy var tabCustomizationView: AXTabGroupCustomizerView = {
        let view = AXTabGroupCustomizerView(tabGroup: currentTabGroup)
        view.delegate = self
        return view
    }()

    lazy var browserSpaceSharedPopover: NSPopover = {
        let popover = NSPopover()
        popover.contentViewController = .init()
        popover.behavior = .transient
        return popover
    }()

    // MARK: - Search Bar Delegate
    func searchBarDidAppear() {
        // Change contentView alpha value to 0.5
        contentView?.alphaValue = 0.5
    }

    func searchBarDidDisappear() {
        // Change contentView alpha value to 1.0
        contentView?.alphaValue = 1.0
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
        self.containerView.currentWebView?.load(URLRequest(url: url))

        makeFirstResponder(self.containerView.currentWebView)
    }

    func searchBarCurrentWebsiteURL() -> String {
        // Returns the current web view's url
        self.containerView.currentWebView?.url?.absoluteString ?? ""
    }

    // MARK: - WebContainer View Delegate
    func webContainerViewChangedURL(to url: URL) {
        layoutManager.searchButton.fullAddress = url
    }

    func webContainerViewCloses() {
        currentTabGroup.removeCurrentTab()
    }

    func webContainerViewRequestsSidebar() -> NSView? {
        return layoutManager.layoutView
    }

    func webContainerViewCreatesPopupWebView(config: WKWebViewConfiguration)
        -> WKWebView
    {
        let newWebView = AXWebView(frame: .zero, configuration: config)
        let tab = AXTab(
            title: newWebView.title ?? "Untitled Popup", webView: newWebView)

        currentTabGroup.addTab(tab)

        return newWebView
    }

    func webContainerViewProgressUpdated(with progress: Double) {
        splitView.beginAnimation(with: progress)
    }

    func webContainerViewFinishedLoading(webView: WKWebView) {
        splitView.finishAnimation()

        layoutManager.searchButton.fullAddress =
            containerView.currentWebView?.url

        if let historyManager = activeProfile.historyManager,
            let title = webView.title, let url = webView.url
        {
            let newItem = AXHistoryItem(
                title: title, address: url.absoluteString)

            historyManager.insert(item: newItem)
        }
    }

    // MARK: - Tab Bar View Delegate
    func tabBarSwitchedTo(tabAt: Int) {
        let tabGroup = currentTabGroup
        let tabs = tabGroup.tabs

        if tabAt == -1 {
            containerView.removeAllWebViews()
        } else {
            splitView.cancelAnimations()

            layoutManager.searchButton.addressField.stringValue = ""
            containerView.updateView(webView: tabs[tabAt].webView)
        }
    }

    func tabBarActiveTabTitleChanged(to: String) {
        containerView.websiteTitleLabel.stringValue = to
    }

    func tabBarDeactivatedTab() -> WKWebViewConfiguration? {
        return activeProfile.configuration
    }

    // MARK: - Tab Hosting View Delegate
    func tabHostingViewReloadCurrentPage() {
        containerView.currentWebView?.reload()
    }

    func tabHostingViewNavigateForward() {
        containerView.currentWebView?.goForward()
    }

    func tabHostingViewNavigateBackwards() {
        containerView.currentWebView?.goBack()
    }

    func tabHostingViewDisplaysTabGroupCustomizationPanel(_ sender: NSView) {
        browserSpaceSharedPopover.contentViewController?.view =
            tabCustomizationView

        browserSpaceSharedPopover.show(
            relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    func tabHostingViewDisplaysWorkspaceSwapperPanel(_ sender: NSView) {
        workspaceSwapperView.reloadTabGroups()
        browserSpaceSharedPopover.contentViewController?.view =
            workspaceSwapperView

        browserSpaceSharedPopover.show(
            relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
}

// MARK: - Workspace Swapper View Delegate
extension AXWindow: AXWorkspaceSwapperViewDelegate {
    func currentProfileName() -> String {
        activeProfile.name
    }

    func didSwitchProfile(to index: Int) {
        profileIndex = profileIndex == 1 ? 0 : 1

        layoutManager.tabGroupInfoView.updateLabels(
            tabGroup: currentTabGroup, profileName: activeProfile.name)
    }

    func popoverViewTabGroups() -> [AXTabGroup] {
        return self.activeProfile.tabGroups
    }

    func didSwitchTabGroup(to index: Int) {
        let tabGroup = self.activeProfile.tabGroups[index]
        self.currentTabGroupIndex = index

        visualEffectTintView.layer?.backgroundColor = tabGroup.color.cgColor

        self.switchToTabGroup(tabGroup)
    }

    func didAddTabGroup(_ newGroup: AXTabGroup) {
        // Switch to the new tab group
        self.activeProfile.tabGroups.append(newGroup)
    }
}

extension AXWindow: AXTabGroupCustomizerViewDelegate {
    func didUpdateTabGroup(_ tabGroup: AXTabGroup) {
        // No need to update profile name here, AXTabGroupCustomizerViewDelegate
        layoutManager.tabGroupInfoView.updateLabels(tabGroup: tabGroup)
    }

    func didUpdateColor(_ tabGroup: AXTabGroup) {
        visualEffectTintView.layer?.backgroundColor = tabGroup.color.cgColor
    }

    func didUpdateIcon(_ tabGroup: AXTabGroup) {
        layoutManager.tabGroupInfoView.updateIcon(tabGroup: tabGroup)
    }
}

extension AXWindow: AXSidebarSearchButtonDelegate {
    func lockClicked() {
        guard let webView = containerView.currentWebView,
            let serverTrust = webView.serverTrust
        else { return }

        SFCertificateTrustPanel.shared().beginSheet(
            for: self, modalDelegate: nil, didEnd: nil, contextInfo: nil,
            trust: serverTrust, message: "TLS Certificate Details")
    }

    func sidebarSearchButtonRequestsHistoryManager() -> AXHistoryManager {
        activeProfile.historyManager
    }
}

// MARK: - Menu Bar Actions
extension AXWindow {
    @IBAction func toggleSearchField(_ sender: Any?) {
        makeFirstResponder(
            layoutManager.searchButton.addressField)
    }

    @IBAction func toggleSearchBarForNewTab(_ sender: Any?) {
        currentTabGroup.addEmptyTab(configuration: activeProfile.configuration)
        makeFirstResponder(layoutManager.searchButton.addressField)
    }

    @IBAction func find(_ sender: Any) {
        containerView.webViewPerformSearch()
    }

    @IBAction func backWebpage(_ sender: Any?) {
        containerView.currentWebView?.goBack()
    }

    @IBAction func forwardWebpage(_ sender: Any?) {
        containerView.currentWebView?.goForward()
    }

    @IBAction func reloadWebpage(_ sender: Any?) {
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
        activeProfile.enableContentBlockers()
    }

    @IBAction func enableYouTubeAdBlocker(_ sender: Any) {
        if let sender = sender as? NSMenuItem {
            sender.title = "Disable YouTube Ad Blocker (Restart App)"
        }

        activeProfile.enableYouTubeAdBlocker()
    }

    @IBAction func closeTab(_ sender: Any) {
        guard currentTabGroup.tabs.count != 0 else {
            self.close()
            return
        }

        currentTabGroup.removeCurrentTab()
    }

    @IBAction func closeWindow(_ sender: Any) {
        self.close()
    }

    @IBAction func showHideSidebar(_ sender: Any) {
        toggleTabSidebar()
    }

    //    @IBAction func importCookiesFromChrome(_ sender: Any) {
    //        guard let webView = containerView.currentWebView else { return }
    //
    //        ChromeCookieImporter.importChromeCookes(into: webView) { result in
    //            mxPrint("Chrome Import Cookie Result, Successful cookies: \(result)")
    //        }
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
                mxPrint("WebView reader content: \(content)")

                if let currentURL = webView.url {
                    webView.loadHTMLString(css + content, baseURL: currentURL)
                }
            } else {
                mxPrint(
                    "Error extracting content: \(String(describing: error))")
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
