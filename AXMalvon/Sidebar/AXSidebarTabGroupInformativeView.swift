//
//  AXSidebarTabGroupInformativeView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-10.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Cocoa

class AXSidebarTabGroupInformativeView: NSView {
    private var hasDrawn: Bool = false

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

    lazy var tabGroupLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Math")
        label.font = .titleBarFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.usesSingleLineMode = true
        label.drawsBackground = false
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    lazy var profileLabel: NSTextField = {
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
}
