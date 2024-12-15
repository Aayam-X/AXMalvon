//
//  AXSidebarSearchButton.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-01.
//

import AppKit

protocol AXSidebarSearchButtonDelegate: AnyObject {
    func lockClicked()
}

class AXSidebarSearchButton: NSButton {
    private var hasDrawn = false
    weak var delegate: AXSidebarSearchButtonDelegate?

    var fullAddress: URL? {
        didSet {
            addressField.stringValue = fullAddress?.absoluteString ?? "Empty"

            if fullAddress?.scheme?.last != "s" {
                lockView.image = NSImage(
                    named: NSImage.lockUnlockedTemplateName)
            } else {
                lockView.image = NSImage(named: NSImage.lockLockedTemplateName)
            }
        }
    }

    var url: URL? {
        didSet {
            addressField.stringValue = url?.host() ?? "Empty"

            if url?.scheme?.last != "s" {
                lockView.image = NSImage(
                    named: NSImage.lockUnlockedTemplateName)
            } else {
                lockView.image = NSImage(named: NSImage.lockLockedTemplateName)
            }
        }
    }

    lazy var addressField: NSTextField = {
        let field = NSTextField()

        field.placeholderString = "Search or Enter URL..."
        field.textColor = .secondaryLabelColor
        field.isBezeled = false
        field.isEditable = false
        field.alignment = .left
        field.drawsBackground = false
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingTail
        field.cell?.truncatesLastVisibleLine = true
        field.translatesAutoresizingMaskIntoConstraints = false

        return field
    }()

    private let lockView: NSButton = {
        let button = NSButton()
        button.isBordered = false
        button.image = NSImage(named: NSImage.lockLockedTemplateName)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewWillDraw() {
        guard !hasDrawn else { return }
        defer { hasDrawn = true }

        // Configure the button appearance
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        self.title = ""
        self.wantsLayer = true
        self.layer?.cornerRadius = 10
        self.layer?.backgroundColor =
            NSColor.systemGray.withAlphaComponent(0.4).cgColor

        heightAnchor.constraint(equalToConstant: 36).isActive = true

        // Restore auto resizing mask
        lockView.translatesAutoresizingMaskIntoConstraints = false
        addressField.translatesAutoresizingMaskIntoConstraints = false

        // Add the lock button
        addSubview(lockView)
        lockView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        lockView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        lockView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive =
            true
        lockView.leftAnchor.constraint(equalTo: leftAnchor, constant: 10)
            .isActive = true

        // Add the title view

        addSubview(addressField)
        addressField.leftAnchor.constraint(
            equalTo: lockView.rightAnchor, constant: 6
        ).isActive = true
        addressField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive =
            true

        // Configure lock button action
        lockView.target = self
        lockView.action = #selector(lockClicked)
    }

    @objc private func lockClicked() {
        delegate?.lockClicked()
    }

    func isServerTrustValid(_ serverTrust: SecTrust) -> Bool {
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        if isValid {
            mxPrint("Certificate is valid and trusted.")
        } else {
            mxPrint(
                "Certificate validation failed: \(error?.localizedDescription ?? "Unknown error")"
            )
        }

        return isValid
    }

}
