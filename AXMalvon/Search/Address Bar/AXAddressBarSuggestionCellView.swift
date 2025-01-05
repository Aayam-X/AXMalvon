//
//  AXAddressBarSuggestionCellView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class AXAddressBarSuggestionCellView: NSTableCellView {
    // MARK: - Properties
    let titleLabel: NSTextField
    let subtitleLabel: NSTextField
    let faviconImageView: NSImageView
    var trackingArea: NSTrackingArea!
    var onMouseEnter: (() -> Void)?

    // MARK: - Initialization
    override init(frame frameRect: NSRect) {
        titleLabel = NSTextField(labelWithString: "")
        subtitleLabel = NSTextField(labelWithString: "")
        faviconImageView = NSImageView(
            image: NSImage(named: NSImage.iconViewTemplateName)!)

        super.init(frame: frameRect)

        setupView()
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .secondaryLabelColor

        [titleLabel, subtitleLabel, faviconImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        // Favicon Image View
        faviconImageView.activateConstraints([
            .centerY: .view(self),
            .left: .view(self, constant: 8),
            .width: .constant(16),
            .height: .constant(16),
        ])

        // Title Label
        titleLabel.activateConstraints([
            .centerY: .view(self),
            .leftRight: .view(faviconImageView, constant: 8),
        ])

        // Subtitle Label
        subtitleLabel.activateConstraints([
            .centerY: .view(self),
            .leftRight: .view(titleLabel, constant: 3),
        ])
    }

    private func setupTrackingArea() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    // MARK: - Configuration
    func configure(title: String, subtitle: String? = nil) {
        titleLabel.stringValue = title
        subtitleLabel.stringValue = subtitle ?? ""
        subtitleLabel.isHidden = subtitle == nil
    }

    // MARK: - Mouse Handling
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        onMouseEnter?()
    }

    deinit {
        removeTrackingArea(trackingArea)
    }
}
