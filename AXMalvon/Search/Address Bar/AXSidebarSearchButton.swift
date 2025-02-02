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
            // Only proceed if the value has actually changed
            guard fullAddress != oldValue else { return }

            updateAddressFieldAttributedString()

            // Update the lock view image based on the scheme
            if let scheme = fullAddress?.scheme {
                let isSecure = scheme.hasSuffix("s")
                lockView.image = NSImage(
                    named: isSecure
                        ? NSImage.lockLockedTemplateName
                        : NSImage.lockUnlockedTemplateName)
            } else {
                lockView.image = NSImage(
                    named: NSImage.lockUnlockedTemplateName)
            }
        }
    }

    lazy var addressField: ZSearchField = {
        let field = ZSearchField()

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
        addressField.stringValue = "HELLO WORLD"
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

        // Use the full host name instead of trimming to the last two components
        let domainName = url.host ?? ""
        let path = url.path + (url.query.map { "?\($0)" } ?? "")

        // Create attributed string only if necessary
        if !domainName.isEmpty || !path.isEmpty {
            let attributedString = NSMutableAttributedString(
                string: domainName,
                attributes: [
                    .foregroundColor: NSColor.labelColor.withAlphaComponent(0.8)
                ])

            if !path.isEmpty {
                let pathAttributedString = NSAttributedString(
                    string: path,
                    attributes: [
                        .foregroundColor: NSColor.labelColor.withAlphaComponent(
                            0.3)
                    ])
                attributedString.append(pathAttributedString)
            }

            addressField.attributedStringValue = attributedString
        } else {
            addressField.attributedStringValue = NSAttributedString(string: "")
        }
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
extension AXSidebarSearchButton: ZSearchFieldDelegate, NSTextFieldDelegate {
    func searchFieldDidBecomeFirstResponder(textField: ZSearchField) {
        textField.stringValue = fullAddress?.absoluteString ?? ""
    }

    func searchFieldDidResignFirstResponder(textField: ZSearchField) {
        updateAddressFieldAttributedString()
    }

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

protocol ZSearchFieldDelegate: NSTextFieldDelegate {
    func searchFieldDidBecomeFirstResponder(textField: ZSearchField)
    func searchFieldDidResignFirstResponder(textField: ZSearchField)
}

// https://stackoverflow.com/questions/25692122/how-to-detect-when-nstextfield-has-the-focus-or-is-its-content-selected-cocoa
class ZSearchField: NSTextField, NSTextDelegate {
    var expectingCurrentEditor: Bool = false

    // When you clicked on serach field, it will get becomeFirstResponder(),
    // and preparing NSText and focus will be taken by the NSText.
    // Problem is that self.currentEditor() hasn't been ready yet here.
    // So we have to wait resignFirstResponder() to get call and make sure
    // self.currentEditor() is ready.
    override func becomeFirstResponder() -> Bool {
        let status = super.becomeFirstResponder()
        if let delegate = self.delegate as? ZSearchFieldDelegate, status == true
        {
            expectingCurrentEditor = true
            delegate.searchFieldDidBecomeFirstResponder(textField: self)
        }
        return status
    }

    // It is pretty strange to detect search field get focused in resignFirstResponder()
    // method.  But otherwise, it is hard to tell if self.currentEditor() is available.
    // Once self.currentEditor() is there, that means the focus is moved from
    // serach feild to NSText. So, tell it's delegate that the search field got focused.

    override func resignFirstResponder() -> Bool {
        let status = super.resignFirstResponder()
        if let delegate = self.delegate as? ZSearchFieldDelegate, status == true
        {
            if self.currentEditor() != nil, expectingCurrentEditor {
                delegate.searchFieldDidBecomeFirstResponder(textField: self)
                // currentEditor.delegate = self
            }
        }
        self.expectingCurrentEditor = false
        return status
    }

    // This method detect whether NSText lost it's focus or not.  Make sure
    // self.currentEditor() is nil, then that means the search field lost its focus,
    // and tell it's delegate that the search field lost its focus.
    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)

        if let delegate = self.delegate as? ZSearchFieldDelegate {
            if self.currentEditor() == nil {
                delegate.searchFieldDidResignFirstResponder(textField: self)
            }
        }
    }

}
