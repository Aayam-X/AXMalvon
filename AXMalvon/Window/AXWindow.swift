//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import SQLite3
import SecurityInterface
import WebKit

class AXWindow: NSWindow, NSWindowDelegate {
    // Window Defaults
    var hiddenSidebarView = false
    lazy var verticalTabs = UserDefaults.standard.bool(forKey: "verticalTabs")

    lazy var trafficLightManager = AXTrafficLightOverlayManager(window: self)
    lazy var splitView = AXQuattroProgressSplitView()
    lazy var containerView = AXWebContainerView(isVertical: verticalTabs)

    // Vertical + Horizontal Tabs
    // Lazy loading to save ram
    lazy var sidebarView = AXSidebarView()

    lazy var tabBarView: AXTabBarViewTemplate = {
        if verticalTabs {
            return AXVerticalTabBarView()
        } else {
            return AXHorizontalTabBarView()
        }
    }()

    var toolbarSearchField: NSSearchToolbarItem?

    //    lazy var tabGroupInfoView: AXTabGroupInfoView = {
    //        let view = AXTabGroupInfoView()
    //
    //        view.translatesAutoresizingMaskIntoConstraints = false
    //        view.onRightMouseDown = displayTabGroupInformationPopover
    //        return view
    //    }()

    lazy var tabGroupInfoView: AXTabGroupInfoView = {
        let value = AXTabGroupInfoView()

        value.translatesAutoresizingMaskIntoConstraints = false
        value.onLeftMouseDown = displayTabGroupInformationPopover
        return value
    }()

    var profiles: [AXProfile]
    var activeProfile: AXProfile

    // MARK: - Toolbar Components
    var splitViewController: NSSplitViewController?
    var searchField: NSSearchField?
    var progressIndicator: NSProgressIndicator?
    var refreshButton: NSButton?

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

    private lazy var visualEffectView: NSVisualEffectView = {
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

    private lazy var visualEffectTintView: NSView = {
        let tintView = NSView()
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true

        return tintView
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
            ],
            backing: .buffered,
            defer: false
        )

        if verticalTabs {
            self.styleMask.insert(.fullSizeContentView)
        }

        configureWindow()
        setupComponents()
    }

    private func configureWindow() {
        self.animationBehavior = .documentWindow
        self.titlebarAppearsTransparent = verticalTabs
        self.backgroundColor = .textBackgroundColor
        self.isReleasedWhenClosed = true
        self.delegate = self
    }

    private func setupComponents() {
        self.contentView = visualEffectView

        verticalTabs
            ? setupVerticalTabLayout(in: visualEffectView)
            : setupHorizontalTabLayout(in: visualEffectView)

        tabBarView.delegate = self
        containerView.delegate = self

        currentTabGroupIndex = 0
        tabBarView.updateTabGroup(currentTabGroup)

        // FIXME: Move this elsewhere
        if !verticalTabs {
            tabGroupInfoView.updateLabels(
                tabGroup: currentTabGroup,
                profileName: self.currentProfileName())
        }
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
        trafficLightManager.updateTrafficLights()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        let frameAsString = NSStringFromRect(self.frame)
        UserDefaults.standard.set(frameAsString, forKey: "windowFrame")
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        sidebarView.gestureView.updateConstraintsWhenMouse(
            window: self, entered: false)
        trafficLightManager.hideTrafficLights()
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

    func toggleTabSidebar() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25  // Adjust duration as needed
            context.allowsImplicitAnimation = true

            let sideBarWillCollapsed = splitView.subviews.count == 2
            if sideBarWillCollapsed {
                hiddenSidebarView = true
                splitView.removeArrangedSubview(sidebarView)
                containerView.websiteTitleLabel.isHidden = true
            } else {
                hiddenSidebarView = false
                splitView.insertArrangedSubview(sidebarView, at: 0)
                containerView.websiteTitleLabel.isHidden = false
            }

            containerView.sidebarCollapsed(
                sideBarWillCollapsed,
                isFullScreen: self.styleMask.contains(.fullScreen))
            splitView.layoutSubtreeIfNeeded()
        }
    }

    func switchToTabGroup(_ tabGroup: AXTabGroup) {
        self.tabBarView.updateTabGroup(tabGroup)

        visualEffectTintView.layer?.backgroundColor = tabGroup.color.cgColor

        mxPrint("Changed to Tab Group \(tabGroup.name), unknown index.")

        if !verticalTabs {
            tabGroupInfoView.updateLabels(
                tabGroup: tabGroup, profileName: self.currentProfileName())
        }
    }

    func switchToTabGroup(_ at: Int) {
        let tabGroup = activeProfile.tabGroups[at]
        self.currentTabGroupIndex = at

        switchToTabGroup(tabGroup)

        mxPrint(
            "Changed to Tab Group \(tabGroup.name), known index: \(self.currentTabGroupIndex). Ignore top message."
        )
    }

    // MARK: - Tab Layout Functions
    private func setupHorizontalTabLayout(
        in visualEffectView: NSVisualEffectView
    ) {
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        visualEffectView.addSubview(tabBarView)
        visualEffectView.addSubview(containerView)

        NSLayoutConstraint.activate([
            tabBarView.leadingAnchor.constraint(
                equalTo: visualEffectView.leadingAnchor),
            tabBarView.trailingAnchor.constraint(
                equalTo: visualEffectView.trailingAnchor),
            tabBarView.topAnchor.constraint(
                equalTo: visualEffectView.topAnchor),
            tabBarView.heightAnchor.constraint(
                equalToConstant: 40),

            containerView.leadingAnchor.constraint(
                equalTo: visualEffectView.leadingAnchor),
            containerView.trailingAnchor.constraint(
                equalTo: visualEffectView.trailingAnchor),
            containerView.topAnchor.constraint(
                equalTo: tabBarView.bottomAnchor),
            containerView.bottomAnchor.constraint(
                equalTo: visualEffectView.bottomAnchor),
        ])

        setupHorizontalToolbar()
    }

    private func setupVerticalTabLayout(in visualEffectView: NSVisualEffectView)
    {
        splitView.frame = visualEffectView.bounds
        splitView.autoresizingMask = [.height, .width]
        visualEffectView.addSubview(splitView)

        splitView.addArrangedSubview(sidebarView)
        splitView.addArrangedSubview(containerView)

        sidebarView.frame.size.width = 180

        // Delegate setup
        sidebarView.translatesAutoresizingMaskIntoConstraints = false
        sidebarView.gestureView.delegate = self
        sidebarView.workspaceSwapperView.delegate = self
        sidebarView.gestureView.searchButton.delegate = self

        sidebarView.insertTabBarView(tabBarView: tabBarView)

        trafficLightManager.updateTrafficLights()
    }

    private func setupHorizontalToolbar() {
        let toolbar = NSToolbar(identifier: "SafariToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = true

        self.toolbar = toolbar
    }
}

// MARK: - Search Bar Delegate
extension AXWindow: AXSearchBarWindowDelegate {
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
    }

    func searchBarCurrentWebsiteURL() -> String {
        // Returns the current web view's url
        self.containerView.currentWebView?.url?.absoluteString ?? ""
    }
}

extension AXWindow: NSSearchFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let value = toolbarSearchField?.searchField.stringValue else {
            return
        }

        if value.isValidURL() && !value.hasWhitespace() {
            self.containerView.currentWebView?.load(
                URLRequest(url: URL(string: value)!.fixURL()))
        } else {
            let newURL = URL(
                string: "https://www.google.com/search?client=Malvon&q=\(value)"
            )

            self.containerView.currentWebView?.load(URLRequest(url: newURL!))
        }
    }
}

// MARK: - WebContainer View Delegate
extension AXWindow: AXWebContainerViewDelegate {
    func webViewRequestsToClose() {
        currentTabGroup.removeCurrentTab()
    }

    func webViewOpenLinkInNewTab(request: URLRequest) {
        let newWebView = AXWebView(
            frame: .zero, configuration: currentConfiguration)
        newWebView.load(request)

        let tab = AXTab(
            title: newWebView.title ?? "Untitled Popup", webView: newWebView)

        currentTabGroup.addTab(tab)
    }

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

        if verticalTabs {
            sidebarView.gestureView.searchButton.url =
                containerView.currentWebView?.url
        }
    }
}

extension AXWindow: AXTabBarViewDelegate {
    func tabBarSwitchedTo(tabAt: Int) {
        let tabGroup = currentTabGroup
        let tabs = tabGroup.tabs

        if tabAt == -1 {
            containerView.removeAllWebViews()
        } else {
            splitView.cancelAnimations()
            containerView.updateView(webView: tabs[tabAt].webView)
        }
    }

    func activeTabTitleChanged(to: String) {
        containerView.websiteTitleLabel.stringValue = to
    }

    func deactivatedTab() -> WKWebViewConfiguration? {
        return activeProfile.configuration
    }
}

// MARK: Sidebar Search Button Delegate
extension AXWindow: AXSidebarSearchButtonDelegate {
    func lockClicked() {
        guard let webView = containerView.currentWebView,
            let serverTrust = webView.serverTrust
        else { return }

        SFCertificateTrustPanel.shared().beginSheet(
            for: self, modalDelegate: nil, didEnd: nil, contextInfo: nil,
            trust: serverTrust, message: "TLS Certificate Details")
    }
}

// MARK: - Gesture View Delegate
extension AXWindow: AXGestureViewDelegate {
    func gestureView(didUpdate tabGroup: AXTabGroup) {
        visualEffectTintView.layer?.backgroundColor = tabGroup.color.cgColor
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

// MARK: - Workspace Swapper View Delegate
extension AXWindow: AXWorkspaceSwapperViewDelegate {
    func currentProfileName() -> String {
        activeProfile.name
    }

    func didSwitchProfile(to index: Int) {
        profileIndex = profileIndex == 1 ? 0 : 1
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

// MARK: - Toolbar Delegate
extension AXWindow: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem
        .Identifier]
    {
        return [
            .flexibleSpace,
            .back,
            .forward,
            .refresh,
            .flexibleSpace,
            .search,
            .addTab,
            .workspaceSwapper,
            .flexibleSpace,
            .tabGroupInformationView,
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem
        .Identifier]
    {
        return [
            .flexibleSpace,
            .flexibleSpace,
            .back,
            .forward,
            .refresh,
            .flexibleSpace,
            .search,
            .addTab,
            .workspaceSwapper,
            .flexibleSpace,
            .tabGroupInformationView,
        ]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case .refresh:
            let item = NSToolbarItem(itemIdentifier: .refresh)
            item.label = "Refresh"
            item.image = NSImage(
                systemSymbolName: "arrow.clockwise",
                accessibilityDescription: "Refresh")
            item.target = self
            item.isNavigational = true
            item.action = #selector(reloadWebpage)
            return item

        case .back:
            let item = NSToolbarItem(itemIdentifier: .back)
            item.label = "Back"
            item.image = NSImage(
                systemSymbolName: "chevron.backward",
                accessibilityDescription: "Back")
            item.target = self
            item.isNavigational = true
            item.action = #selector(backWebpage)
            return item

        case .forward:
            let item = NSToolbarItem(itemIdentifier: .forward)
            item.label = "Forward"
            item.image = NSImage(
                systemSymbolName: "chevron.forward",
                accessibilityDescription: "Forward")
            item.target = self
            item.isNavigational = true
            item.action = #selector(forwardWebpage)
            return item

        case .search:
            toolbarSearchField = NSSearchToolbarItem(itemIdentifier: .search)
            toolbarSearchField!.label = "Search"
            toolbarSearchField!.preferredWidthForSearchField = 300
            toolbarSearchField!.visibilityPriority = .high
            toolbarSearchField!.searchField.placeholderString =
                "Search or enter address"
            toolbarSearchField!.searchField.delegate = self

            // Add progress bar to search field
            let progressBar = createProgressBar()
            toolbarSearchField!.searchField.addSubview(progressBar)

            // Constrain progress bar to fill search field
            NSLayoutConstraint.activate([
                progressBar.leadingAnchor.constraint(
                    equalTo: toolbarSearchField!.searchField.leadingAnchor),
                progressBar.trailingAnchor.constraint(
                    equalTo: toolbarSearchField!.searchField.trailingAnchor),
                progressBar.bottomAnchor.constraint(
                    equalTo: toolbarSearchField!.searchField.bottomAnchor),
                progressBar.heightAnchor.constraint(equalToConstant: 1),
            ])

            return toolbarSearchField!

        case .addTab:
            let item = NSToolbarItem(itemIdentifier: .addTab)
            item.label = "Add Tab"
            item.image = NSImage(
                systemSymbolName: "plus", accessibilityDescription: "Add Tab")
            item.target = self
            item.action = #selector(AppDelegate.toggleSearchBarForNewTab(_:))
            return item

        case .workspaceSwapper:
            let item = NSToolbarItem(itemIdentifier: .workspaceSwapper)
            item.label = "Workspace Swapper"
            item.image = NSImage(
                systemSymbolName: "rectangle.stack",
                accessibilityDescription: "Switch Workspace")
            item.target = self
            item.action = #selector(showWorkspaceSwapper)
            return item

        case .tabGroupInformationView:
            let item = NSToolbarItem(itemIdentifier: .tabGroupInformationView)
            item.label = ""
            item.image = nil
            item.target = self
            item.action = #selector(displayTabGroupInformationPopover)

            item.view = .init(frame: .init(x: 0, y: 0, width: 70, height: 30))
            item.view!.addSubview(tabGroupInfoView)

            return item

        default:
            return nil
        }
    }

    func createProgressBar() -> NSProgressIndicator {
        let progressBar = NSProgressIndicator()
        progressBar.style = .bar
        progressBar.isIndeterminate = false
        progressBar.doubleValue = 50  // Example value
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        //progressBar.controlTint = .clear // Make it blend with the background
        return progressBar
    }

    @objc func showWorkspaceSwapper(_ sender: Any?) {
        guard let sender = sender as? NSToolbarItem else { return }

        guard let itemViewer = sender.value(forKey: "_itemViewer") as? NSView
        else {
            return
        }

        let workspaceSwapperView = AXWorkspaceSwapperView()
        workspaceSwapperView.delegate = self
        workspaceSwapperView.reloadTabGroups()

        let popover = NSPopover()
        popover.behavior = .transient
        let viewController = NSViewController()
        viewController.view = workspaceSwapperView
        popover.contentViewController = viewController

        popover.show(
            relativeTo: itemViewer.bounds,
            of: itemViewer, preferredEdge: .minY)
    }

    @objc func displayTabGroupInformationPopover() {
        let popover = NSPopover()
        popover.behavior = .transient
        let vc = NSViewController()
        let view = AXTabGroupCustomizerView(tabGroup: currentTabGroup)
        view.delegate = self
        vc.view = view
        popover.contentViewController = vc

        popover.show(
            relativeTo: tabGroupInfoView.bounds, of: tabGroupInfoView,
            preferredEdge: .minY)
    }
}

extension AXWindow: AXTabGroupCustomizerViewDelegate {
    func didUpdateTabGroup(_ tabGroup: AXTabGroup) {
        gestureView(didUpdate: tabGroup)
        tabGroupInfoView.updateLabels(
            tabGroup: tabGroup, profileName: self.currentProfileName())
    }

    func didUpdateColor(_ tabGroup: AXTabGroup) {
        gestureView(didUpdate: tabGroup)
    }

    func didUpdateIcon(_ tabGroup: AXTabGroup) {
        gestureView(didUpdate: tabGroup)
        tabGroupInfoView.updateIcon(tabGroup: tabGroup)
    }
}

// MARK: - Toolbar Item Identifiers
extension NSToolbarItem.Identifier {
    static let refresh = NSToolbarItem.Identifier("Refresh")
    static let back = NSToolbarItem.Identifier("Back")
    static let forward = NSToolbarItem.Identifier("Forward")
    static let search = NSToolbarItem.Identifier("Search")
    static let addTab = NSToolbarItem.Identifier("AddTab")
    static let flexibleSpace = NSToolbarItem.Identifier("flexibleSpace")
    static let workspaceSwapper = NSToolbarItem.Identifier("WorkspaceSwapper")  // New identifier

    static let tabGroupInformationView = NSToolbarItem.Identifier(
        "TabGroupInformationView")
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
