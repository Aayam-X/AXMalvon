//
//  AXTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

let AX_DEFAULT_FAVICON = NSImage(
    systemSymbolName: "square.fill", accessibilityDescription: nil)

let AX_DEFAULT_FAVICON_SLEEP = NSImage(
    systemSymbolName: "moon.fill", accessibilityDescription: nil)

private let AX_DEFAULT_FAVICON_SCRIPT = """
    ["icon", "shortcut icon", "apple-touch-icon"].map(r => document.head.querySelector(`link[rel="${r}"]`)).find(l => l)?.href || ""
    """

protocol AXTabButtonDelegate: AnyObject {
    func tabButtonDidSelect(_ tabButton: AXTabButton)
    func tabButtonWillClose(_ tabButton: AXTabButton)
    func tabButtonActiveTitleChanged(
        _ newTitle: String, for tabButton: AXTabButton)

    func tabButtonDeactivatedWebView(_ tabButton: AXTabButton)
}

class AXTabButton: NSButton {
    unowned var tab: AXTab!
    weak var delegate: AXTabButtonDelegate?

    // Subviews
    var titleView: NSTextField! = NSTextField()
    var favIconImageView: NSImageView! = NSImageView()

    // Drag & Drop
    private var initialMouseDownLocation: NSPoint?

    var favicon: NSImage? {
        set {
            self.favIconImageView.image =
                newValue == nil ? AX_DEFAULT_FAVICON : newValue
        }
        get {
            self.favIconImageView.image
        }
    }

    var closeButton: AXSidebarTabCloseButton! = AXSidebarTabCloseButton()

    // Colors
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)

    // Observers
    var titleObserver: NSKeyValueObservation?

    // Other
    private var hasDrawn = false
    var hasCustomTitle = false

    weak var titleViewRightAnchor: NSLayoutConstraint?
    weak var heightConstraint: NSLayoutConstraint?
    var trackingArea: NSTrackingArea!

    var isSelected: Bool = false {
        didSet {
            self.layer?.backgroundColor =
                isSelected ? selectedColor.cgColor : .clear
            if self.titleObserver == nil {
                forceCreateWebview()
            }
        }
    }

    var webTitle: String = "Untitled" {
        didSet {
            if !hasCustomTitle {
                titleView.stringValue = webTitle
            }
        }
    }

    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()

        // Add items to the context menu
        let item = NSMenuItem(
            title: "Deactivate Tab", action: #selector(deactiveTab),
            keyEquivalent: "")
        item.target = self

        menu.addItem(item)

        return menu
    }()

    init(tab: AXTab) {
        self.tab = tab
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        title = ""
        self.heightConstraint = heightAnchor.constraint(equalToConstant: 30)
        heightConstraint!.isActive = true
    }

    override func viewWillDraw() {
        guard !hasDrawn else { return }
        defer { hasDrawn = true }
        // Setup trackingArea
        self.setTrackingArea()

        // Setup imageView
        favIconImageView.translatesAutoresizingMaskIntoConstraints = false
        favIconImageView.image = AX_DEFAULT_FAVICON_SLEEP
        favIconImageView.contentTintColor = .textBackgroundColor
            .withAlphaComponent(0.2)
        addSubview(favIconImageView)
        favIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
            .isActive = true
        favIconImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5)
            .isActive = true
        favIconImageView.widthAnchor.constraint(equalToConstant: 16).isActive =
            true
        favIconImageView.heightAnchor.constraint(equalToConstant: 16).isActive =
            true

        // Setup closeButton
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.target = self
        closeButton.action = #selector(closeTab)
        addSubview(closeButton)
        closeButton.image = NSImage(
            systemSymbolName: "xmark", accessibilityDescription: nil)
        closeButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        closeButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -5)
            .isActive = true
        closeButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive =
            true
        closeButton.isHidden = true

        // Setup titleView
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.isEditable = false  // This should be set to true in a while :)
        titleView.alignment = .left
        titleView.isBordered = false
        titleView.usesSingleLineMode = true
        titleView.drawsBackground = false
        titleView.lineBreakMode = .byTruncatingTail
        addSubview(titleView)
        titleView.leftAnchor.constraint(
            equalTo: favIconImageView.rightAnchor, constant: 5
        ).isActive = true
        titleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive =
            true
        titleViewRightAnchor = titleView.rightAnchor.constraint(
            equalTo: closeButton.leftAnchor, constant: 5)
        titleViewRightAnchor?.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        titleObserver?.invalidate()
        titleObserver = nil
    }

    func faviconNotFound() {
        favIconImageView.image = AX_DEFAULT_FAVICON
    }
}

// MARK: Tab Functions
extension AXTabButton {
    @objc func closeTab() {
        delegate?.tabButtonWillClose(self)
    }

    @objc func deactiveTab() {
        titleObserver?.invalidate()
        titleObserver = nil
        favicon = AX_DEFAULT_FAVICON_SLEEP
        delegate?.tabButtonDeactivatedWebView(self)
    }

    func updateTitle(_ to: String) {
        self.webTitle = to
        tab.title = to

        if self.isSelected {
            self.delegate?.tabButtonActiveTitleChanged(to, for: self)
        }
    }

    // This would be called directly from a button click
    @objc func switchTab() {
        delegate?.tabButtonDidSelect(self)
    }
}

// MARK: Web View Functions
extension AXTabButton {
    public func stopObserving() {
        titleObserver?.invalidate()
        titleObserver = nil
    }

    func findFavicon(for webView: AXWebView) {
        Task {
            do {
                guard
                    let faviconURLString = try await webView.evaluateJavaScript(
                        AX_DEFAULT_FAVICON_SCRIPT) as? String,
                    let faviconURL = URL(string: faviconURLString)
                else {
                    self.favicon = nil
                    return
                }

                // Download the favicon asynchronously
                self.favicon = try await downloadFavicon(from: faviconURL)
            } catch {
                // Handle errors gracefully
                print("Error fetching or downloading favicon: \(error)")
                self.favicon = nil
            }
        }
    }

    func downloadFavicon(from url: URL) async throws -> NSImage? {
        // Use `URLSession` with async API
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = NSImage(data: data) else {
            throw NSError(
                domain: "DownloadFaviconError", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        return image
    }

    public func startObserving() {
        guard let webView = tab._webView else { return }

        createObserver(webView)
    }

    func forceCreateWebview() {
        let webView = tab.webView
        createObserver(webView)
    }

    func createObserver(_ webView: AXWebView) {
        Task {
            try await Task.sleep(for: .seconds(2.22))
            findFavicon(for: webView)
        }

        self.titleObserver = webView.observe(
            \.title, options: .new,
            changeHandler: { [weak self] _, _ in
                let title = webView.title ?? "Untitled"
                self?.updateTitle(title)

                // Ensure we have a valid URL and host
                guard let newURL = webView.url,
                    let newHost = newURL.host
                else { return }

                // Extract characters after the first 3 in the host
                let newHostSubstring = newHost.dropFirst(3).prefix(3)
                if let currentHost = self?.tab.url?.host {
                    let currentHostSubstring = currentHost.dropFirst(3).prefix(
                        3)

                    // Compare the substrings
                    if newHostSubstring != currentHostSubstring {
                        // If the substrings are different, find a new favicon
                        self?.tab.url = webView.url
                        self?.findFavicon(for: webView)
                    }
                }
            })
    }

}

// MARK: Mouse Functions
extension AXTabButton {
    func setTrackingArea() {
        let options: NSTrackingArea.Options = [
            .activeAlways, .inVisibleRect, .mouseEnteredAndExited,
        ]
        trackingArea = NSTrackingArea.init(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseDown(with event: NSEvent) {
        initialMouseDownLocation = event.locationInWindow

        if event.clickCount == 1 {
            self.switchTab()
            self.isSelected = true
        } else if event.clickCount == 2 {
            // Double click: Allow User to Edit the Title
        }

        self.layer?.backgroundColor = selectedColor.cgColor
    }

    override func mouseEntered(with event: NSEvent) {
        titleViewRightAnchor?.constant = 0
        closeButton.isHidden = false

        if !isSelected {
            self.layer?.backgroundColor = hoverColor.cgColor
        }
    }

    override func mouseExited(with event: NSEvent) {
        titleViewRightAnchor?.constant = 20
        closeButton.isHidden = true
        self.layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
    }

    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)

        // Show the context menu at the mouse location
        let locationInButton = self.convert(event.locationInWindow, from: nil)

        // Show the context menu at the converted location relative to the button
        contextMenu.popUp(positioning: nil, at: locationInButton, in: self)
    }
}

// MARK: - Draging Source
extension AXTabButton: NSDraggingSource, NSPasteboardWriting {
    // Define drag operations
    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        return .move
    }

    // Provide writable types for the pasteboard
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard
        .PasteboardType]
    {
        return [.axTabButton]
    }

    // Provide the pasteboard property list (button.tag)
    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType)
        -> Any?
    {
        guard type == .axTabButton else { return nil }
        return "\(self.tag)"  // Send tag as a string
    }

    // Start a dragging session when the mouse is dragged
    override func mouseDragged(with event: NSEvent) {
        guard let initialLocation = initialMouseDownLocation else { return }

        // Calculate the distance moved
        let currentLocation = event.locationInWindow
        let distance = hypot(
            currentLocation.x - initialLocation.x,
            currentLocation.y - initialLocation.y)

        guard distance > 5.0 else { return }

        let draggingItem = NSDraggingItem(pasteboardWriter: self)

        // Define the item's image for the drag session
        let draggingFrame = self.bounds
        draggingItem.setDraggingFrame(draggingFrame, contents: self.toImage())

        // Start the dragging session
        self.beginDraggingSession(
            with: [draggingItem], event: event, source: self)

        self.isHidden = true
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        self.isHidden = false
    }

    override func draggingEnded(_ sender: any NSDraggingInfo) {
        self.isHidden = false
    }

    override func concludeDragOperation(_ sender: (any NSDraggingInfo)?) {
        self.isHidden = false
    }

    // Helper: Create a snapshot of the button for the dragging image
    func toImage() -> NSImage? {
        guard
            let bitmapImageRepresentation =
                self.bitmapImageRepForCachingDisplay(in: bounds)
        else {
            return nil
        }
        bitmapImageRepresentation.size = bounds.size
        self.cacheDisplay(in: bounds, to: bitmapImageRepresentation)

        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmapImageRepresentation)

        return image
    }
}

extension NSPasteboard.PasteboardType {
    static let axTabButton = NSPasteboard.PasteboardType(
        "com.ayaamx.AXMalvon.tab")
}

// MARK: - Close Button
class AXSidebarTabCloseButton: NSButton {
    var trackingArea: NSTrackingArea!

    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    var defaultColor: CGColor? = .none
    var mouseDown: Bool = false

    init(isSelected: Bool = false) {
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        self.setTrackingArea()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTrackingArea() {
        let options: NSTrackingArea.Options = [
            .activeAlways, .inVisibleRect, .mouseEnteredAndExited,
        ]
        trackingArea = NSTrackingArea.init(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseUp(with event: NSEvent) {
        mouseDown = false
        if self.isMousePoint(
            self.convert(event.locationInWindow, from: nil), in: self.bounds)
        {
            sendAction(action, to: target)
        }

        layer?.backgroundColor = defaultColor
    }

    override func mouseDown(with event: NSEvent) {
        mouseDown = true
        self.layer?.backgroundColor = hoverColor.cgColor
    }

    override func mouseEntered(with event: NSEvent) {
        if isEnabled {
            self.layer?.backgroundColor = hoverColor.cgColor
        }
    }

    override func mouseDragged(with event: NSEvent) {
        mouseDown = false
    }

    override func mouseExited(with event: NSEvent) {
        self.layer?.backgroundColor = defaultColor
    }
}
