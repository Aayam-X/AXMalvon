//
//  AXSearchFieldPopoverView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-12.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit
import Carbon.HIToolbox

class AXSearchFieldPopoverView: NSView, NSTextFieldDelegate {
    weak var appProperties: AXSessionProperties!
    
    var newTabMode: Bool = true
    private var localMouseDownEventMonitor: Any?
    private var hasDrawn: Bool = false
    
    var mostVisitedWebsites: [String] = []
    var searchedQueries: [String] = []
    var skipSuggestions = false
    
    private var highlightedSuggestion = 0 {
        willSet(newValue) {
            suggestions[highlightedSuggestion]!.isSelected = false
            suggestions[newValue]!.isSelected = true
        }
    }
    
    var searchField: AXTextField! = {
        let searchField = AXTextField()
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.alignment = .left
        searchField.isBordered = false
        searchField.usesSingleLineMode = true
        searchField.drawsBackground = false
        searchField.lineBreakMode = .byTruncatingTail
        searchField.placeholderString = "Search or Enter URL..."
        searchField.font = .systemFont(ofSize: 25)
        searchField.focusRingType = .none
        
        return searchField
    }()
    
    var suggestionsStackView: NSStackView! = {
        let s = NSStackView()
        s.orientation = .vertical
        s.spacing = 1.08
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    var suggestions: [AXSearchFieldSuggestItem?]! = [
        AXSearchFieldSuggestItem(),
        AXSearchFieldSuggestItem(),
        AXSearchFieldSuggestItem(),
        AXSearchFieldSuggestItem(),
        AXSearchFieldSuggestItem()
    ]
    
    deinit {
        suggestionsStackView = nil
        suggestions = nil
        searchField = nil
    }
    
    //    func saveMostVisitedSites() {
    //        print("func saveMostVisitedSites()")
    //        let websiteCounts = searchedQueries.reduce(into: [:]) { counts, item in counts[item, default: 0] += 1 }
    //        let websites = websiteCounts.filter { $0.value > 3 }.map { $0.key }
    //
    //        let newWebsites = websites.filter { !mostVisitedWebsites.contains($0) }
    //        mostVisitedWebsites.append(contentsOf: newWebsites)
    //        UserDefaults.standard.set(mostVisitedWebsites, forKey: "MostVisitedWebsite")
    //    }
    
    init(appProperties: AXSessionProperties) {
        self.appProperties = appProperties
//        mostVisitedWebsites = UserDefaults.standard.stringArray(forKey: "MostVisitedWebsite") ?? []
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDraw() {
        if !hasDrawn {
            // Setup searchField
            searchField.delegate = self
            addSubview(searchField)
            searchField.widthAnchor.constraint(equalToConstant: 550).isActive = true
            searchField.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 25).isActive = true
            
            // Setup seperator
            let seperator = NSBox()
            seperator.boxType = .separator
            seperator.translatesAutoresizingMaskIntoConstraints = false
            addSubview(seperator)
            seperator.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 20).isActive = true
            seperator.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
            seperator.rightAnchor.constraint(equalTo: rightAnchor, constant: 5).isActive = true
            
            // Setup suggestionsStackView
            addSubview(suggestionsStackView)
            suggestionsStackView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 30).isActive = true
            suggestionsStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            suggestionsStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            // Setup suggestionItems
            for suggestion in suggestions {
                suggestion!.isHidden = true
                suggestion!.target = self
                suggestion!.action = #selector(searchSuggestionAction)
                suggestionsStackView.addArrangedSubview(suggestion!)
                suggestion!.widthAnchor.constraint(equalToConstant: 550).isActive = true
                suggestion!.heightAnchor.constraint(equalToConstant: 35).isActive = true
            }
            
            highlightedSuggestion = 0
            
//            if appProperties.isPrivate {
//                suggestionWindow.appearance = .init(named: .darkAqua)
//            }
            
            hasDrawn = true
            _ = searchField.becomeFirstResponder()
        }
    }
    
    private func searchEnter(_ url: URL) {
        if newTabMode {
            appProperties.tabManager.createNewTab(from: url)
        } else {
            appProperties.tabManager.updateCurrentWebPage(with: url)
        }
        
        newTabMode = true
    }
    
    @objc func searchSuggestionAction(_ sender: AXSearchFieldSuggestItem) {
        if !sender.titleValue.isEmpty {
            let url = fixURL(URL(string: "https://www.google.com/search?client=Malvon&q=\(sender.titleValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)")!)
            searchEnter(url)
            
            appProperties.searchBarWindow.close()
        }
    }
    
    func searchFieldAction() {
        appProperties.contentView.alphaValue = 1.0
        let value = searchField.stringValue
        
        var url: URL?
        
//        if !appProperties.isPrivate {
//            searchedQueries.append(value)
//
//            if searchedQueries.count == 15 {
//                //saveMostVisitedSites()
//                searchedQueries.removeAll()
//            }
//        }
        
        if !searchField.stringValue.isEmpty {
            if value.starts(with: "malvon?") {
                print(value.string(after: 7))
                if let url = Bundle.main.url(forResource: value.string(after: 7), withExtension: "html") {
//                    appProperties.tabManager.createNewTab(fileURL: url)
                }
            } else if value.starts(with: "file:///") {
                url = URL(string: value)!
            } else if value.isValidURL() && !value.hasWhitespace() {
                url = fixURL(URL(string: value)!)
            } else {
                url = fixURL(URL(string: "https://www.google.com/search?client=Malvon&q=\(searchField.stringValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)")!)
            }
        }
        
        if url != nil {
            searchEnter(url!)
        }
        
        appProperties.searchBarWindow.close()
    }
    
    func updateSuggestions() {
        if !searchField.stringValue.isEmpty {
            // First one will always be equal to the text
            suggestions[0]!.isHidden = false
            
            let userInput = searchField.stringValue
            let filteredWebsites = mostVisitedWebsites.filter { website in
                return website.starts(with: userInput)
            }
            
            if let autofillSuggestion = filteredWebsites.first {
                let fieldEditor: NSText? = window?.fieldEditor(false, for: searchField)
                if fieldEditor != nil {
                    updateFieldEditor(fieldEditor, withSuggestion: autofillSuggestion)
                    suggestions[0]!.titleValue = autofillSuggestion
                }
            } else {
                suggestions[0]!.titleValue = searchField.stringValue
            }
            
            Task {
                do {
                    let terms = try await SearchSuggestions.getQuerySuggestion(searchField.stringValue)
                    
                    for i in 1 ..< 5  {
                        if i <= terms.count {
                            suggestions[i]!.isHidden = false
                            suggestions[i]!.titleValue = terms[i - 1]
                        } else {
                            suggestions[i]!.isHidden = true
                        }
                    }
                } catch {
                    print("Search Suggestion: Error: \(error.localizedDescription)")
                    
                    for index in 1 ..< 5 {
                        suggestions[index]!.isHidden = true
                    }
                }
            }
        } else {
            suggestions.forEach { suggestion in
                suggestion!.isHidden = true
            }
        }
        
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            highlightedSuggestion == 0 ? (highlightedSuggestion = 4) : (highlightedSuggestion -= 1)
            searchField.stringValue = suggestions[highlightedSuggestion]!.titleValue
            return true
        }
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            highlightedSuggestion == 4 ? (highlightedSuggestion = 0) : (highlightedSuggestion += 1)
            searchField.stringValue = suggestions[highlightedSuggestion]!.titleValue
            return true
        }
        if commandSelector == #selector(NSResponder.deleteToBeginningOfLine(_:)) {
            updateSuggestions()
            return false
        }
        
        if (commandSelector == #selector(NSResponder.cancelOperation(_:))) {
            appProperties.searchBarWindow.close()
            return true
        }
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            searchFieldAction()
            return true
        }
        if commandSelector == #selector(NSResponder.deleteForward(_:)) || commandSelector == #selector(NSResponder.deleteBackward(_:)) {
            let insertionRange = textView.selectedRanges[0].rangeValue
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                skipSuggestions = (insertionRange.location != 0 || insertionRange.length > 0)
            } else {
                skipSuggestions = (insertionRange.location != textView.string.count || insertionRange.length > 0)
            }
            return false
        }
        
        return false
    }
    
    private func updateFieldEditor(_ fieldEditor: NSText?, withSuggestion suggestion: String?) {
        let selection = NSRange(location: fieldEditor?.selectedRange.location ?? 0, length: suggestion?.count ?? 0)
        fieldEditor?.string = suggestion ?? ""
        fieldEditor?.selectedRange = selection
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if !skipSuggestions {
            updateSuggestions()
        } else {
            skipSuggestions = false
            suggestions.forEach { suggestion in
                suggestion!.isHidden = true
            }
        }
    }
    
    func windowClosed() {
        self.searchField.stringValue = ""
        self.newTabMode = true
        suggestions.forEach { suggestion in
            suggestion!.isHidden = true
        }
    }
}

fileprivate func fixURL(_ url: URL) -> URL {
    var newURL = ""
    
    if url.isFileURL || (url.host != nil && url.scheme != nil) {
        return url
    }
    
    if url.scheme == nil {
        newURL += "https://"
    }
    
    if let host = url.host, host.contains("www") {
        newURL += "www.\(url.host!)"
    }
    
    newURL += url.path
    newURL += url.query ?? ""
    return URL(string: newURL)!
}

class AXTextField: NSTextField {
    // Prevent the text from being selected when becoming first responder
    override func becomeFirstResponder() -> Bool {
        let status = super.becomeFirstResponder()
        
        let selectionRange = currentEditor()?.selectedRange
        currentEditor()?.selectedRange = .init(location: selectionRange?.length ?? 0, length: 0)
        
        return status
    }
}

extension String {
    func isValidURL() -> Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
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
