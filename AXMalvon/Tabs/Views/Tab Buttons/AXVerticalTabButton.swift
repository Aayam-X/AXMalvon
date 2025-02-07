//
//  AXTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class AXVerticalTabButton: NSButton, AXTabButton {
    weak var delegate: AXTabButtonDelegate?

    // Subviews
    var favIconImageView: NSImageView! = NSImageView()
    var titleView: NSTextField! = NSTextField()
    var closeButton = AXSidebarTabCloseButton()

    var trackingArea: NSTrackingArea!

    var webTitle: String = "Untitled" {
        didSet {
            titleView.stringValue = webTitle
        }
    }

    var isSelected: Bool = false {
        didSet {
            self.updateAppearance()
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

    required init() {
        super.init(frame: .zero)
        self.isBordered = false
        self.bezelStyle = .smallSquare
        title = ""

        self.wantsLayer = true
        self.layer?.cornerRadius = 10
        layer?.masksToBounds = false
        setupViews()
        setupShadow()
        updateTrackingAreas()
    }

    required convenience init?(coder: NSCoder) {
        self.init()
    }

    func setupViews() {
        self.heightAnchor.constraint(equalToConstant: 33).isActive = true

        // Setup imageView
        favIconImageView.translatesAutoresizingMaskIntoConstraints = false
        favIconImageView.image = AXTabButtonConstants.defaultFaviconSleep
        favIconImageView.contentTintColor = .textBackgroundColor
            .withAlphaComponent(0.2)
        addSubview(favIconImageView)

        favIconImageView.activateConstraints([
            .centerY: .view(self),
            .left: .view(self, constant: 10),
            .width: .constant(16),
            .height: .constant(16),
        ])

        // Setup closeButton
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.target = self
        closeButton.action = #selector(closeTab)
        addSubview(closeButton)
        closeButton.image = NSImage(
            systemSymbolName: "xmark", accessibilityDescription: nil)

        closeButton.activateConstraints([
            .right: .view(self, constant: -7),
            .centerY: .view(self),
            .width: .constant(16),
            .height: .constant(16),
        ])
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
        titleView.activateConstraints([
            .leftRight: .view(favIconImageView, constant: 5),
            .centerY: .view(self),
            .rightLeft: .view(closeButton),
        ])

        titleView.setContentCompressionResistancePriority(
            .defaultLow, for: .horizontal)
        titleView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }
    
    private func updateAppearance() {
        let newBackgroundColor: CGColor
        if isSelected {
            if effectiveAppearance.name == .vibrantDark
                || effectiveAppearance.name == .darkAqua
            {
                newBackgroundColor = .black
                layer?.shadowColor = .white
            } else {
                newBackgroundColor = .white
                layer?.shadowColor = .black
            }
            layer?.shadowOpacity = 0.3
            closeButton.isHidden = false
        } else {
            newBackgroundColor = .clear
            layer?.shadowOpacity = 0.0
            closeButton.isHidden = true
        }

        if self.layer?.backgroundColor != newBackgroundColor {
            self.layer?.backgroundColor = newBackgroundColor
        }
    }

    private func setupShadow() {
        layer?.shadowColor = NSColor.textColor.cgColor
        layer?.shadowOpacity = 0.0
        layer?.shadowRadius = 3.0
        layer?.shadowOffset = CGSize(width: 0, height: 0)
    }
}

// MARK: Tab Functions
extension AXVerticalTabButton {
    @objc func closeTab() {
        delegate?.tabButtonDidRequestClose(self)
    }
    
    // This would be called directly from a button click
    @objc func switchTab() {
        delegate?.tabButtonDidSelect(self)
    }
}

// MARK: Mouse Functions
extension AXVerticalTabButton {
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea)
        }

        trackingArea = NSTrackingArea(rect: self.bounds, options: [.activeInKeyWindow, .mouseEnteredAndExited, .inVisibleRect], owner: self, userInfo: nil)
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
            NSAnimationContext.runAnimationGroup { _ in
                self.animator().layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.3).cgColor
            }
        }
        // Delay close button appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.closeButton.isHidden = false
        }
    }

    override func mouseExited(with event: NSEvent) {
        if !isSelected {
            NSAnimationContext.runAnimationGroup { _ in
                self.animator().layer?.backgroundColor = NSColor.clear.cgColor
            }
        }
        // Delay close button hiding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if !self.isSelected {
                self.closeButton.isHidden = true
            }
        }
    }
}
