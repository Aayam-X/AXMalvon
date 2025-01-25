//
//  AXWebContainerView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import AppKit
import WebKit

protocol AXWebContainerViewDelegate: AnyObject {
    func webViewProgressDidChange(to: Double, _ smooth: Bool)
    func webViewCreateWebView(config: WKWebViewConfiguration) -> WKWebView
}

class AXWebContainerView: NSView {
    weak var delegate: AXWebContainerViewDelegate?

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

        //self.layer?.backgroundColor = NSColor.systemIndigo.withAlphaComponent(0.3).cgColor

        addSubview(websiteTitleLabel)
        websiteTitleLabel.topAnchor.constraint(
            equalTo: topAnchor, constant: -0.5
        ).isActive = true
        websiteTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
            .isActive = true
        websiteTitleLabel.stringValue = "Empty Window"

        splitView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(splitView)
        splitView.topAnchor.constraint(equalTo: topAnchor, constant: 14)
            .isActive = true
        splitView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
            .isActive = true
        splitView.leftAnchor.constraint(equalTo: leftAnchor, constant: 14)
            .isActive = true
        splitView.rightAnchor.constraint(equalTo: rightAnchor, constant: -14)
            .isActive = true
    }

    deinit {
        progressBarObserver = nil
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

        progressBarObserver = webView.observe(
            \.estimatedProgress, options: [.new]
        ) { [weak self] _, change in
            if let newProgress = change.newValue {
                self?.updateProgress(newProgress)
            } else {
                print("Progress change has no new value.")
            }
        }
    }

    func createEmptyView() {
        currentWebView?.removeFromSuperview()
        self.websiteTitleLabel.stringValue = "Empty Window"
    }

    func removeAllWebViews() {
        currentWebView?.loadHTMLString("", baseURL: nil)
        currentWebView?.removeFromSuperview()
        self.currentWebView = nil
        self.websiteTitleLabel.stringValue = "Empty Window"

        progressBarObserver = nil
    }

    func updateProgress(_ newValue: CGFloat) {
        if newValue >= 0.93 {
            // Go very fast to 100!
            delegate?.webViewProgressDidChange(to: newValue, false)
        } else {
            delegate?.webViewProgressDidChange(to: newValue, true)
        }
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

    override func viewWillDraw() {
        self.layer?.cornerRadius = 5.0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AXWebContainerView: WKNavigationDelegate, WKUIDelegate,
    WKDownloadDelegate
{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //        if let themeColor = webView.themeColor {
        //            appProperties.updateColor(newColor: themeColor)
        //        }
        print("Webview finished loading")
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        delegate?.webViewCreateWebView(config: configuration)
    }

    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor ([URL]?) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Select File"
        panel.prompt = "Open"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
//        let result = await panel.begin(forDirectory: nil, file: nil)
        completionHandler(panel.urls)
    }
    
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        print("DONWLOAD DOWNLAOD")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let _ = navigationResponse.response.suggestedFilename {
            if navigationResponse.response.mimeType != "text/html" {
                decisionHandler(.download)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(
        _ webView: WKWebView, navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    ) {
        download.delegate = self
    }

    func download(
        _ download: WKDownload, decideDestinationUsing response: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Select Download Destination"
        panel.prompt = "Save"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        // Use `await` to handle the panel's presentation
        let result = await panel.begin()
        if result == .OK, let directoryURL = panel.url {
            return directoryURL.appendingPathComponent(suggestedFilename)
        }
        return nil
    }

    func downloadDidFinish(_ download: WKDownload) {
        print("Download finished!")
    }
}

private func insetWebView(_ bounds: NSRect) -> NSRect {
    return NSRect(
        x: bounds.origin.x + 1, y: bounds.origin.y + 14,
        width: bounds.size.width - 15, height: bounds.size.height - 28)
}
