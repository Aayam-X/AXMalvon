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
        
        self.layer?.backgroundColor = appProperties.tabManager.currentTabGroup.color.cgColor
        
        addSubview(websiteTitleLabel)
        websiteTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: -0.5).isActive = true
        websiteTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        websiteTitleLabel.stringValue = "Empty Window"
        
        splitView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(splitView)
        splitView.topAnchor.constraint(equalTo: topAnchor, constant: 14).isActive = true
        splitView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14).isActive = true
        splitView.leftAnchor.constraint(equalTo: leftAnchor, constant: 14).isActive = true
        splitView.rightAnchor.constraint(equalTo: rightAnchor, constant: -14).isActive = true
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
        
        webView.frame = splitView.frame
        splitView.addArrangedSubview(webView)
        webView.autoresizingMask = [.height, .width]
        
        self.window?.makeFirstResponder(currentWebView)
        
        progressBarObserver = webView.observe(\.estimatedProgress, changeHandler: { [self] _, _ in
            updateProgress(webView.estimatedProgress)
        })
    }
    
    func updateProgress(_ newValue: CGFloat) {
        appProperties.sidebarView.gestureView.progress = newValue
        
        if newValue >= 0.93 {
             // Go very fast to 100!
            appProperties.window.splitView.updateProgress(1.0)
         } else {
             appProperties.window.splitView.smoothProgress(newValue)
         }
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
        //        if let themeColor = webView.themeColor {
        //            appProperties.updateColor(newColor: themeColor)
        //        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return appProperties.tabManager.createNewPopupTab(with: configuration)
    }
}

fileprivate func insetWebView(_ bounds: NSRect) -> NSRect {
    return NSRect(x: bounds.origin.x + 1, y: bounds.origin.y + 14, width: bounds.size.width - 15, height: bounds.size.height - 28)
}
