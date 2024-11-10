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
    
    lazy var testButton: AXButton = {
        let button = AXButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.target = self
        button.action = #selector(testButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        
        addSubview(websiteTitleLabel)
        websiteTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: -0.5).isActive = true
        websiteTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        websiteTitleLabel.stringValue = "Testing"
        
        addSubview(testButton)
        testButton.topAnchor.constraint(equalTo: topAnchor, constant: -0.5).isActive = true
        testButton.leftAnchor.constraint(equalTo: websiteTitleLabel.rightAnchor).isActive = true
        
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
        self.currentWebView!.uiDelegate = self
        self.currentWebView!.navigationDelegate = self
        splitView.addArrangedSubview(webView)
        
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
    
    @objc func testButtonAction() {
//        appProperties.tabManager.createNewTab(from: "https://www.apple.com/ca")
//        appProperties.tabManager.switchTab(to: 0)
        appProperties.searchBarWindow.show()
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

extension AXWebContainerView {
    override var acceptsFirstResponder: Bool {
        true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.keyCode {
            case 18: // '1' key
                switchToTab(index: 0)
            case 19: // '2' key
                switchToTab(index: 1)
            case 20: // '3' key
                switchToTab(index: 2)
            case 21: // '4' key
                switchToTab(index: 3)
            case 22: // '5' key
                switchToTab(index: 4)
            case 23: // '6' key
                switchToTab(index: 5)
            case 26: // '7' key
                switchToTab(index: 6)
            default:
                break
            }
        } else {
            super.keyDown(with: event)
        }
    }
    
    func switchToTab(index: Int) {
        // Check if the tab index is valid
        if index < appProperties.tabManager.currentTabGroup.tabs.count {
            // Hide all tabs
            appProperties.tabManager.currentTabGroup.switchTab(to: index)
        } else {
            // Switch to the last tab if the index is out of range
            appProperties.tabManager.currentTabGroup.switchTab(to: appProperties.tabManager.currentTabGroup.tabs.count - 1)
        }
    }
}
