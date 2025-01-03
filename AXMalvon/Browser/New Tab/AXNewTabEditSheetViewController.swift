//
//  AXNewTabEditSheetViewController.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-03.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class AXSiteEditSheet: NSViewController {
    private let titleField = NSTextField()
    private let urlField = NSTextField()
    private let isNewSite: Bool
    private let completion: (String, String) -> Void
    private let index: Int?

    init(
        title: String = "", url: String = "", isNewSite: Bool = true,
        index: Int? = nil, completion: @escaping (String, String) -> Void
    ) {
        self.isNewSite = isNewSite
        self.completion = completion
        self.index = index
        super.init(nibName: nil, bundle: nil)
        titleField.stringValue = title
        urlField.stringValue = url

        loadView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))

        let titleLabel = NSTextField(labelWithString: "Title:")
        let urlLabel = NSTextField(labelWithString: "URL:")

        titleField.placeholderString = "Enter site title"
        urlField.placeholderString = "Enter site URL"

        let saveButton = NSButton(
            title: isNewSite ? "Add" : "Save", target: self,
            action: #selector(save))
        let cancelButton = NSButton(
            title: "Cancel", target: self, action: #selector(cancel))

        [titleLabel, titleField, urlLabel, urlField, saveButton, cancelButton]
            .forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview($0)
            }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: view.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor, constant: 20),

            titleField.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            titleField.leadingAnchor.constraint(
                equalTo: titleLabel.trailingAnchor, constant: 10),
            titleField.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),

            urlLabel.topAnchor.constraint(
                equalTo: titleField.bottomAnchor, constant: 20),
            urlLabel.leadingAnchor.constraint(
                equalTo: titleLabel.leadingAnchor),

            urlField.topAnchor.constraint(equalTo: urlLabel.topAnchor),
            urlField.leadingAnchor.constraint(
                equalTo: urlLabel.trailingAnchor, constant: 10),
            urlField.trailingAnchor.constraint(
                equalTo: titleField.trailingAnchor),

            saveButton.topAnchor.constraint(
                equalTo: urlField.bottomAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor, constant: -20),

            cancelButton.centerYAnchor.constraint(
                equalTo: saveButton.centerYAnchor),
            cancelButton.trailingAnchor.constraint(
                equalTo: saveButton.leadingAnchor, constant: -10),
        ])
    }

    @objc
    private func save() {
        guard let url = URL(string: urlField.stringValue) else {
            let alert = NSAlert()
            alert.messageText = "Invalid URL"
            alert.runModal()
            return
        }

        let fixedValue = url.fixURL().absoluteString

        completion(titleField.stringValue, fixedValue)
        if let window = view.window {
            window.sheetParent?.endSheet(window)
        }
    }

    @objc
    private func cancel() {
        if let window = view.window {
            window.sheetParent?.endSheet(window)
        }
    }
}
