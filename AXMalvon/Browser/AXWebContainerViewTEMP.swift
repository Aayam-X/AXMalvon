//
//  AXWebContainerViewTEMP.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-30.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
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

    func webContainerUserDidClickStartPageItem(_ tab: AXTab)

    func webContainerViewDidSwitchToStartPage()
}

class AXWebContainerView: NSView {
    let startPageView = AXStartPageView(frame: .zero)
    weak var delegate: AXWebContainerViewDelegate?

    private unowned var tabView: NSTabView?

    private unowned var currentWebView: AXWebView?

    // Observers
    var progressBarObserver: NSKeyValueObservation?
    var urlObserver: NSKeyValueObservation?

    var currentPageAddress: URL? {
        currentWebView?.url
    }

    func setupViews() {
        // This is literally all there is to the initialization code.
        startPageView.delegate = self
    }

    override func removeFromSuperview() {
        progressBarObserver?.invalidate()
        progressBarObserver = nil

        super.removeFromSuperview()
    }
    
    func selectTabViewItem(at: Int) {
        tabView?.selectTabViewItem(at: at)
    }

    func switchTo(tabGroup: AXTabGroup) {
        self.subviews.removeAll()

        self.tabView = tabGroup.tabContentView

        if let tabView = tabView {
            tabView.delegate = self
            self.addSubview(tabView)
            tabView.translatesAutoresizingMaskIntoConstraints = false

            tabView.activateConstraints([
                .allEdges: .view(self)
            ])

            tabView.selectTabViewItem(at: tabGroup.selectedIndex)
        }
    }

    func displayNewTabPage() {
        mxPrint("Displaying Empty Tab Page")
        self.currentWebView = nil

        startPageView.frame = self.frame
        addSubview(startPageView)
        startPageView.autoresizingMask = [.height, .width]

        delegate?.webContainerViewDidSwitchToStartPage()
    }

    func reload() {
        currentWebView?.reload()
    }

    func back() {
        currentWebView?.goBack()
    }

    func forward() {
        currentWebView?.goForward()
    }

    func loadURL(url: URL) {
        if let currentWebView {
            currentWebView.load(URLRequest(url: url))
        } else {
            // Act as if a favourites site was clicked
            newTabViewDidSelectItem(url: url)
        }
    }

    func axWindowFirstResponder(_ window: AXWindow) {
        window.makeFirstResponder(currentWebView)
    }

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AXWebContainerView: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        guard let tab = tabViewItem as? AXTab else { return }
        if tab.isEmpty {
            displayNewTabPage()
            return
        } else {
            self.startPageView.removeFromSuperview()
        }
        
        guard let webView = tab.webView else { fatalError("Unable to create webView") }

        self.currentWebView = webView
        self.currentWebView!.uiDelegate = self
        self.currentWebView!.navigationDelegate = self

        webView.frame = tabView.frame

        self.window?.makeFirstResponder(self.currentWebView)

        progressBarObserver = webView.observe(
            \.estimatedProgress, options: [.new]
        ) { [weak self] _, change in
            if let newProgress = change.newValue {
                self?.updateProgress(newProgress)
            } else {
                mxPrint("Progress change has no new value.")
            }
        }

        if let url = webView.url {
            self.delegate?.webContainerViewChangedURL(to: url)
        }

        urlObserver = webView.observe(\.url, options: [.new]) {
            [weak self] _, change in
            if let newURL = change.newValue, let newURL {
                self?.delegate?.webContainerViewChangedURL(to: newURL)
            }
        }
    }
}

// MARK: - Web View Functions
extension AXWebContainerView: WKNavigationDelegate, WKUIDelegate,
    WKDownloadDelegate
{

    func updateProgress(_ value: Double) {
        //splitView.beginAnimation(with: value)
    }

    func removeAllWebViews() {
        currentWebView?.removeFromSuperview()
        self.currentWebView = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        mxPrint("Webview finished loading")
        //splitView.finishAnimation()

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

    //        func webView(
    //            _ webView: WKWebView,
    //            decidePolicyFor navigationAction: WKNavigationAction
    //        ) async -> WKNavigationActionPolicy {
    //            if navigationAction.navigationType == .linkActivated,
    //               navigationAction.modifierFlags.contains(.command)
    //            {
    //                let request = navigationAction.request
    //
    //                return delegate?.webViewOpenLinkInNewTab(request: request) != nil
    //                ? .cancel : .allow
    //            }
    //
    //            return .allow
    //        }

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

extension AXWebContainerView: AXNewTabViewDelegate {
    func newTabViewDidSelectItem(url: URL) {
        guard let tabView else { return }

        guard !tabView.tabViewItems.isEmpty,
            let currentTabViewItem = tabView.selectedTabViewItem as? AXTab
        else {
            fatalError(
                "\(#function) called when tab view is empty or no current tab view item"
            )
        }

        // Update the AXTab properties
        currentTabViewItem.url = url
        currentTabViewItem.isEmpty = false

        // Create the webView
        let webView = AXWebView(
            frame: .zero, configuration: currentTabViewItem.webConfiguration)
        currentTabViewItem.view = webView
        webView.load(URLRequest(url: url))

        // Start AXTabButton observation. Called via delegate method.
        delegate?.webContainerUserDidClickStartPageItem(currentTabViewItem)

        startPageView.removeFromSuperview()
    }
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
        -> Bool
    {
        return false
    }

    override func drawDivider(in rect: NSRect) {
        // Make divider invisble
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
