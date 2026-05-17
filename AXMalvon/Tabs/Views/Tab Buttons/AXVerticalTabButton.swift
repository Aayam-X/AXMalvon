//
//  AXVerticalTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//
//  A sidebar tab cell. Layout: 16×16 rounded favicon (with a skeleton
//  placeholder until the image arrives) + truncating title + hover-only
//  close button. Selection is rendered with an ``NSGlassEffectView``
//  backdrop. Hover state can be cleared imperatively by the enclosing
//  tab bar (used to fix the hover-stuck-during-scroll bug).
//

import AppKit

@MainActor
final class AXVerticalTabButton: NSButton, AXTabButton {
    weak var delegate: AXTabButtonDelegate?

    // MARK: - Geometry
    private static let height: CGFloat = 32
    private static let cornerRadius: CGFloat = 8
    private static let faviconSize: CGFloat = 16
    private static let faviconCornerRadius: CGFloat = 3

    // MARK: - Subviews

    /// Sits behind the content; opacity animates from 0 → 1 on selection.
    private let selectionPane: NSGlassEffectView = {
        let v = NSGlassEffectView()
        v.style = .regular
        v.cornerRadius = AXVerticalTabButton.cornerRadius
        v.translatesAutoresizingMaskIntoConstraints = false
        v.alphaValue = 0
        return v
    }()

    /// Rounded backdrop that doubles as the skeleton placeholder while the
    /// favicon is loading. Has a faint fill that's visible whenever the
    /// favicon image hasn't been set.
    private let faviconBackdrop: NSView = {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.cornerRadius = AXVerticalTabButton.faviconCornerRadius
        v.layer?.masksToBounds = true
        v.layer?.backgroundColor = NSColor.tertiaryLabelColor
            .withAlphaComponent(0.35).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let faviconImageView: NSImageView = {
        let v = NSImageView()
        v.imageScaling = .scaleProportionallyUpOrDown
        v.translatesAutoresizingMaskIntoConstraints = false
        v.alphaValue = 0
        v.wantsLayer = true
        return v
    }()

    private let titleLabel: NSTextField = {
        let f = NSTextField(labelWithString: "")
        f.isEditable = false
        f.isBordered = false
        f.drawsBackground = false
        f.usesSingleLineMode = true
        f.lineBreakMode = .byTruncatingTail
        f.alignment = .left
        f.font = .systemFont(ofSize: 13, weight: .medium)
        f.textColor = .labelColor
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()

    private let closeButton: AXSidebarTabCloseButton = {
        let b = AXSidebarTabCloseButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)
        b.alphaValue = 0
        return b
    }()

    // MARK: - State

    private var trackingArea: NSTrackingArea?

    private var isHovering: Bool = false {
        didSet {
            guard oldValue != isHovering else { return }
            applyAppearance(animated: true)
        }
    }

    var isSelected: Bool = false {
        didSet {
            guard oldValue != isSelected else { return }
            applyAppearance(animated: true)
        }
    }

    var webTitle: String = "Untitled" {
        didSet { titleLabel.stringValue = webTitle }
    }

    var favicon: NSImage? {
        didSet {
            applyFavicon(animated: oldValue != favicon)
        }
    }

    /// Tab-group color applied as a subtle tint behind the selection glass.
    /// Set when the button is created (or when the active tab group
    /// changes); the glass effect handles its own appearance otherwise.
    var accentColor: NSColor? {
        didSet {
            selectionPane.tintColor = accentColor?.withAlphaComponent(0.35)
        }
    }

    // MARK: - Init

    required init() {
        super.init(frame: .zero)
        wantsLayer = true
        isBordered = false
        bezelStyle = .smallSquare
        title = ""
        focusRingType = .none
        layer?.cornerRadius = Self.cornerRadius
        closeButton.target = self
        closeButton.action = #selector(handleCloseClick)
        setupSubviews()
    }

    required convenience init?(coder: NSCoder) {
        self.init()
    }

    // MARK: - Layout

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: Self.height).isActive = true

        // Selection pane goes in first → backmost.
        addSubview(selectionPane)
        addSubview(faviconBackdrop)
        faviconBackdrop.addSubview(faviconImageView)
        addSubview(titleLabel)
        addSubview(closeButton)

        NSLayoutConstraint.activate([
            // Selection pane fills the cell.
            selectionPane.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionPane.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionPane.topAnchor.constraint(equalTo: topAnchor),
            selectionPane.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Favicon backdrop on the left.
            faviconBackdrop.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 10),
            faviconBackdrop.centerYAnchor.constraint(equalTo: centerYAnchor),
            faviconBackdrop.widthAnchor.constraint(
                equalToConstant: Self.faviconSize),
            faviconBackdrop.heightAnchor.constraint(
                equalToConstant: Self.faviconSize),

            // Favicon image fills its backdrop.
            faviconImageView.leadingAnchor.constraint(
                equalTo: faviconBackdrop.leadingAnchor),
            faviconImageView.trailingAnchor.constraint(
                equalTo: faviconBackdrop.trailingAnchor),
            faviconImageView.topAnchor.constraint(
                equalTo: faviconBackdrop.topAnchor),
            faviconImageView.bottomAnchor.constraint(
                equalTo: faviconBackdrop.bottomAnchor),

            // Close button on the right.
            closeButton.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -7),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: Self.faviconSize),
            closeButton.heightAnchor.constraint(equalToConstant: Self.faviconSize),

            // Title between favicon and close button.
            titleLabel.leadingAnchor.constraint(
                equalTo: faviconBackdrop.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(
                equalTo: closeButton.leadingAnchor, constant: -6),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        titleLabel.setContentCompressionResistancePriority(
            .defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    // MARK: - Tracking

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovering = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovering = false
    }

    override func mouseDown(with event: NSEvent) {
        delegate?.tabButtonDidSelect(self)
        isSelected = true
    }

    /// Forcibly clears hover state. Called by the enclosing tab bar on
    /// scroll, where AppKit doesn't reliably fire `mouseExited` even
    /// though the tracking area uses `.inVisibleRect`.
    func clearHoverState() {
        guard isHovering else { return }
        isHovering = false
    }

    // MARK: - Appearance

    private func applyAppearance(animated: Bool) {
        let duration: TimeInterval = animated ? 0.15 : 0.0
        let showClose = isHovering || isSelected

        let nonSelectedHoverColor = NSColor.gray
            .withAlphaComponent(0.15).cgColor
        let backgroundColor: CGColor =
            (!isSelected && isHovering)
            ? nonSelectedHoverColor
            : NSColor.clear.cgColor

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            ctx.allowsImplicitAnimation = true
            selectionPane.animator().alphaValue = isSelected ? 1 : 0
            closeButton.animator().alphaValue = showClose ? 1 : 0
            layer?.backgroundColor = backgroundColor
        }
    }

    private func applyFavicon(animated: Bool) {
        let duration: TimeInterval = animated ? 0.18 : 0.0
        let hasFavicon = favicon != nil

        if hasFavicon {
            faviconImageView.image = favicon
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = duration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            faviconImageView.animator().alphaValue = hasFavicon ? 1 : 0
        }

        // Skeleton fill is the backdrop layer's background colour; hide it
        // when the favicon is opaque so transparent favicons don't show a
        // grey halo.
        faviconBackdrop.layer?.backgroundColor =
            hasFavicon
            ? NSColor.clear.cgColor
            : NSColor.tertiaryLabelColor.withAlphaComponent(0.35).cgColor
    }

    // MARK: - Actions

    @objc private func handleCloseClick() {
        delegate?.tabButtonDidRequestClose(self)
    }
}
