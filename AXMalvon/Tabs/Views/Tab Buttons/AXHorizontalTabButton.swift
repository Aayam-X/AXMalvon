//
//  AXHorizontalTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
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
            self.updateAppearance()

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
        self.bezelStyle = .smallSquare
        title = ""

        self.wantsLayer = true
        self.layer?.cornerRadius = 7
        self.layer?.masksToBounds = false
        setupShadow()
        setupViews()
        setupTrackingArea()
    }

    override func viewWillDraw() {
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.heightAnchor.constraint(equalToConstant: 33).isActive = true

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.favicon = tab?.icon ?? NSImage(systemSymbolName: "moon.fill", accessibilityDescription: nil)
        addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        closeButton.target = self
        closeButton.action = #selector(closeTab)

        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.isEditable = false
        titleView.isBordered = false
        titleView.usesSingleLineMode = true
        titleView.drawsBackground = false
        titleView.lineBreakMode = .byTruncatingTail
        titleView.textColor = .textColor
        addSubview(titleView)
        NSLayoutConstraint.activate([
            titleView.leftAnchor.constraint(equalTo: closeButton.rightAnchor, constant: 5),
            titleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleView.rightAnchor.constraint(equalTo: rightAnchor, constant: -7)
        ])
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

    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseDown(with event: NSEvent) {
        closeButton.hideCloseButton()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().layer?.setAffineTransform(CGAffineTransform(scaleX: 1, y: 0.95))
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
            self.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.3).cgColor
        }
        closeButton.showCloseButton()
    }

    override func mouseExited(with event: NSEvent) {
        closeButton.hideCloseButton()
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
        } else {
            backgroundColor = .clear
            layer?.shadowOpacity = 0.0
        }

        self.layer?.backgroundColor = backgroundColor
    }

    private func setupShadow() {
        layer?.shadowColor = NSColor.textColor.cgColor
        layer?.shadowOpacity = 0.0
        layer?.shadowRadius = 4.0
        layer?.shadowOffset = CGSize(width: 0, height: 0)
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
