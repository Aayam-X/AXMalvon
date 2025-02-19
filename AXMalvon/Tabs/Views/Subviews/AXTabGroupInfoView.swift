//
//  AXTabGroupInfoView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-10.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class AXTabGroupInfoView: NSView {
    var onRightMouseDown: (() -> Void)?
    var onLeftMouseDown: (() -> Void)?

    // Create the image view
    lazy var imageView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = NSImage(
            systemSymbolName: "square.3.layers.3d",
            accessibilityDescription: nil)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
    }()

    private lazy var tabGroupLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Untitled Group")
        label.font = .titleBarFont(ofSize: 14)
        label.usesSingleLineMode = true
        label.drawsBackground = false
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var profileLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Default")
        label.font = .messageFont(ofSize: 10)
        label.textColor = NSColor.gray
        return label
    }()

    lazy var labelsStackView: NSStackView = {
        let stackView = NSStackView(views: [tabGroupLabel, profileLabel])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 1
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var contentStackView: NSStackView = {
        let stackView = NSStackView(views: [imageView, labelsStackView])
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        // Add content stack view
        addSubview(contentStackView)

        self.activateConstraints([
            .height: .constant(33)
        ])

        contentStackView.activateConstraints([
            .top: .view(self),
            .left: .view(self, constant: 5),
            .right: .view(self, constant: -5),
        ])

        contentStackView.bottomAnchor.constraint(
            lessThanOrEqualTo: bottomAnchor
        ).isActive = true

        imageView.activateConstraints([
            .width: .constant(24),
            .height: .constant(24),
        ])
    }

    @MainActor
    func updateLabels(tabGroup: AXTabGroup, profileName: String) {
        self.tabGroupLabel.stringValue = tabGroup.name
        self.profileLabel.stringValue = profileName

        updateIcon(tabGroup.icon)
    }

    @MainActor
    func updateLabels(tabGroup: AXTabGroup) {
        self.tabGroupLabel.stringValue = tabGroup.name

        updateIcon(tabGroup.icon)
    }

    @MainActor
    func updateIcon(tabGroup: AXTabGroup) {
        updateIcon(tabGroup.icon)
    }

    @MainActor
    func updateIcon(_ named: String) {
        self.imageView.image = NSImage(
            systemSymbolName: named, accessibilityDescription: nil)
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightMouseDown?()
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onRightMouseDown?()
        } else {
            onLeftMouseDown?()
        }
    }
}
