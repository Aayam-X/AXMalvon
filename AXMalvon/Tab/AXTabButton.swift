//
//  AXTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//

import AppKit

let AX_DEFAULT_FAVICON = NSImage(
    systemSymbolName: "square.fill", accessibilityDescription: nil)

let AX_DEFAULT_FAVICON_SLEEP = NSImage(
    systemSymbolName: "moon.fill", accessibilityDescription: nil)

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
                forcedStartObserving()
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

// MARK: WebView Functions
extension AXTabButton {
    public func stopObserving() {
        titleObserver?.invalidate()
        titleObserver = nil
    }

    public func forcedStartObserving() {
        let webView = tab.webView

        self.titleObserver = webView.observe(
            \.title, options: .new,
            changeHandler: { [weak self] _, _ in
                let title = webView.title ?? "Untitled"
                self?.updateTitle(title)
            })
    }

    public func startObserving() {
        guard let webView = tab._webView else { return }

        let title0 = webView.title ?? "Untitled"
        self.updateTitle(title0)

        self.titleObserver = webView.observe(
            \.title, options: .new,
            changeHandler: { [weak self] _, _ in
                let title = webView.title ?? "Untitled"
                self?.updateTitle(title)
            })
    }
}

// MARK: Mouse Functions
extension AXTabButton {
    func setTrackingArea() {
        let options: NSTrackingArea.Options = [
            .activeAlways, .inVisibleRect, .mouseEnteredAndExited,
            .enabledDuringMouseDrag,
        ]
        trackingArea = NSTrackingArea.init(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 1 {
            self.switchTab()
            self.isSelected = true
        } else if event.clickCount == 2 {
            // Edit the title.
            print("Double click")
            //
            //            userDoubleClicked = true
            //            titleView.isEditable = true
            //            titleView.placeholderString = titleView.stringValue
            //            window?.makeFirstResponder(titleView)
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

        //        if userDoubleClicked {
        //            if titleView.stringValue.isEmpty || titleView.stringValue == titleView.placeholderString {
        //                hasCustomTitle = false
        //                titleView.stringValue = webTitle
        //            } else {
        //                hasCustomTitle = true
        //            }
        //
        //            titleView.currentEditor()?.selectedRange = .init(location: -1, length: 0)
        //            titleView.isEditable = false
        //            userDoubleClicked = false
        //        }
    }

    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)

        // Show the context menu at the mouse location
        let locationInButton = self.convert(event.locationInWindow, from: nil)

        // Show the context menu at the converted location relative to the button
        contextMenu.popUp(positioning: nil, at: locationInButton, in: self)
    }
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
