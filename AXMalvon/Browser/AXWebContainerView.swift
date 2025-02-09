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
    func webContainerViewSelectedTabWithEmptyView() -> AXWebView?
    
    func webContainerViewFinishedLoading(webView: WKWebView)
    func webContainerViewChangedURL(to url: URL)
    func webContainerViewCloses()

    func webContainerViewCreatesPopupWebView(config: WKWebViewConfiguration)
        -> WKWebView
    func webContainerViewCreatesTabWithZeroTabs(with url: URL) -> AXTab

    func webContainerViewRequestsSidebar() -> NSView?

    func webContainerViewDidSwitchToStartPage()
    
    func webContainerUserDidClickStartPageItem(_ with: URL) -> AXWebView
}

class AXWebContainerView: NSView {
    let startPageView = AXStartPageView(frame: .zero)
    weak var delegate: AXWebContainerViewDelegate?
    
    var browserTabView = AXBrowserTabView()
    
    private weak var currentWebView: AXWebView?
    
    // Observers
    private var progressBarObserver: NSKeyValueObservation?
    private var urlObserver: NSKeyValueObservation?
    
    func setupViews() {
        // This is literally all there is to the initialization code.
        startPageView.delegate = self
        browserTabView.delegate = self
        
        addSubview(browserTabView)
        browserTabView.activateConstraints([
            .allEdges: .view(self)
        ])
    }
    
    override func removeFromSuperview() {
        progressBarObserver?.invalidate()
        progressBarObserver = nil
        
        super.removeFromSuperview()
    }
    
    var currentPageAddress: URL? {
        currentWebView?.url
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
            startPageView.removeFromSuperview()
            currentWebView.load(URLRequest(url: url))
        } else {
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
    
    // MARK: - View Switching
    public func selectTabViewItem(at: Int) {
        browserTabView.selectTabViewItem(at: at)
    }
    
    // MARK: - Progress Bar Animation
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
    
    private func didSwitchToNewWebView(_ webView: AXWebView) {
        self.currentWebView = webView
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        // Observers
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
    func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        guard let tabViewItem else { return false }
        
        if tabViewItem.view == nil {
            if let newWebView = delegate?.webContainerViewSelectedTabWithEmptyView() {
                tabViewItem.view = newWebView
                
                didSwitchToNewWebView(newWebView)
                
                return true
            } else {
                tabViewItem.view = startPageView
                delegate?.webContainerViewDidSwitchToStartPage()
                currentWebView = nil
                progressBarObserver = nil
                urlObserver = nil
                return true
            }
        } else {
            if let webView = tabViewItem.view as? AXWebView {
                didSwitchToNewWebView(webView)
            }
            
            return true
        }
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        if let webView = tabViewItem?.view as? AXWebView {
            self.currentWebViewFocus(webView: webView)
        }
    }
    
    func malvonUpdateTabViewItems(tabGroup: AXTabGroup) {
        var newItems: [NSTabViewItem] = []
        
        for tab in tabGroup.tabs {
            let tabViewItem = NSTabViewItem()
            mxPrint("Tab View Update: \(tab.isTabEmpty)")
            tabViewItem.view = tab.webView
            
            newItems.append(tabViewItem)
        }
        
        self.browserTabView.tabViewItems = newItems
    }
    
    func malvonAddWebView(tab: AXTab) {
        let tabViewItem = NSTabViewItem()
        tabViewItem.view = tab.webView
        
        browserTabView.addTabViewItem(tabViewItem)
    }
    
    func malvonRemoveWebView(at: Int) {
        browserTabView.tabViewItems.remove(at: at)
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
        
        progressBarObserver = nil
        urlObserver = nil
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
        // Start AXTabButton observation. Called via delegate method.
        let webView = delegate?.webContainerUserDidClickStartPageItem(url)
        guard let selectedItem = browserTabView.selectedTabViewItem else { fatalError("Fix me") }
        selectedItem.view = webView
        
        if let webView {
            didSwitchToNewWebView(webView)
        }
    }
}
