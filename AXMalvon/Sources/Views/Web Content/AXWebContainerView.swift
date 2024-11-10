//
//  AXWebContainerView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import AppKit
import WebKit

class AXWebContainerView: NSView {
    weak var appProperties: AXSessionProperties!
    private var hasDrawn: Bool = false
    weak var currentWebView: AXWebView?
    
    private lazy var splitView = AXWebContainerSplitView()
    var progressBarObserver: NSKeyValueObservation?
    
    var websiteTitleLabel: NSTextField = {
        let title = NSTextField()
        title.isEditable = false
        title.alignment = .left
        title.isBordered = false
        title.usesSingleLineMode = true
        title.drawsBackground = false
        title.alphaValue = 0.3
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
    
    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        
        addSubview(websiteTitleLabel)
        websiteTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: -0.5).isActive = true
        websiteTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        websiteTitleLabel.stringValue = "Empty Window"
        
        splitView.frame = bounds.insetBy(dx: 14, dy: 14)
        addSubview(splitView)
        splitView.autoresizingMask = [.height, .width]
        
        // Setup progress bar
        appProperties.progressBar.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(appProperties.progressBar)
        appProperties.progressBar.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        appProperties.progressBar.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        appProperties.progressBar.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        appProperties.progressBar.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        appProperties.progressBar.smoothProgress(50)
    }
    
    init(appProperties: AXSessionProperties) {
        self.appProperties = appProperties
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateView(webView: AXWebView) {
        currentWebView?.removeFromSuperview()
        
        self.currentWebView = webView
        self.websiteTitleLabel.stringValue = webView.title ?? "Untitled Page"
        self.currentWebView!.uiDelegate = self
        self.currentWebView!.navigationDelegate = self
        splitView.addArrangedSubview(webView)
        self.window?.makeFirstResponder(currentWebView)
        
        progressBarObserver = webView.observe(\.estimatedProgress, changeHandler: { [self] _, _ in
            let progress: CGFloat = webView.estimatedProgress
            if progress >= 0.93 {
                // Go very fast to 100!
                appProperties.progressBar.updateProgress(1.0)
            } else {
                appProperties.progressBar.smoothProgress(progress)
            }
        })
    }
}

fileprivate class AXWebContainerSplitView: NSSplitView, NSSplitViewDelegate {
    init() {
        super.init(frame: .zero)
        delegate = self
        isVertical = true
        dividerStyle = .thin
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 50
    }
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }
    
    override func drawDivider(in rect: NSRect) {
        // Make divider invisble
    }
    
    override func viewWillDraw() {
        self.layer?.cornerRadius = 5.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AXWebContainerView: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading webpage")
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return appProperties.tabManager.createNewPopupTab(with: configuration)
    }
}
