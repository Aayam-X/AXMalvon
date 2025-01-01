//
//  AXWebContainerView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

protocol AXWebContainerViewDelegate: AnyObject {
    func webContainerViewFinishedLoading(webView: WKWebView)
    func webContainerViewChangedURL(to url: URL)
    func webContainerViewCloses()

    func webContainerViewCreatesPopupWebView(config: WKWebViewConfiguration)
        -> WKWebView

    func webContainerViewRequestsSidebar() -> NSView?

    func webContainerSwitchedToEmptyWebView()
}

class AXWebContainerView: NSView {
    weak var delegate: AXWebContainerViewDelegate?
    weak var sidebar: NSView?
    let isVertical: Bool

    unowned var currentWebView: AXWebView?

    let splitViewContainer = NSView()
    private lazy var splitView = AXQuattroProgressSplitView()

    var sidebarTrackingArea: NSTrackingArea!
    var isAnimating: Bool = false
    var progressBarObserver: NSKeyValueObservation?
    var urlObserver: NSKeyValueObservation?

    // Constraints
    private lazy var splitViewLeftAnchorConstraint: NSLayoutConstraint? = nil
    private lazy var splitViewTopAnchorConstraint: NSLayoutConstraint? = nil
    private lazy var splitViewBottomAnchorConstraint: NSLayoutConstraint? = nil
    private lazy var splitViewRightAnchorConstraint: NSLayoutConstraint? = nil

    var websiteTitleLabel: NSTextField = {
        let title = NSTextField()
        title.isEditable = false
        title.alignment = .center
        title.isBordered = false
        title.usesSingleLineMode = true
        title.drawsBackground = false
        title.alphaValue = 0.5
        title.font = .systemFont(ofSize: 9)
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()

    func setupViews() {
        if isVertical {
            updateTrackingArea()

            addSubview(websiteTitleLabel)
            websiteTitleLabel.topAnchor.constraint(
                equalTo: topAnchor, constant: -1.2
            ).isActive = true
            websiteTitleLabel.leftAnchor.constraint(
                equalTo: leftAnchor, constant: 15
            )
            .isActive = true
            websiteTitleLabel.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -15
            )
            .isActive = true
            websiteTitleLabel.stringValue = "Empty Window"
            websiteTitleLabel.delegate = self

            splitViewContainer.wantsLayer = true
            splitViewContainer.layer?.masksToBounds = false

            // Add splitView to the container view
            let shadow = NSShadow()
            shadow.shadowColor = .textColor.withAlphaComponent(0.6)
            shadow.shadowBlurRadius = 2.0
            shadow.shadowOffset = .zero
            splitViewContainer.shadow = shadow

            splitView.wantsLayer = true
            splitView.layer?.cornerRadius = 5.0
        }

        splitViewContainer.translatesAutoresizingMaskIntoConstraints = false
        splitView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(splitViewContainer)
        createSplitViewContainerConstraints()

        splitViewContainer.addSubview(splitView)
        NSLayoutConstraint.activate([
            splitView.topAnchor.constraint(
                equalTo: splitViewContainer.topAnchor),
            splitView.leftAnchor.constraint(
                equalTo: splitViewContainer.leftAnchor),
            splitView.rightAnchor.constraint(
                equalTo: splitViewContainer.rightAnchor),
            splitView.bottomAnchor.constraint(
                equalTo: splitViewContainer.bottomAnchor)
        ])
    }

    override func removeFromSuperview() {
        progressBarObserver?.invalidate()
        progressBarObserver = nil

        super.removeFromSuperview()
    }

    func createSplitViewContainerConstraints() {
        if isVertical {
            splitViewTopAnchorConstraint = splitViewContainer.topAnchor
                .constraint(
                    equalTo: topAnchor, constant: 9.0)
            splitViewLeftAnchorConstraint = splitViewContainer.leftAnchor
                .constraint(equalTo: leftAnchor, constant: 2.0)
            splitViewRightAnchorConstraint = splitViewContainer.rightAnchor
                .constraint(equalTo: rightAnchor, constant: -9.0)
            splitViewBottomAnchorConstraint = splitViewContainer.bottomAnchor
                .constraint(equalTo: bottomAnchor, constant: -9.0)

            splitViewTopAnchorConstraint!.isActive = true
            splitViewLeftAnchorConstraint!.isActive = true
            splitViewRightAnchorConstraint!.isActive = true
            splitViewBottomAnchorConstraint!.isActive = true
        } else {
            NSLayoutConstraint.activate([
                splitViewContainer.topAnchor.constraint(equalTo: topAnchor),
                splitViewContainer.leftAnchor.constraint(equalTo: leftAnchor),
                splitViewContainer.rightAnchor.constraint(equalTo: rightAnchor),
                splitViewContainer.bottomAnchor.constraint(
                    equalTo: bottomAnchor)
            ])
        }
    }

    func sidebarCollapsed(_ collapsed: Bool, isFullScreen: Bool) {
        // If it is fullScreen
        if isFullScreen && collapsed {
            splitViewTopAnchorConstraint?.constant = 0
            splitViewLeftAnchorConstraint?.constant = 0
            splitViewRightAnchorConstraint?.constant = 0
            splitViewBottomAnchorConstraint?.constant = 0
            splitView.layer?.cornerRadius = 0.0
        } else {
            splitViewLeftAnchorConstraint?.constant = collapsed ? 9 : 2
            splitViewTopAnchorConstraint?.constant = 9
            splitViewRightAnchorConstraint?.constant = -9
            splitViewBottomAnchorConstraint?.constant = -9
            splitView.layer?.cornerRadius = 5.0
        }
    }

    func updateView(webView: AXWebView) {
        splitView.cancelAnimations()
        splitView.arrangedSubviews.forEach(splitView.removeArrangedSubview)

        self.currentWebView = webView
        self.websiteTitleLabel.stringValue = webView.title ?? "Untitled Page"
        self.currentWebView!.uiDelegate = self
        self.currentWebView!.navigationDelegate = self

        webView.frame = splitView.frame
        splitView.addArrangedSubview(webView)
        webView.autoresizingMask = [.height, .width]

        if webView.url != nil {
            self.window?.makeFirstResponder(currentWebView)
        } else {
            delegate?.webContainerSwitchedToEmptyWebView()
        }

        progressBarObserver = webView.observe(
            \.estimatedProgress, options: [.new]
        ) { [weak self] _, change in
            if let newProgress = change.newValue {
                self?.updateProgress(newProgress)
            } else {
                mxPrint("Progress change has no new value.")
            }
        }

        guard !isVertical else { return }
        if let url = webView.url {
            self.delegate?.webContainerViewChangedURL(to: url)
        }

        urlObserver = webView.observe(\.url, options: [.new]) { [weak self] _, change in
            if let newURL = change.newValue, let newURL {
                self?.delegate?.webContainerViewChangedURL(to: newURL)
            }
        }
    }

    // MARK: - Collapsed Sidebar Methods
    func ensureSidebarExists() {
        if sidebar == nil {
            sidebar = delegate?.webContainerViewRequestsSidebar()
        }
    }

    override func mouseEntered(with event: NSEvent) {
        guard let window = self.window as? AXWindow, window.hiddenSidebarView
        else { return }
        sidebarHover()
    }

    func sidebarHover() {
        ensureSidebarExists()
        guard let sidebar = sidebar, let window = window as? AXWindow else {
            return
        }
        addSubview(sidebar)

        if !isAnimating {
            sidebar.layer?.backgroundColor =
                window.currentTabGroup.color.withAlphaComponent(1.0).cgColor
            NSAnimationContext.runAnimationGroup(
                { context in
                    context.duration = 0.1
                    sidebar.animator().frame.origin.x = 0
                },
                completionHandler: {
                    self.isAnimating = false
                })
        }
    }

    override func mouseExited(with event: NSEvent) {
        mxPrint("Mouse exited sidebar")
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        updateTrackingArea()
    }

    func updateTrackingArea() {
        if sidebarTrackingArea != nil {
            removeTrackingArea(sidebarTrackingArea)
        }
        let trackingRect = NSRect(
            x: bounds.origin.x - 100, y: bounds.origin.y, width: 101,
            height: bounds.height)
        sidebarTrackingArea = NSTrackingArea(
            rect: trackingRect,
            options: [.activeAlways, .mouseEnteredAndExited], owner: self)
        addTrackingArea(sidebarTrackingArea)
    }

    init(isVertical: Bool) {
        self.isVertical = isVertical

        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Page Find Functions
extension AXWebContainerView: NSTextFieldDelegate {
    func webViewPerformSearch() {
        self.websiteTitleLabel.stringValue = "Find in Page..."
        self.websiteTitleLabel.placeholderString = "Find in Page..."
        self.websiteTitleLabel.isEditable = true
        websiteTitleLabel.alphaValue = 0.8

        window?.makeFirstResponder(websiteTitleLabel)
    }

    func webPageFindTextFieldDidLoseFocus() {
        self.websiteTitleLabel.isEditable = false
        websiteTitleLabel.alphaValue = 0.3
        self.websiteTitleLabel.stringValue =
            currentWebView?.title ?? "Empty Window"
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let currentWebView else { return }

        Task {
            _ = try? await currentWebView.find(websiteTitleLabel.stringValue)
        }
    }

    func control(
        _ control: NSControl, textShouldBeginEditing fieldEditor: NSText
    ) -> Bool {
        // To detect when the text field loses focus
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
            if websiteTitleLabel.currentEditor() == nil {
                timer.invalidate()
                webPageFindTextFieldDidLoseFocus()
            }
        }

        return true
    }
}

// MARK: - Web View Functions
extension AXWebContainerView: WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {

    func updateProgress(_ value: Double) {
        splitView.beginAnimation(with: value)
    }

    func removeAllWebViews() {
        currentWebView?.removeFromSuperview()
        self.currentWebView = nil
        self.websiteTitleLabel.stringValue = "Empty Window"
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        mxPrint("Webview finished loading")
        splitView.finishAnimation()

        delegate?.webContainerViewFinishedLoading(webView: webView)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        delegate?.webContainerViewCreatesPopupWebView(config: configuration)
    }

    func webViewDidClose(_ webView: WKWebView) {
        delegate?.webContainerViewCloses()
    }

    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo
    ) async -> [URL]? {
        let panel = NSOpenPanel()
        panel.title = "Select File"
        panel.prompt = "Open"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        // Use `await` to present the panel
        let result = await panel.begin()
        return result == .OK ? panel.urls : nil
    }

    func webView(
        _ webView: WKWebView, navigationAction: WKNavigationAction,
        didBecome download: WKDownload
    ) {
        mxPrint("DONWLOAD DOWNLAOD")
    }

    //    func webView(
    //        _ webView: WKWebView,
    //        decidePolicyFor navigationAction: WKNavigationAction
    //    ) async -> WKNavigationActionPolicy {
    //        if navigationAction.navigationType == .linkActivated,
    //            navigationAction.modifierFlags.contains(.command)
    //        {
    //            let request = navigationAction.request
    //
    //            return delegate?.webViewOpenLinkInNewTab(request: request) != nil
    //                ? .cancel : .allow
    //        }
    //
    //        return .allow
    //    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        if navigationResponse.canShowMIMEType {
            return .allow
        } else {
            return .download
        }
    }

    func webView(
        _ webView: WKWebView, navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    ) {
        download.delegate = self
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Select Download Destination"
        panel.prompt = "Save"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        // Use `await` to present the panel
        let result = await panel.begin()
        if result == .OK, let directoryURL = panel.url {
            return directoryURL.appendingPathComponent(suggestedFilename)
        }
        return nil
    }

    func downloadDidFinish(_ download: WKDownload) {
        mxPrint("Download finished!")
    }

    //    func webView(
    //        _ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
    //        completionHandler: @escaping (
    //            URLSession.AuthChallengeDisposition, URLCredential?
    //        ) -> Void
    //    ) {
    //        guard let serverTrust = challenge.protectionSpace.serverTrust else {
    //            return completionHandler(.useCredential, nil)
    //        }
    //        let exceptions = SecTrustCopyExceptions(serverTrust)
    //        SecTrustSetExceptions(serverTrust, exceptions)
    //        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    //    }
}

// MARK: - Web Split View
private class AXWebContainerSplitView: NSSplitView, NSSplitViewDelegate {
    init() {
        super.init(frame: .zero)
        delegate = self
        isVertical = true
        dividerStyle = .thin
    }

    func splitView(
        _ splitView: NSSplitView,
        constrainMinCoordinate proposedMinimumPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        return 50
    }

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView)
        -> Bool {
        return false
    }

    override func drawDivider(in rect: NSRect) {
        // Make divider invisble
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
