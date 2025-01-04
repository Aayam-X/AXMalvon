//
//  AXTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class AXVerticalTabButton: NSButton, AXTabButton {
    unowned var tab: AXTab!
    weak var delegate: AXTabButtonDelegate?

    // Subviews
    var favIconImageView: NSImageView! = NSImageView()
    var titleView: NSTextField! = NSTextField()
    var closeButton: AXSidebarTabCloseButton! = AXSidebarTabCloseButton()
    var trackingArea: NSTrackingArea!

    var webTitle: String = "Untitled" {
        didSet {
            titleView.stringValue = webTitle
        }
    }

    var favicon: NSImage? {
        get {
            self.favIconImageView.image
        }
        set {
            self.favIconImageView.image =
                newValue == nil ? AXTabButtonConstants.defaultFavicon : newValue
        }
    }

    var isSelected: Bool = false {
        didSet {
            self.updateAppearance()

            if isSelected, tab.titleObserver == nil {
                forceCreateWebview()
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

    required init(tab: AXTab!) {
        self.tab = tab
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isBordered = false
        self.bezelStyle = .smallSquare
        title = ""

        self.wantsLayer = true
        self.layer?.cornerRadius = 10
        layer?.masksToBounds = false

        setupViews()
        setupShadow()
        setupTrackingArea()

        if let tab {
            tab.onWebViewInitialization =
                self.onWebViewInitializationListenerHandler
        }

        if tab?._webView == nil {
            titleView.stringValue = "New Tab"
        }
    }

    func onWebViewInitializationListenerHandler(webView: AXWebView) {
        mxPrint(#function, "CALLEDDDD")
        self.createObserver(webView)
    }

    override func viewWillDraw() {
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.heightAnchor.constraint(equalToConstant: 33).isActive = true

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
        titleView.rightAnchor.constraint(equalTo: closeButton.leftAnchor)
            .isActive =
            true

        titleView.setContentCompressionResistancePriority(
            .defaultLow, for: .horizontal)
        titleView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    func faviconNotFound() {
        favIconImageView.image = AXTabButtonConstants.defaultFavicon
    }
}

// MARK: Tab Functions
extension AXVerticalTabButton {
    @objc
    func closeTab() {
        tab?.stopTitleObservation()
        delegate?.tabButtonWillClose(self)
    }

    @objc
    func deactiveTab() {
        tab.deactivateWebView()

        favicon = AXTabButtonConstants.defaultFaviconSleep
        delegate?.tabButtonDeactivatedWebView(self)
    }

    // This would be called directly from a button click
    @objc
    func switchTab() {
        delegate?.tabButtonDidSelect(self)
    }

    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [
            .activeAlways, .inVisibleRect, .mouseEnteredAndExited,
        ]
        trackingArea = NSTrackingArea(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseDown(with event: NSEvent) {
        closeButton.isHidden = false
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().layer?.setAffineTransform(
                CGAffineTransform(scaleX: 1, y: 0.95))
        }

        self.switchTab()
        isSelected = true
    }

    override func mouseUp(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().layer?.setAffineTransform(.identity)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        if !isSelected {
            self.layer?.backgroundColor =
                NSColor.systemGray.withAlphaComponent(0.3).cgColor
        }
        closeButton.isHidden = false
    }

    override func mouseExited(with event: NSEvent) {
        if !isSelected {
            closeButton.isHidden = true
        }
        updateAppearance()
    }

    private func updateAppearance() {
        let backgroundColor: CGColor
        if isSelected {
            if effectiveAppearance.name == .darkAqua {
                backgroundColor = .black
                layer?.shadowColor = .white
            } else {
                backgroundColor = .white
                layer?.shadowColor = .black
            }
            layer?.shadowOpacity = 0.3
            closeButton.isHidden = false
        } else {
            backgroundColor = .clear
            layer?.shadowOpacity = 0.0
            closeButton.isHidden = true
        }

        self.layer?.backgroundColor = backgroundColor
    }

    private func setupShadow() {
        layer?.shadowColor = NSColor.textColor.cgColor
        layer?.shadowOpacity = 0.0
        layer?.shadowRadius = 3.0
        layer?.shadowOffset = CGSize(width: 0, height: 0)
    }
}

// MARK: Mouse Functions
extension AXVerticalTabButton {
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

    let hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    let selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    let defaultAlphaValue: CGFloat = 0.3

    var defaultColor: CGColor? = .none
    var mouseDown: Bool = false

    init(isSelected: Bool = false) {
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .smallSquare
        self.alphaValue = defaultAlphaValue
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

        self.alphaValue = 1
    }

    override func mouseDragged(with event: NSEvent) {
        mouseDown = false
    }

    override func mouseExited(with event: NSEvent) {
        self.layer?.backgroundColor = defaultColor
        self.alphaValue = defaultAlphaValue
    }
}
