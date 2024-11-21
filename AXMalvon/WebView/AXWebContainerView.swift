//
//  AXWebContainerView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import AppKit
import WebKit

let faviconJavaScript = """
    ["icon", "shortcut icon", "apple-touch-icon"].map(r => document.head.querySelector(`link[rel="${r}"]`)).find(l => l)?.href || ""
    """

//let faviconJavaScript1 = """
//(() => {
//  const favicon = ["icon", "shortcut icon", "apple-touch-icon"]
//    .map(r => document.head.querySelector(`link[rel="${r}"]`))
//    .find(l => l)?.href ||
//    document.head.querySelector('meta[property="og:image"]')?.content ||
//    document.querySelector('link[rel="icon"]')?.href;
//  return favicon || "";
//})();
//"""
//
//let faviconJavaScript = """
//(() => {
//  const favicon = ["icon", "shortcut icon", "apple-touch-icon"]
//    .map(r => document.head.querySelector(`link[rel="${r}"]`))
//    .find(l => l)?.href ||
//    document.querySelector('meta[name="icon"]')?.content ||
//    document.querySelector('link[rel="icon"]')?.href ||
//    document.querySelector('meta[property="og:image"]')?.content;
//  return favicon || "";
//})();
//"""

protocol AXWebContainerViewDelegate: AnyObject {
    func webViewDidFinishLoading()
    func webViewStartedLoading(with progress: Double)
    
    func webViewCreateWebView(config: WKWebViewConfiguration) -> WKWebView

    func webContainerViewRequestsSidebar() -> AXSidebarView
    func webContainerFoundFavicon(image: NSImage?)
}

class AXWebContainerView: NSView {
    weak var delegate: AXWebContainerViewDelegate?
    weak var sidebar: AXSidebarView?

    private var hasDrawn: Bool = false
    weak var currentWebView: AXWebView?

    private lazy var splitView = AXWebContainerSplitView()

    var sidebarTrackingArea: NSTrackingArea!
    var isAnimating: Bool = false
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

        updateTrackingArea()
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
        currentWebView?.uiDelegate = nil
        currentWebView?.navigationDelegate = nil

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
    
    func updateProgress(_ value: Double) {
        delegate?.webViewStartedLoading(with: value)
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
        guard let sidebar = sidebar else { return }
        addSubview(sidebar)

        if !isAnimating {
            sidebar.layer?.backgroundColor =
                NSColor.red.withAlphaComponent(0.3).cgColor
            sidebar.extendVisualEffectView()
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
        print("Mouse exited sidebar")
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

}

extension AXWebContainerView: WKNavigationDelegate, WKUIDelegate,
    WKDownloadDelegate
{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Webview finished loading")
        delegate?.webViewDidFinishLoading()

        webView.evaluateJavaScript(faviconJavaScript) { (result, error) in
            if let faviconURLString = result as? String,
                let faviconURL = URL(string: faviconURLString)
            {
                self.downloadFavicon(from: faviconURL)
            } else {
                print("No favicon found or error: \(String(describing: error))")
                self.delegate?.webContainerFoundFavicon(image: nil)
            }
        }
    }

    func downloadFavicon(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            guard let data = data, error == nil, let image = NSImage(data: data)
            else {
                print(
                    "Failed to download favicon: \(String(describing: error))")
                return
            }
            DispatchQueue.main.async {
                self.delegate?.webContainerFoundFavicon(image: image)
            }
        }
        task.resume()
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        delegate?.webViewCreateWebView(config: configuration)
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
        print("DONWLOAD DOWNLAOD")
    }

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
        print("Download finished!")
    }
    
    func enableContentBlockers() {
        // Ensure the blocker list file exists
        guard let blockerListURL = Bundle.main.url(forResource: "blockerList", withExtension: "json") else {
            print("Blocker list file not found.")
            return
        }
        
        // Load the content of the blocker list JSON efficiently
        guard let blockerListData = try? Data(contentsOf: blockerListURL),
              let blockerListString = String(data: blockerListData, encoding: .utf8) else {
            print("Failed to load or decode blocker list.")
            return
        }
        
        // Compile the content rule list
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "ContentBlockingRules",
            encodedContentRuleList: blockerListString
        ) { [weak self] contentRuleList, error in
            // Handle any compilation errors
            if let error = error {
                print("Failed to compile content rule list: \(error.localizedDescription)")
                return
            }
            
            // Safely unwrap the content rule list
            guard let contentRuleList = contentRuleList, let self = self else { return }
            
            // Apply the content rule list to the web view configuration
            let configuration = self.currentWebView?.configuration
            configuration?.userContentController.add(contentRuleList)
            
            // Reload the web view efficiently
            self.currentWebView?.reload()
        }
    }

}

private func insetWebView(_ bounds: NSRect) -> NSRect {
    return NSRect(
        x: bounds.origin.x + 1, y: bounds.origin.y + 14,
        width: bounds.size.width - 15, height: bounds.size.height - 28)
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
