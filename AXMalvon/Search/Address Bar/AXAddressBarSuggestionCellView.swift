//
//  AXAddressBarSuggestionCellView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class AXAddressBarSuggestionCellView: NSButton {
    // Subviews
    var favIconImageView: NSImageView! = NSImageView()
    var titleView: NSTextField! = NSTextField()

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
        self.heightAnchor.constraint(equalToConstant: 16).isActive = true

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
        } else {
            newBackgroundColor = .clear
            layer?.shadowOpacity = 0.0
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

// MARK: Mouse Functions
extension AXAddressBarSuggestionCellView {
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea)
        }

        trackingArea = NSTrackingArea(rect: self.bounds, options: [.activeInKeyWindow, .mouseEnteredAndExited, .inVisibleRect], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseDown(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().layer?.setAffineTransform(
                CGAffineTransform(scaleX: 1, y: 0.95))
        }

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
    }

    override func mouseExited(with event: NSEvent) {
        if !isSelected {
            NSAnimationContext.runAnimationGroup { _ in
                self.animator().layer?.backgroundColor = NSColor.clear.cgColor
            }
        }
    }
}
