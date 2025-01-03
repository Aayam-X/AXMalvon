//
//  AXNewTabTopSiteCardCollectionViewItem.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-03.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class AXNewTabTopSiteCardCollectionViewItem: NSCollectionViewItem {
    internal let myImageView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private var url: String! = nil
    private var index: Int! = nil

    var mouseUpSelector: ((String) -> Void)?

    var onRightMouseDown: ((Int) -> Void)?

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 9
        view.layer?.backgroundColor = nil  // Removed background color

        myImageView.translatesAutoresizingMaskIntoConstraints = false
        myImageView.wantsLayer = true
        myImageView.layer?.shadowColor = NSColor.black.cgColor
        myImageView.layer?.shadowOpacity = 0.2
        myImageView.layer?.shadowOffset = CGSize(width: 0, height: -2)
        myImageView.layer?.shadowRadius = 4
        myImageView.layer?.cornerRadius = 9

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 14)
        titleLabel.alignment = .center

        view.addSubview(myImageView)
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            myImageView.topAnchor.constraint(
                equalTo: view.topAnchor, constant: 10),
            myImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            myImageView.widthAnchor.constraint(equalToConstant: 60),  // Larger image
            myImageView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.topAnchor.constraint(
                equalTo: myImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 5),
            titleLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -5),
        ])
    }

    func configure(title: String, url: String, index: Int) {
        titleLabel.stringValue = title
        self.url = url
        self.index = index

        let cacheKey = "placeholder_\(title)"  // Unique key for caching based on the title
        if let cachedImage = ImageCache.shared.getImage(forKey: cacheKey) {
            self.myImageView.image = cachedImage
        } else {
            let placeholderImage = createPlaceholderImage(for: title)
            ImageCache.shared.setImage(placeholderImage, forKey: cacheKey)
            self.myImageView.image = placeholderImage
        }
    }

    private func createPlaceholderImage(for title: String) -> NSImage {
        let size = CGSize(width: 60, height: 60)
        let firstLetter = String(title.prefix(1)).uppercased()
        let colors: [NSColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemYellow,
            .systemOrange, .systemPurple, .systemPink, .systemTeal,
            .systemPurple, .systemCyan, .systemIndigo,
        ]
        let backgroundColor = colors.randomElement() ?? .systemGray

        let image = NSImage(size: size)
        image.lockFocus()

        // Draw background
        backgroundColor.setFill()
        let rect = NSRect(origin: .zero, size: size)
        rect.fill()

        // Draw first letter
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 24),
            .foregroundColor: NSColor.white,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                style.lineBreakMode = .byClipping
                return style
            }(),
        ]

        let attributedString = NSAttributedString(
            string: firstLetter, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributedString.draw(in: textRect)

        image.unlockFocus()
        return image
    }

    override func mouseUp(with event: NSEvent) {
        self.mouseUpSelector?(self.url)
    }

    override func rightMouseDown(with event: NSEvent) {
        self.onRightMouseDown?(self.index!)
        super.rightMouseDown(with: event)
    }
}
