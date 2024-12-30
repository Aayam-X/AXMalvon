//
//  AXHorizontalTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//

import AppKit

private struct AXHorizontalTabButtonConstants {
    static let defaultFavicon = NSImage(
        systemSymbolName: "square.fill", accessibilityDescription: nil)
    static let defaultFaviconSleep = NSImage(
        systemSymbolName: "moon.fill", accessibilityDescription: nil)
    static let defaultCloseButton = NSImage(
        systemSymbolName: "xmark", accessibilityDescription: nil)

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

class AXHorizontalTabButton: NSButton, AXTabButton {
    var tab: AXTab!
    var delegate: (any AXTabButtonDelegate)?

    private var closeButton = AXHorizontalTabCloseButton()
    var titleView = NSTextField()

    var trackingArea: NSTrackingArea!

    var webTitle: String = "Untitled" {
        didSet {
            titleView.stringValue = webTitle
        }
    }

    var favicon: NSImage? {
        didSet {
            closeButton.favicon = favicon
        }
    }

    var isSelected: Bool = false {
        didSet {
            self.layer?.backgroundColor =
                isSelected
                ? AXHorizontalTabButtonConstants.selectedColor.cgColor
                : AXHorizontalTabButtonConstants.backgroundColor.cgColor
            layer?.shadowOpacity = isSelected ? 0.3 : 0.0

            if isSelected, tab.titleObserver == nil {
                forceCreateWebview()
            }
        }
    }

    required init(tab: AXTab!) {
        self.tab = tab
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        title = ""

        self.wantsLayer = true
        self.layer?.cornerRadius = 7
        layer?.masksToBounds = false

        layer?.shadowColor = NSColor.textColor.cgColor
        layer?.shadowOpacity = 0.0  // Adjust shadow visibility
        layer?.shadowRadius = 4.0  // Adjust softness
        layer?.shadowOffset = CGSize(width: 0, height: 0)  // Shadow below the button

        setTrackingArea()
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        if isSelected {
            self.layer?.backgroundColor =
                AXHorizontalTabButtonConstants.selectedColor.cgColor
            self.layer?.shadowOpacity = 0.3
        }

        self.heightAnchor.constraint(equalToConstant: 33).isActive = true

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.favicon =
            tab?.icon != nil
            ? tab.icon : AXHorizontalTabButtonConstants.defaultFaviconSleep
        addSubview(closeButton)
        closeButton.centerYAnchor.constraint(equalTo: centerYAnchor)
            .isActive = true
        closeButton.leftAnchor.constraint(
            equalTo: leftAnchor, constant: 10
        )
        .isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 20).isActive = true

        closeButton.target = self
        closeButton.action = #selector(closeTab)

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
            equalTo: closeButton.rightAnchor, constant: 5
        ).isActive = true
        titleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive =
            true

        titleView.rightAnchor.constraint(equalTo: rightAnchor, constant: -7)
            .isActive = true
    }

    @objc
    func closeTab() {
        tab?.stopTitleObservation()
        delegate?.tabButtonWillClose(self)
    }

    // This would be called directly from a button click
    @objc
    func switchTab() {
        delegate?.tabButtonDidSelect(self)
    }

    func setTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea.init(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseDown(with event: NSEvent) {
        closeButton.hideCloseButton()

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

        self.layer?.backgroundColor =
            AXHorizontalTabButtonConstants.selectedColor.cgColor
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
                AXHorizontalTabButtonConstants.hoverColor.cgColor
        }

        closeButton.showCloseButton()
    }

    override func mouseExited(with event: NSEvent) {
        self.layer?.backgroundColor =
            isSelected
            ? AXHorizontalTabButtonConstants.selectedColor.cgColor
            : AXHorizontalTabButtonConstants.backgroundColor.cgColor

        closeButton.hideCloseButton()
    }
}

// MARK: - Close Button + Favicon
class AXHorizontalTabCloseButton: NSButton {
    // swiftlint:disable:next identifier_name
    var _favicon: NSImage?

    var favicon: NSImage? {
        get {
            return _favicon
        } set {
            self._favicon = newValue
            self.image =
                newValue ?? AXHorizontalTabButtonConstants.defaultFavicon
        }
    }

    init(isSelected: Bool = false) {
        super.init(frame: .zero)
        self.isBordered = false
        self.bezelStyle = .smallSquare

        self.imagePosition = .imageOnly
        self.image = AXHorizontalTabButtonConstants.defaultFavicon
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showCloseButton() {
        self.image = AXHorizontalTabButtonConstants.defaultCloseButton
    }

    func hideCloseButton() {
        self.image = _favicon
    }
}
