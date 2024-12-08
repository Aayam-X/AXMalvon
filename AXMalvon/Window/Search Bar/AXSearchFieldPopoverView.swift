//
//  AXSearchFieldPopoverView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-12.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class AXSearchFieldPopoverView: NSView, NSTextFieldDelegate {
    private var hasDrawn = false
    unowned var searchBarWindow: AXSearchBarWindow

    var newTabMode = true
    private var skipSuggestions = false

    private var highlightedSuggestion = 0 {
        willSet {
            suggestions[highlightedSuggestion]?.isSelected = false
            suggestions[newValue]?.isSelected = true
        }
    }

    private lazy var searchIcon: NSImageView = {
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = NSImage(
            systemSymbolName: "magnifyingglass",
            accessibilityDescription: "Search Icon")
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
    }()

    lazy var searchField: NSTextField = {
        let field = NSTextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.alignment = .left
        field.isBordered = false
        field.usesSingleLineMode = true
        field.drawsBackground = false
        field.lineBreakMode = .byTruncatingTail
        field.placeholderString = "Search or Enter URL..."
        field.font = .systemFont(ofSize: 25)
        field.focusRingType = .none
        field.delegate = self
        return field
    }()

    private lazy var suggestionsStackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 10  // Increase spacing for better visibility
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var suggestions: [AXSearchFieldSuggestItem?] = Array(
        repeating: nil, count: 5)

    init(searchBarWindow: AXSearchBarWindow) {
        self.searchBarWindow = searchBarWindow
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        suggestions.removeAll()
    }

    override func viewWillDraw() {
        guard !hasDrawn else { return }
        setupUI()
        hasDrawn = true
        searchField.becomeFirstResponder()
    }

    private func setupUI() {
        // Container for the search field and icon
        let searchContainer = NSStackView()
        searchContainer.orientation = .horizontal
        searchContainer.alignment = .centerY
        searchContainer.spacing = 10
        searchContainer.translatesAutoresizingMaskIntoConstraints = false

        addSubview(searchContainer)
        searchContainer.addArrangedSubview(searchIcon)
        searchContainer.addArrangedSubview(searchField)

        NSLayoutConstraint.activate([
            searchContainer.leftAnchor.constraint(
                equalTo: leftAnchor, constant: 25),
            searchContainer.topAnchor.constraint(
                equalTo: topAnchor, constant: 25),
            searchIcon.widthAnchor.constraint(equalToConstant: 25),
            searchIcon.heightAnchor.constraint(equalToConstant: 25),
            searchField.widthAnchor.constraint(equalToConstant: 500),
        ])

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(
                equalTo: searchContainer.bottomAnchor, constant: 20),
            separator.leftAnchor.constraint(equalTo: leftAnchor, constant: 5),
            separator.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -5),
        ])

        addSubview(suggestionsStackView)
        NSLayoutConstraint.activate([
            suggestionsStackView.topAnchor.constraint(
                equalTo: searchField.bottomAnchor, constant: 30),
            suggestionsStackView.leftAnchor.constraint(
                equalTo: leftAnchor, constant: 15),
            suggestionsStackView.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -15),
        ])

        for i in 0..<suggestions.count {
            let suggestion = AXSearchFieldSuggestItem()
            suggestion.isHidden = true
            suggestion.target = self
            suggestion.action = #selector(searchSuggestionAction(_:))
            suggestionsStackView.addArrangedSubview(suggestion)
            NSLayoutConstraint.activate([
                suggestion.widthAnchor.constraint(equalToConstant: 550),
                suggestion.heightAnchor.constraint(equalToConstant: 35),
            ])
            suggestions[i] = suggestion
        }

        highlightedSuggestion = 0
    }

    func windowClosed() {
        searchField.stringValue = ""
        newTabMode = true
        suggestions.forEach { $0?.isHidden = true }
    }
}

extension AXSearchFieldPopoverView {
    // MARK: Search Suggestions
    // Update icon based on input
    func controlTextDidChange(_ notification: Notification) {
        if searchField.stringValue.isValidURL() {
            searchIcon.image = NSImage(
                systemSymbolName: "network",
                accessibilityDescription: "Internet Icon")
        } else {
            searchIcon.image = NSImage(
                systemSymbolName: "magnifyingglass",
                accessibilityDescription: "Search Icon")
        }

        if !skipSuggestions {
            updateSuggestions()
        } else {
            skipSuggestions = false
            suggestions.forEach { $0?.isHidden = true }
        }
    }

    private func updateSuggestions() {
        guard !searchField.stringValue.isEmpty else {
            suggestions.forEach { $0?.isHidden = true }
            return
        }

        suggestions[0]?.isHidden = false
        suggestions[0]?.titleValue = searchField.stringValue

        let userInput = searchField.stringValue

        DispatchQueue.global(qos: .userInitiated).async {
            let filteredWebsites = AXSearchDatabase.shared
                .getRelevantSearchSuggestions(
                    prefix: userInput, minOccurrences: 3)

            DispatchQueue.main.async {
                for (index, suggestion) in self.suggestions.enumerated()
                    .dropFirst()
                {
                    if index <= filteredWebsites.count {
                        suggestion?.isHidden = false
                        suggestion?.titleValue = filteredWebsites[index - 1]
                    } else {
                        suggestion?.isHidden = true
                    }
                }

                if let firstSuggestion = filteredWebsites.first,
                    let fieldEditor = self.window?.fieldEditor(
                        false, for: self.searchField)
                {
                    self.updateFieldEditor(
                        fieldEditor, withSuggestion: firstSuggestion)

                    self.highlightedSuggestion = 1
                } else {
                    self.highlightedSuggestion = 0
                }
            }
        }
    }

    private func updateFieldEditor(
        _ fieldEditor: NSText?, withSuggestion suggestion: String
    ) {
        let selection = NSRange(
            location: fieldEditor?.selectedRange.location ?? 0,
            length: suggestion.count)
        fieldEditor?.string = suggestion
        fieldEditor?.selectedRange = selection
    }

    func control(
        _ control: NSControl, textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.moveUp(_:)):
            highlightedSuggestion =
                (highlightedSuggestion == 0) ? 4 : highlightedSuggestion - 1
            searchField.stringValue =
                suggestions[highlightedSuggestion]?.titleValue ?? ""
            return true
        case #selector(NSResponder.moveDown(_:)):
            highlightedSuggestion =
                (highlightedSuggestion == 4) ? 0 : highlightedSuggestion + 1
            searchField.stringValue =
                suggestions[highlightedSuggestion]?.titleValue ?? ""
            return true
        case #selector(NSResponder.deleteToBeginningOfLine(_:)):
            updateSuggestions()
            return false
        case #selector(NSResponder.cancelOperation(_:)):
            searchBarWindow.close()
            return true
        case #selector(NSResponder.insertNewline(_:)):
            searchFieldAction()
            return true
        case #selector(NSResponder.deleteForward(_:)),
            #selector(NSResponder.deleteBackward(_:)):
            let insertionRange =
                textView.selectedRanges.first?.rangeValue ?? NSRange()
            skipSuggestions =
                (commandSelector == #selector(NSResponder.deleteBackward(_:))
                    && (insertionRange.location != 0
                        || insertionRange.length > 0))
                || (commandSelector == #selector(NSResponder.deleteForward(_:))
                    && (insertionRange.location != textView.string.count
                        || insertionRange.length > 0))
            return false
        default:
            return false
        }
    }
}

// MARK: - Search Actions
extension AXSearchFieldPopoverView {
    private func searchEnter(_ url: URL) {
        if newTabMode {
            searchBarWindow.searchBarDelegate?.searchBarCreatesNewTab(with: url)
        } else {
            searchBarWindow.searchBarDelegate?.searchBarUpdatesCurrentTab(
                with: url)
        }
        newTabMode = true
    }

    @objc private func searchSuggestionAction(
        _ sender: AXSearchFieldSuggestItem
    ) {
        guard !sender.titleValue.isEmpty else { return }

        searchField.stringValue = sender.titleValue
        searchFieldAction()
        searchBarWindow.close()
    }

    func searchFieldAction() {
        searchBarWindow.searchBarDelegate?.searchBarDidDisappear()

        guard !searchField.stringValue.isEmpty else {
            searchBarWindow.close()
            return
        }

        let value = searchField.stringValue

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

        searchBarWindow.close()
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

        guard let parentWindow = searchBarWindow.parentWindow1 else { return }

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
}

// MARK: Extensions
extension URL {
    func fixURL() -> URL {
        var newURL = ""
        
        if isFileURL || (host != nil && scheme != nil) {
            return self
        }
        
        if scheme == nil {
            newURL += "https://"
        }
        
        if let host = host, host.contains("www") {
            newURL += "www.\(host)"
        }
        
        newURL += path
        newURL += query ?? ""
        return URL(string: newURL)!
    }
}

extension String {
    func isValidURL() -> Bool {
        let detector = try! NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(
            in: self, options: [],
            range: NSRange(location: 0, length: self.utf16.count))
        {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }

    func hasWhitespace() -> Bool {
        return rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }

    func string(after: Int) -> String {
        let index = self.index(startIndex, offsetBy: after)
        return String(self[index...])
    }
}
