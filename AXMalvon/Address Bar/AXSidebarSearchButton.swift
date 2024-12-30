//
//  AXSidebarSearchButton.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-01.
//

import AppKit

protocol AXSidebarSearchButtonDelegate: AnyObject {
    func lockClicked()
    func sidebarSearchButtonRequestsHistoryManager() -> AXHistoryManager
    func sidebarSearchButtonSearchesFor(_ url: URL)
}

class AXSidebarSearchButton: NSButton {
    override var intrinsicContentSize: NSSize {
        .init(width: 300, height: 30)
    }

    weak var delegate: AXSidebarSearchButtonDelegate?

    weak var historyManager: AXHistoryManager? {
        delegate?.sidebarSearchButtonRequestsHistoryManager()
    }

    var previousStringValueCount = 0

    let suggestionsWindowController = AXAddressBarWindow()

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

        suggestionsWindowController.suggestionItemClickAction = {
            [weak self] suggestion in
            self?.addressField.stringValue = suggestion
            self?.searchFieldAction()
        }
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
        addressField.rightAnchor.constraint(
            equalToSystemSpacingAfter: rightAnchor, multiplier: 0.5
        ).isActive = true

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

private var debounceInterval: TimeInterval { 0.15 }
private var debounceWorkItem: DispatchWorkItem?
private var textChanges: Int = 0

// MARK: - Search Suggestions
extension AXSidebarSearchButton: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let query = addressField.stringValue

        // Cancel the previous debounce work item
        debounceWorkItem?.cancel()

        // Create a new debounce work item
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // Fetch Google suggestions asynchronously
            fetchGoogleSuggestions(for: query) { googleSuggestions in
                // Fetch filtered suggestions and websites
                let filteredSuggestions = AXSearchDatabase.shared
                    .getRelevantSearchSuggestions(
                        prefix: query, minOccurrences: 3)

                let filteredWebsites: [String]

                if let historyResults = self.historyManager?.search(
                    query: query)
                {
                    filteredWebsites = historyResults.map({ item in
                        return item.title + " — " + item.address
                    })
                } else {
                    filteredWebsites = []
                }

                // Update suggestions window on the main thread
                DispatchQueue.main.async {
                    self.suggestionsWindowController.showSuggestions(
                        topSearches: filteredSuggestions,
                        history: filteredWebsites,
                        googleSuggestions: googleSuggestions,
                        for: self.addressField
                    )
                }
            }
        }

        // Save the new work item
        debounceWorkItem = workItem

        if textChanges < 3 {
            textChanges += 1
            DispatchQueue.main.async(execute: workItem)
        } else {
            // Schedule the work item with a delay
            DispatchQueue.main.asyncAfter(
                deadline: .now() + debounceInterval, execute: workItem)
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
                addressField.currentEditor()?.selectedRange = NSMakeRange(
                    previousStringValueCount, currentSuggestion.count)
            }
            return true
        }
        if commandSelector == #selector(moveDown(_:)) {
            suggestionsWindowController.moveDown()
            if let currentSuggestion = suggestionsWindowController
                .currentSuggestion
            {
                addressField.stringValue = currentSuggestion
                addressField.currentEditor()?.selectedRange = NSMakeRange(
                    previousStringValueCount, currentSuggestion.count)
            }
            return true
        }

        if commandSelector == #selector(insertNewline(_:)) {
            if let suggestion = suggestionsWindowController.currentSuggestion {
                addressField.stringValue = suggestion
            }
            suggestionsWindowController.orderOut()
            searchFieldAction()
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
        addressField.stringValue = fullAddress?.absoluteString ?? "Empty2"
        debounceWorkItem?.cancel()

        return true
    }

    func searchFieldAction() {
        debounceWorkItem?.cancel()
        textChanges = 0
        let value = addressField.stringValue

        // Section 1: Handle File URLs
        if value.starts(with: "malvon?") {
            searchActionMalvonURL(value)
        } else if value.starts(with: "file:///") {
            searchActionFileURL(value)

            /* Section 2: Handle Regular Search Terms */
        } else if value.isValidURL() && !value.hasWhitespace() {
            searchActionURL(value)
        } else {
            searchActionSearchTerm(value)
        }

        suggestionsWindowController.orderOut()
    }

    /// URL: malvon?
    func searchActionMalvonURL(_ value: String) {
        // FIXME: File URL Implementation
        /*
        if let resourceURL = Bundle.main.url(
            forResource: value.string(after: 7), withExtension: "html")
        {
            // appProperties.tabManager.createNewTab(fileURL: resourceURL)
        }
         */
    }

    /// URL: file:///
    func searchActionFileURL(_ value: String) {
        if let url = URL(string: value) {
            searchEnter(url)
        }
    }

    /// URL: https://www.apple.com
    func searchActionURL(_ value: String) {
        guard let url = URL(string: value) else { return }

        searchEnter(url.fixURL())

        guard let parentWindow = self.window as? AXWindow else { return }

        Task(priority: .background) {
            if parentWindow.profiles[0].name != "Private" {
                AXSearchDatabase.shared.incrementOccurrence(for: value)
            }
        }
    }

    /// Google Search Term
    func searchActionSearchTerm(_ value: String) {
        let searchQuery =
            value.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            ?? ""
        let searchURL = URL(
            string:
                "https://www.google.com/search?client=Malvon&q=\(searchQuery)"
        )!.fixURL()
        searchEnter(searchURL)
    }

    private func searchEnter(_ url: URL) {
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
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
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
