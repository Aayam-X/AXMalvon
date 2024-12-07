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
    (d=>{const h=d.head,l=["icon","shortcut icon","apple-touch-icon","mask-icon"];for(let r of l)if((r=h.querySelector(`link[rel="${r}"]`))&&r.href)return r.href;return d.location.origin+"/favicon.ico"})(document)
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

    // Animations
    private let shrinkScale: CGFloat = 0.9  // Factor to shrink the button by
    private let animationDuration: CFTimeInterval = 0.2

    // Singleton session to reduce resource allocation
    let session: URLSession = {
        // Hyper-optimized session configuration
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 1.5  // Aggressive timeout
        config.timeoutIntervalForResource = 1.5
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.httpMaximumConnectionsPerHost = 1
        config.waitsForConnectivity = false

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .background

        return URLSession(
            configuration: config,
            delegate: nil,
            delegateQueue: queue
        )
    }()

    var favicon: NSImage? {
        set {
            self.favIconImageView.image =
                newValue == nil ? AX_DEFAULT_FAVICON : newValue
            tab.icon = newValue
        }
        get {
            self.favIconImageView.image
        }
    }

    var closeButton: AXSidebarTabCloseButton! = AXSidebarTabCloseButton()

    // Colors
    var hoverColor: NSColor = NSColor.systemGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = .textBackgroundColor

    // Other
    private var hasDrawn = false

    weak var titleViewRightAnchor: NSLayoutConstraint?
    weak var heightConstraint: NSLayoutConstraint?
    var trackingArea: NSTrackingArea!

    var isSelected: Bool = false {
        didSet {
            self.layer?.backgroundColor =
                isSelected ? selectedColor.cgColor : .clear
            layer?.shadowOpacity = isSelected ? 0.3 : 0.0
            if isSelected, tab.titleObserver == nil {
                forceCreateWebview()
            }
        }
    }

    var webTitle: String = "Untitled" {
        didSet {
            //if !hasCustomTitle {
            titleView.stringValue = webTitle
            //}
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
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        title = ""

        self.wantsLayer = true
        self.layer?.cornerRadius = 10
        layer?.masksToBounds = false

        layer?.shadowColor = NSColor.textColor.cgColor
        layer?.shadowOpacity = 0.0  // Adjust shadow visibility
        layer?.shadowRadius = 1.0  // Adjust softness
        layer?.shadowOffset = CGSize(width: 0, height: 2)  // Shadow below the button
    }

    override func viewWillDraw() {
        guard !hasDrawn else { return }
        defer { hasDrawn = true }
        // Setup trackingArea
        self.setTrackingArea()

        if isSelected {
            self.layer?.backgroundColor = selectedColor.cgColor
            layer?.shadowOpacity = 0.3
        }

        self.heightAnchor.constraint(equalToConstant: 36).isActive = true

        // Setup imageView
        favIconImageView.translatesAutoresizingMaskIntoConstraints = false
        favIconImageView.image =
            tab.icon != nil ? tab.icon : AX_DEFAULT_FAVICON_SLEEP
        favIconImageView.contentTintColor = .textBackgroundColor
            .withAlphaComponent(0.2)
        addSubview(favIconImageView)
        favIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
            .isActive = true
        favIconImageView.leftAnchor.constraint(
            equalTo: leftAnchor, constant: 10
        )
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
        closeButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -7)
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
        titleView.textColor = .textColor
        addSubview(titleView)
        titleView.leftAnchor.constraint(
            equalTo: favIconImageView.rightAnchor, constant: 5
        ).isActive = true
        titleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive =
            true
        titleViewRightAnchor = titleView.rightAnchor.constraint(
            equalTo: closeButton.leftAnchor, constant: 7)
        titleViewRightAnchor?.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        tab.deactivateWebView()

        favicon = AX_DEFAULT_FAVICON_SLEEP
        delegate?.tabButtonDeactivatedWebView(self)
    }

    func updateTitle(_ to: String) {
        self.webTitle = to

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
    func findFavicon(for webView: AXWebView) {
        // Weak self to prevent retain cycles
        Task(priority: .low) { [weak self] in
            guard let self = self else { return }

            do {
                // Ultra-lightweight favicon extraction
                guard
                    let faviconURLString = try? await webView
                        .evaluateJavaScript(AX_DEFAULT_FAVICON_SCRIPT)
                        as? String,
                    let faviconURL = URL(string: faviconURLString)
                else {
                    self.favicon = nil
                    return
                }

                // Minimal, quick download
                self.favicon = try await quickFaviconDownload(from: faviconURL)
            } catch {
                // Ultra-minimal error handling
                self.favicon = nil
            }
        }
    }

    // Static method to minimize instance overhead
    private func quickFaviconDownload(from url: URL) async throws -> NSImage? {
        // Ultra-lightweight download with strict size limit
        let (data, _) = try await session.data(from: url)

        // Minimal image creation with immediate downsizing
        guard let image = NSImage(data: data)?.downsizedIcon() else {
            throw URLError(.cannotParseResponse)
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
        tab.startTitleObservation(for: self)
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

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().layer?.setAffineTransform(
                CGAffineTransform(scaleX: 1, y: 0.95))
        }

        if event.clickCount == 1 {
            self.switchTab()
            self.isSelected = true
        } else if event.clickCount == 2 {
            // Double click: Allow User to Edit the Title
        }

        self.layer?.backgroundColor = selectedColor.cgColor
    }

    override func mouseUp(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().layer?.setAffineTransform(.identity)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        titleViewRightAnchor?.constant = -6
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

// Extension for ultra-lightweight image downsizing
extension NSImage {
    func downsizedIcon() -> NSImage? {
        let targetSize = NSSize(width: 16, height: 16)
        let newImage = NSImage(size: targetSize)

        newImage.lockFocus()
        defer { newImage.unlockFocus() }

        self.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: self.size),
            operation: .sourceOver,
            fraction: 1.0
        )

        return newImage
    }
}
