//
//  AXTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

// MARK: - Constants
private struct AXTabButtonConstants {
    static let defaultFavicon = NSImage(
        systemSymbolName: "square.fill", accessibilityDescription: nil)
    static let defaultFaviconSleep = NSImage(
        systemSymbolName: "moon.fill", accessibilityDescription: nil)

    static let animationDuration: CFTimeInterval = 0.2
    static let shrinkScale: CGFloat = 0.9
    static let tabHeight: CGFloat = 36
    static let iconSize = NSSize(width: 16, height: 16)
    static let closeButtonSize = NSSize(width: 20, height: 16)
    static let shadowOpacity: Float = 0.3
    static let shadowRadius: CGFloat = 4.0
    static let shadowOffset = CGSize(width: 0, height: 0)

    // Colors
    static let hoverColor: NSColor = NSColor.systemGray.withAlphaComponent(0.3)
    static let selectedColor: NSColor = .textBackgroundColor
    static let backgroundColor: NSColor = .textBackgroundColor
        .withAlphaComponent(0.0)
}

class AXVerticalTabButton: NSButton, AXTabButton {
    unowned var tab: AXTab!
    weak var delegate: AXTabButtonDelegate?

    // Subviews
    var titleView: NSTextField! = NSTextField()
    var favIconImageView: NSImageView! = NSImageView()

    // Drag & Drop
    private var initialMouseDownLocation: NSPoint?

    var favicon: NSImage? {
        get {
            self.favIconImageView.image
        } set {
            self.favIconImageView.image =
                newValue == nil ? AXTabButtonConstants.defaultFavicon : newValue
            tab.icon = newValue
        }
    }

    var closeButton: AXSidebarTabCloseButton! = AXSidebarTabCloseButton()

    // Constraints
    weak var titleViewRightAnchor: NSLayoutConstraint?
    weak var heightConstraint: NSLayoutConstraint?
    var trackingArea: NSTrackingArea!

    var isSelected: Bool = false {
        didSet {
            self.layer?.backgroundColor =
                isSelected
                ? AXTabButtonConstants.selectedColor.cgColor
                : AXTabButtonConstants.backgroundColor.cgColor
            layer?.shadowOpacity = isSelected ? 0.3 : 0.0

            closeButton.isHidden = !isSelected
            titleViewRightAnchor?.constant = isSelected ? -6 : 20

            if isSelected, tab.titleObserver == nil {
                forceCreateWebview()
            }
        }
    }

    var webTitle: String = "Untitled" {
        didSet {
            // if !hasCustomTitle {
            titleView.stringValue = webTitle
            // }
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

    required init(tab: AXTab!) {
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
        layer?.shadowRadius = 4.0  // Adjust softness
        layer?.shadowOffset = CGSize(width: 0, height: 0)  // Shadow below the button

        setupViews()
    }

    func setupViews() {
        // Setup trackingArea
        self.setTrackingArea()

        if isSelected {
            self.layer?.backgroundColor =
                AXTabButtonConstants.selectedColor.cgColor
            layer?.shadowOpacity = 0.3
        }

        self.heightAnchor.constraint(equalToConstant: 36).isActive = true

        // Setup imageView
        favIconImageView.translatesAutoresizingMaskIntoConstraints = false
        favIconImageView.image =
            tab.icon != nil
            ? tab.icon : AXTabButtonConstants.defaultFaviconSleep
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
        closeButton.isHidden = !isSelected

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
            equalTo: closeButton.leftAnchor, constant: isSelected ? -7 : 7)
        titleViewRightAnchor?.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func faviconNotFound() {
        favIconImageView.image = AXTabButtonConstants.defaultFavicon
    }
}

// MARK: Tab Functions
extension AXVerticalTabButton {
    @objc
    func closeTab() {
        delegate?.tabButtonWillClose(self)
    }

    @objc
    func deactiveTab() {
        tab.deactivateWebView()

        favicon = AXTabButtonConstants.defaultFaviconSleep
        delegate?.tabButtonDeactivatedWebView(self)
    }

    func updateTitle(_ title: String) {
        self.webTitle = title

        if self.isSelected {
            self.delegate?.tabButtonActiveTitleChanged(title, for: self)
        }
    }

    // This would be called directly from a button click
    @objc
    func switchTab() {
        delegate?.tabButtonDidSelect(self)
    }
}

// MARK: Web View Functions
extension AXVerticalTabButton {
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
extension AXVerticalTabButton {
    func setTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited]
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

        self.layer?.backgroundColor = AXTabButtonConstants.selectedColor.cgColor
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
            self.layer?.backgroundColor =
                AXTabButtonConstants.hoverColor.cgColor
        }
    }

    override func mouseExited(with event: NSEvent) {
        if !isSelected {
            closeButton.isHidden = true
            titleViewRightAnchor?.constant = 20
        }

        self.layer?.backgroundColor =
            isSelected
            ? AXTabButtonConstants.selectedColor.cgColor
            : AXTabButtonConstants.backgroundColor.cgColor
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

/*
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
*/

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
        self.bezelStyle = .smallSquare
        self.setTrackingArea()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea.init(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseUp(with event: NSEvent) {
        mouseDown = false
        if self.isMousePoint(
            self.convert(event.locationInWindow, from: nil), in: self.bounds) {
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
