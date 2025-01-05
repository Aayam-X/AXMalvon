//
//  AXSidebarSearchButton.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-01.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

protocol AXSidebarSearchButtonDelegate: AnyObject {
    func lockClicked()
    func sidebarSearchButtonRequestsHistoryManager() -> AXHistoryManager?
    func sidebarSearchButtonSearchesFor(_ url: URL)
}

class AXToolbarSearchButton: AXSidebarSearchButton {
    override var intrinsicContentSize: NSSize {
        .init(width: 300, height: 36)
    }
}

class AXSidebarSearchButton: NSButton {
    weak var delegate: AXSidebarSearchButtonDelegate?

    var historyManagerExists: Bool = true

    weak var historyManager: AXHistoryManager? {
        delegate?.sidebarSearchButtonRequestsHistoryManager()
    }

    var previousStringValueCount = 0

    lazy var suggestionsWindowController: AXAddressBarWindow! = {
        let windowController = AXAddressBarWindow()
        windowController.suggestionItemClickAction = { [weak self] suggestion in
            self?.addressField.stringValue = suggestion
            self?.searchEnterAction()
        }
        return windowController
    }()

    lazy var suggestionsManager: SuggestionsManager = {
        let manager = SuggestionsManager(
            historyManager: historyManager!)
        manager.onQueryUpdated = onQueryUpdated
        manager.onTopSearchesUpdated = onTopSearchesUpdated
        manager.onHistoryUpdated = onHistoryUpdated
        manager.onGoogleSuggestionsUpdated = onGoogleSuggestionsUpdated

        return manager
    }()

    var fullAddress: URL? {
        didSet {
            updateAddressFieldAttributedString()

            if fullAddress?.scheme?.last != "s" {
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
        field.alignment = .left
        field.drawsBackground = false
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingTail
        field.cell?.truncatesLastVisibleLine = true
        field.translatesAutoresizingMaskIntoConstraints = true
        field.wantsLayer = true
        field.delegate = self
        field.controlSize = .large
        field.focusRingType = .none

        return field
    }()

    private let lockView: NSButton = {
        let button = NSButton()
        button.isBordered = false
        button.image = NSImage(named: NSImage.lockLockedTemplateName)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    func setupViews() {
        // Configure the button appearance
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        self.title = ""
        self.wantsLayer = true
        self.layer?.cornerRadius = 10
        self.layer?.backgroundColor =
            NSColor.systemGray.withAlphaComponent(0.4).cgColor

        self.heightAnchor.constraint(equalToConstant: 33).isActive = true

        // Restore auto resizing mask
        lockView.translatesAutoresizingMaskIntoConstraints = false
        addressField.translatesAutoresizingMaskIntoConstraints = false

        // Add the lock button
        addSubview(lockView)
        lockView.activateConstraints([
            .left: .view(self, constant: 5),
            .centerY: .view(self),
            .width: .constant(16),
            .height: .constant(16),
        ])

        // Add the title view
        addSubview(addressField)
        addressField.activateConstraints([
            .leftRight: .view(lockView, constant: 4),
            .right: .view(self),
            .centerY: .view(self),
        ])
        //addressField.alphaValue = 0.6

        // Configure lock button action
        lockView.target = self
        lockView.action = #selector(lockClicked)
    }

    private func updateAddressFieldAttributedString() {
        guard let url = fullAddress else {
            addressField.attributedStringValue = NSAttributedString(string: "")
            return
        }

        let components = url.host?.split(separator: ".") ?? []
        let domainName = components.suffix(2).joined(separator: ".")
        let path = url.path + (url.query.map { "?\($0)" } ?? "")

        let attributedString = NSMutableAttributedString(
            string: domainName,
            attributes: [
                .foregroundColor: NSColor.labelColor.withAlphaComponent(0.8)
            ])

        if !path.isEmpty {
            let pathAttributedString = NSAttributedString(
                string: path,
                attributes: [
                    .foregroundColor: NSColor.labelColor.withAlphaComponent(0.3)
                ])
            attributedString.append(pathAttributedString)
        }

        addressField.attributedStringValue = attributedString
    }

    @objc
    private func lockClicked() {
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

// MARK: - Search Suggestions
extension AXSidebarSearchButton: NSTextFieldDelegate {
    // Split callback functions for each type of update
    func onQueryUpdated(_ query: String) {
        suggestionsWindowController.currentQuery = query
    }
    func onTopSearchesUpdated(_ searches: [String]) {
        suggestionsWindowController.topSiteItems = searches
    }
    func onHistoryUpdated(_ history: [(title: String, url: String)]) {
        suggestionsWindowController.historyItems = history
    }
    func onGoogleSuggestionsUpdated(_ suggestions: [String]) {
        suggestionsWindowController.googleSearchItems = suggestions
    }

    func controlTextDidBeginEditing(_ obj: Notification) {
        historyManagerExists = historyManager != nil
    }

    func controlTextDidChange(_ obj: Notification) {
        let query = addressField.stringValue

        if historyManagerExists {
            suggestionsManager.updateSuggestions(with: query)
            suggestionsWindowController.showSuggestions(for: self.addressField)
        }
    }

    func control(
        _ control: NSControl, textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        if commandSelector == #selector(moveUp(_:)) {
            suggestionsWindowController.moveUp()
            if let currentSuggestion = suggestionsWindowController
                .currentSuggestion
            {
                addressField.stringValue = currentSuggestion
                addressField.currentEditor()?.selectedRange = NSRange(
                    location: previousStringValueCount,
                    length: currentSuggestion.count)
            }
            return true
        }
        if commandSelector == #selector(moveDown(_:)) {
            suggestionsWindowController.moveDown()
            if let currentSuggestion = suggestionsWindowController
                .currentSuggestion
            {
                addressField.stringValue = currentSuggestion
                addressField.currentEditor()?.selectedRange = NSRange(
                    location: previousStringValueCount,
                    length: currentSuggestion.count)
            }
            return true
        }

        if commandSelector == #selector(insertNewline(_:)) {
            if let suggestion = suggestionsWindowController.currentSuggestion {
                addressField.stringValue = suggestion
            }
            suggestionsWindowController.orderOut()
            searchEnterAction()

            return true
        }

        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            suggestionsWindowController.orderOut()
            return true
        }

        return false
    }

    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText)
        -> Bool
    {
        suggestionsWindowController.orderOut()
        addressField.stringValue = fullAddress?.absoluteString ?? ""

        return true
    }

    private func searchEnterAction() {
        let url = AXSearchQueryToURL.shared.convert(
            query: addressField.stringValue)
        delegate?.sidebarSearchButtonSearchesFor(url)
    }
}

private func fetchGoogleSuggestions(
    for query: String, completion: @escaping ([String]) -> Void
) {
    let encodedQuery =
        query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        ?? ""
    let urlString =
        "https://suggestqueries.google.com/complete/search?client=firefox&q=\(encodedQuery)"

    guard let url = URL(string: urlString) else {
        completion([])  // Return an empty list if the URL is invalid
        return
    }

    // URLSession runs network requests on a background thread
    let task = URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            print("Error fetching suggestions: \(error)")
            completion([])  // Return an empty list on error
            return
        }

        guard let data = data else {
            completion([])  // Return an empty list if there's no data
            return
        }

        do {
            // Decode the JSON response
            if let json = try JSONSerialization.jsonObject(
                with: data, options: []) as? [Any],
                let suggestions = json[1] as? [String]
            {
                // Return suggestions on the main thread
                DispatchQueue.main.async {
                    var completionValue = suggestions
                    completionValue.insert(query, at: 0)

                    completion(completionValue)
                }
            } else {
                DispatchQueue.main.async {
                    completion([])  // Handle unexpected JSON format
                }
            }
        } catch {
            print("Error decoding JSON: \(error)")
            DispatchQueue.main.async {
                completion([])
            }
        }
    }

    task.resume()  // Start the network request
}
