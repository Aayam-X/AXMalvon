//
//  AXTabGroupInfoView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-10.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Cocoa

class AXTabGroupInfoView: NSView {
    private var hasDrawn: Bool = false
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
        let label = NSTextField(labelWithString: "Math")
        label.font = .titleBarFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.usesSingleLineMode = true
        label.drawsBackground = false
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var profileLabel: NSTextField = {
        let label = NSTextField(labelWithString: "School")
        label.font = .messageFont(ofSize: 11)
        label.textColor = NSColor.gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var labelsStackView: NSStackView = {
        let stackView = NSStackView(views: [tabGroupLabel, profileLabel])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 2
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

    @MainActor
    override func viewWillDraw() {
        guard !hasDrawn else { return }
        defer { hasDrawn = true }

        // Add content stack view
        addSubview(contentStackView)

        // Set up constraints for the content stack view
        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 5),
            contentStackView.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -5),
            contentStackView.topAnchor.constraint(
                equalTo: topAnchor, constant: 2),
            contentStackView.bottomAnchor.constraint(
                lessThanOrEqualTo: bottomAnchor, constant: 4),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
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
        onLeftMouseDown?()
    }
}
