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

    override func viewWillDraw() {
        guard !hasDrawn else { return }
        defer { hasDrawn = true }

        self.layer?.backgroundColor = .black

        // Add subviews
        addSubview(imageView)
        addSubview(tabGroupLabel)
        addSubview(profileLabel)

        // Set up constraints
        NSLayoutConstraint.activate([
            // Image view constraints
            imageView.leftAnchor.constraint(equalTo: leftAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            imageView.widthAnchor.constraint(equalToConstant: 24),  // Set the width of the image view
            imageView.heightAnchor.constraint(equalToConstant: 24),  // Set the height of the image view

            // Tab group label constraints
            tabGroupLabel.topAnchor.constraint(equalTo: topAnchor),
            tabGroupLabel.leftAnchor.constraint(
                equalTo: imageView.rightAnchor, constant: 6),
            tabGroupLabel.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -5),

            // Profile label constraints
            profileLabel.topAnchor.constraint(
                equalTo: tabGroupLabel.bottomAnchor),
            profileLabel.leftAnchor.constraint(
                equalTo: imageView.rightAnchor, constant: 6),
            profileLabel.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }
}
