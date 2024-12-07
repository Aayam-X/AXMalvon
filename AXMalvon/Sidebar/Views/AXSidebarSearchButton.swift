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

    var url: URL? {
        didSet {
            titleView.stringValue = url?.host() ?? "Empty"

            if url?.scheme?.last != "s" {
                lockView.image = NSImage(
                    named: NSImage.lockUnlockedTemplateName)
            } else {
                lockView.image = NSImage(named: NSImage.lockLockedTemplateName)
            }
        }
    }

    private let titleView: NSTextField = {
        let textField = NSTextField()
        textField.stringValue = "Search"
        textField.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        textField.textColor = .secondaryLabelColor
        textField.isBezeled = false
        textField.isEditable = false
        textField.alignment = .left
        textField.drawsBackground = false
        textField.usesSingleLineMode = true
        textField.lineBreakMode = .byTruncatingTail
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
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

        // Add the lock button
        addSubview(lockView)
        NSLayoutConstraint.activate([
            lockView.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            lockView.centerYAnchor.constraint(equalTo: centerYAnchor),
            lockView.widthAnchor.constraint(equalToConstant: 16),
            lockView.heightAnchor.constraint(equalToConstant: 16),
        ])

        // Add the title view
        addSubview(titleView)
        NSLayoutConstraint.activate([
            titleView.leftAnchor.constraint(
                equalTo: lockView.rightAnchor, constant: 5),
            titleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleView.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -8),
        ])

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
