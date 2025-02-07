//
//  AXWebContainerView.swift
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
    func webContainerViewCreatesTabWithZeroTabs(with url: URL) -> AXTab

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

    func displayNewTabPage() {
        mxPrint("Displaying Empty Tab Page")
        self.currentWebView = nil

        startPageView.frame = self.frame
        addSubview(startPageView)
        startPageView.autoresizingMask = [.height, .width]

        // Makes the search field first responder.
        delegate?.webContainerViewDidSwitchToStartPage()
    }

    func reload() {
        currentWebView?.reload()
    }

    func back() {
        currentWebView?.goBack()
        self.finishAnimation()
    }

    func forward() {
        currentWebView?.goForward()
        self.finishAnimation()
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
        //window.makeFirstResponder(currentWebView)
        if let webView = currentWebView {
            DispatchQueue.main.async {
                window.makeFirstResponder(webView)
            }
        }
    }

    func currentWebViewFocus(webView: AXWebView) {
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.window else { return }
            window.makeFirstResponder(webView)
        }
    }

    private let animationQueue = DispatchQueue(
        label: "com.ayaamx.AXMalvon.progressAnimation",
        qos: .userInitiated
    )

    override var isFlipped: Bool {
        true
    }

    private let borderLayers: [CAShapeLayer] = {
        let layer = CAShapeLayer()
        layer.lineWidth = 9.0
        layer.strokeColor =
            NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor
        layer.isHidden = true
        layer.opacity = 0.0

        let layer1 = CAShapeLayer()
        layer1.lineWidth = 9.0
        layer1.strokeColor =
            NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor
        layer1.isHidden = true
        layer1.opacity = 0.0

        let layer2 = CAShapeLayer()
        layer2.lineWidth = 9.0
        layer2.strokeColor =
            NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor
        layer2.isHidden = true
        layer2.opacity = 0.0

        let layer3 = CAShapeLayer()
        layer3.lineWidth = 9.0
        layer3.strokeColor =
            NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor
        layer3.isHidden = true
        layer3.opacity = 0.0

        return [layer, layer1, layer2, layer3]
    }()

    private var currentProgress: CGFloat = 0.0
    private var animationToken: UUID?

    init() {
        super.init(frame: .zero)
        setupViews()

        wantsLayer = true
        self.layer?.masksToBounds = true
        setupLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Progress Bar Animation
    private func setupLayers() {
        borderLayers.forEach { layer?.addSublayer($0) }
    }

    private func createBorderPath(for edge: NSRectEdge) -> NSBezierPath {
        let path = NSBezierPath()
        switch edge {
        case .maxY:
            path.move(to: CGPoint(x: 0, y: bounds.height))
            path.line(to: CGPoint(x: bounds.width, y: bounds.height))
        case .maxX:
            path.move(to: CGPoint(x: bounds.width, y: bounds.height))
            path.line(to: CGPoint(x: bounds.width, y: 0))
        case .minY:
            path.move(to: CGPoint(x: bounds.width, y: 0))
            path.line(to: CGPoint(x: 0, y: 0))
        case .minX:
            path.move(to: CGPoint(x: 0, y: 0))
            path.line(to: CGPoint(x: 0, y: bounds.height))
        @unknown default:
            break
        }
        return path
    }

    func beginAnimation(with value: Double) {
        let targetProgress: CGFloat
        let duration: CFTimeInterval

        switch value {
        case 93...:
            targetProgress = 1.0
            duration = 0.69
        case 0.75...:
            targetProgress = 0.80
            duration = 9.0
        case 0.50...:
            targetProgress = 0.75
            duration = 1.2
        case 0.25...:
            targetProgress = 0.50
            duration = 0.9
        default:
            targetProgress = 0.25
            duration = 0.6
        }

        animateProgressAsync(to: targetProgress, duration: duration)
    }

    private func animateProgressAsync(
        to targetProgress: CGFloat, duration: CFTimeInterval
    ) {
        let currentToken = UUID()
        animationToken = currentToken

        animationQueue.async { [weak self] in
            guard let self = self else { return }

            let startProgress = self.currentProgress

            DispatchQueue.main.async {
                guard self.animationToken == currentToken else { return }

                // Prepare and start animation
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                animation.fromValue = startProgress
                animation.toValue = targetProgress
                animation.duration = duration
                animation.timingFunction = CAMediaTimingFunction(
                    name: .easeInEaseOut)

                // Apply animation to each border layer
                for (index, layer) in self.borderLayers.enumerated() {
                    let path = self.createBorderPath(
                        for: NSRectEdge(rawValue: UInt(index))!)
                    layer.path = path.cgPath
                    layer.zPosition = 1
                    layer.opacity = 1.0
                    layer.isHidden = false
                    layer.add(animation, forKey: "progressAnimation")
                }

                if targetProgress >= 0.95 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        [weak self] in
                        self?.borderLayers.forEach { layer in
                            layer.opacity = 0.0
                            layer.isHidden = true
                        }
                    }
                }

                self.currentProgress = targetProgress
            }
        }
    }

    func finishAnimation() {
        animateProgressAsync(to: 1.0, duration: 0.69)
    }

    func cancelAnimations() {
        animationToken = nil

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.borderLayers.forEach { layer in
                layer.removeAllAnimations()
                layer.opacity = 0.0
                layer.isHidden = true
            }
        }
    }

    // MARK: - View Switching
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
            
            if tabGroup.tabs.isEmpty || tabGroup.selectedIndex >= tabGroup.tabs.count {
                displayNewTabPage()
            } else {
                let tab = tabGroup.tabs[tabGroup.selectedIndex]
                self.willSwitchTab(tab)
            }
        }
    }

    func willSwitchTab(_ tab: AXTab) {
        self.cancelAnimations()
        guard let tabView else { return }

        if tab.isEmpty {
            displayNewTabPage()
            return
        } else {
            self.startPageView.removeFromSuperview()
        }

        guard let webView = tab.webView else {
            fatalError("Unable to create webView")
        }

        self.currentWebView = webView
        self.currentWebView!.uiDelegate = self
        self.currentWebView!.navigationDelegate = self

        webView.frame = tabView.frame
        currentWebViewFocus(webView: webView)

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

extension AXWebContainerView: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        if let tab = tabViewItem as? AXTab {
            self.willSwitchTab(tab)
        }
    }
}

// MARK: - Web View Functions
extension AXWebContainerView: WKNavigationDelegate, WKUIDelegate,
    WKDownloadDelegate
{

    func updateProgress(_ value: Double) {
        self.beginAnimation(with: value)
    }

    func removeAllWebViews() {
        currentWebView?.removeFromSuperview()
        self.currentWebView = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        mxPrint("Webview finished loading")
        self.cancelAnimations()

        delegate?.webContainerViewFinishedLoading(webView: webView)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        return delegate?.webContainerViewCreatesPopupWebView(
            config: configuration)
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

        let currentTabViewItem: AXTab?

        if tabView.tabViewItems.isEmpty {
            currentTabViewItem = delegate?
                .webContainerViewCreatesTabWithZeroTabs(with: url)
        } else {
            currentTabViewItem = tabView.selectedTabViewItem as? AXTab
        }

        guard let currentTabViewItem = currentTabViewItem else {
            fatalError("\(#function) Failed to create new tab.")
        }

        // Update the AXTab properties
        currentTabViewItem.url = url
        currentTabViewItem.isEmpty = false

        // Update the tab
        self.willSwitchTab(currentTabViewItem)
        tabView.selectTabViewItem(at: 0)

        // Start AXTabButton observation. Called via delegate method.
        delegate?.webContainerUserDidClickStartPageItem(currentTabViewItem)
    }
}
