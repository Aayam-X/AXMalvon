//
//  AXSearchFieldPopoverView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-12.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import Carbon.HIToolbox

class AXSearchFieldPopoverView: NSView, NSTextFieldDelegate {
    unowned var appProperties: AXAppProperties!
    
    fileprivate var hasDrawn = false
    var newTabMode: Bool = true
    
    let suggestionWindow = AXAboutView.createSuggestionsWindow()
    
    private var highlightedSuggestion = 0 {
        willSet(newValue) {
            suggestions[highlightedSuggestion].isSelected = false
            suggestions[newValue].isSelected = true
        }
    }
    
    lazy var searchField: NSTextField = {
        let searchField = NSTextField()
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
    
    lazy var suggestionsStackView: NSStackView = {
        let s = NSStackView()
        s.orientation = .vertical
        s.spacing = 1.08
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    let suggestions = [AXSearchFieldSuggestItem(), AXSearchFieldSuggestItem(), AXSearchFieldSuggestItem(), AXSearchFieldSuggestItem(), AXSearchFieldSuggestItem()]
    
    override func viewWillDraw() {
        if !hasDrawn {
            layer?.backgroundColor = NSColor.textBackgroundColor.withAlphaComponent(0.92).cgColor
            hasDrawn = true
            
            searchField.delegate = self
            addSubview(searchField)
            searchField.leftAnchor.constraint(equalTo: leftAnchor, constant: 25).isActive = true
            searchField.rightAnchor.constraint(equalTo: rightAnchor, constant: -25).isActive = true
            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 25).isActive = true
            
            searchField.becomeFirstResponder()
            
            addSubview(suggestionsStackView)
            suggestionsStackView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
            suggestionsStackView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 5).isActive = true
            suggestionsStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 25).isActive = true
            suggestionsStackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -25).isActive = true
            
            for suggestion in suggestions {
                suggestion.titleValue = ""
                suggestion.target = self
                suggestion.action = #selector(searchSuggestionAction)
                suggestionsStackView.addArrangedSubview(suggestion)
                suggestion.widthAnchor.constraint(equalTo: suggestionsStackView.widthAnchor).isActive = true
                suggestion.heightAnchor.constraint(equalToConstant: 35).isActive = true
            }
            
            highlightedSuggestion = 0
        }
    }
    
    private func searchEnter(_ url: URL) {
        if newTabMode {
            appProperties.tabManager.createNewTab(url: url)
        } else {
            appProperties.tabs[appProperties.currentTab].view.load(URLRequest(url: url))
        }
        
        newTabMode = true
    }
    
    @objc func searchSuggestionAction(_ sender: AXSearchFieldSuggestItem) {
        if !sender.titleValue.isEmpty {
            searchEnter(fixURL(URL(string: "https://www.google.com/search?client=Malvon&q=\(sender.titleValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)")!))
            close()
        }
    }
    
    func searchFieldAction() {
        appProperties.tabs[appProperties.currentTab].view.alphaValue = 1.0
        let value = searchField.stringValue
        
        if !searchField.stringValue.isEmpty {
            if value.starts(with: "malvon?") {
                print(value.string(after: 7))
                if let url = Bundle.main.url(forResource: value.string(after: 7), withExtension: "html") {
                    appProperties.tabManager.createNewTab(fileURL: url)
                }
            } else if value.starts(with: "file:///") {
                appProperties.tabManager.createNewTab(fileURL: URL(string: value)!)
            } else if value.isValidURL && !value.hasWhitespace {
                searchEnter(fixURL(URL(string: value)!))
            } else {
                searchEnter(fixURL(URL(string: "https://www.google.com/search?client=Malvon&q=\(searchField.stringValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)")!))
            }
        }
        
        close()
    }
    
    func updateSuggestions() {
        if !searchField.stringValue.isEmpty {
            // First one will always be equal to the text
            suggestions[0].titleValue = searchField.stringValue
            
            SearchSuggestions.getQuerySuggestions(searchField.stringValue) { [self] results, error in
                if error != nil {
                    for index in 1..<suggestions.count {
                        let suggestion = suggestions[index]
                        suggestion.titleValue = ""
                    }
                    return
                }
                
                let results = results!
                
                for index in 1..<suggestions.count {
                    let suggestion = suggestions[index]
                    
                    if index < results.count {
                        suggestion.titleValue = results[index]
                    } else {
                        suggestion.titleValue = ""
                    }
                }
            }
        } else {
            suggestions.forEach { suggestion in
                suggestion.title = ""
            }
        }
        
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            highlightedSuggestion == 0 ? (highlightedSuggestion = 4) : (highlightedSuggestion -= 1)
            searchField.stringValue = suggestions[highlightedSuggestion].titleValue
            return true
        }
        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            highlightedSuggestion == 4 ? (highlightedSuggestion = 0) : (highlightedSuggestion += 1)
            searchField.stringValue = suggestions[highlightedSuggestion].titleValue
            return true
        }
        if commandSelector == #selector(NSResponder.deleteToBeginningOfLine(_:)) {
            updateSuggestions()
            return false
        }
        
        if (commandSelector == #selector(NSResponder.cancelOperation(_:))) {
            close()
            return true
        }
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            searchFieldAction()
            return true
        }
        
        return false
    }
    
    func controlTextDidChange(_ obj: Notification) {
        updateSuggestions()
    }
    
    func show() {
        appProperties.tabs[appProperties.currentTab].view.alphaValue = 0.5
        appProperties.window.ignoresMouseEvents = true
        suggestionWindow.contentView = self
        
        print(appProperties.window.frame.midY)
        print((appProperties.window.frame.height - self.frame.size.height) / 2)
        suggestionWindow.setFrameOrigin(.init(x: (appProperties.window.frame.width - self.frame.width) / 2, y: (appProperties.window.frame.midY)))
        suggestionWindow.makeKeyAndOrderFront(nil)
    }
    
    func close() {
        self.searchField.stringValue = ""
        appProperties.searchFieldShown = false
        self.newTabMode = true
        suggestions.forEach { suggestion in
            suggestion.title = ""
        }
        
        appProperties.tabs[appProperties.currentTab].view.alphaValue = 1.0
        suggestionWindow.close()
        appProperties.window.ignoresMouseEvents = false
        self.removeFromSuperview()
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

fileprivate extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
    
    var hasWhitespace: Bool {
        return rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }
    
    func string(after: Int) -> String {
        let index = self.index(startIndex, offsetBy: after)
        return String(self[index...])
    }
}
