//
//  AXSearchFieldPopoverView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-12.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import Carbon.HIToolbox

class AXSearchFieldPopoverView: NSView, NSTextFieldDelegate {
    weak var appProperties: AXAppProperties!
    
    var newTabMode: Bool = true
    private var localMouseDownEventMonitor: Any?
    private var hasDrawn: Bool = false
    
    var suggestionWindow: NSPanel!
    
    private var highlightedSuggestion = 0 {
        willSet(newValue) {
            suggestions[highlightedSuggestion]!.isSelected = false
            suggestions[newValue]!.isSelected = true
        }
    }
    
    lazy var searchField: AXTextField! = {
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
    
    lazy var suggestionsStackView: NSStackView! = {
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
    
    init() {
        suggestionWindow = AXSearchFieldWindow()
        super.init(frame: .zero)
        suggestionWindow.contentView = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDraw() {
        if !hasDrawn {
            // Setup searchField
            searchField.delegate = self
            addSubview(searchField)
            searchField.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -50).isActive = true
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
                suggestion!.widthAnchor.constraint(equalTo: suggestionsStackView.widthAnchor).isActive = true
                suggestion!.heightAnchor.constraint(equalToConstant: 35).isActive = true
            }
            
            highlightedSuggestion = 0
            
            if appProperties.isPrivate {
                suggestionWindow.appearance = .init(named: .darkAqua)
            }
            
            hasDrawn = true
        }
    }
    
    private func searchEnter(_ url: URL) {
        if newTabMode {
            appProperties.tabManager.createNewTab(url: url)
        } else {
            appProperties.currentTab.view.load(URLRequest(url: url))
            appProperties.currentTab.url = url
        }
        
        newTabMode = true
    }
    
    @objc func searchSuggestionAction(_ sender: AXSearchFieldSuggestItem) {
        if !sender.titleValue.isEmpty {
            let url = fixURL(URL(string: "https://www.google.com/search?client=Malvon&q=\(sender.titleValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)")!)
            searchEnter(url)
            close()
        }
    }
    
    func searchFieldAction() {
        appProperties.currentTab.view.alphaValue = 1.0
        let value = searchField.stringValue
        
        var url: URL?
        
        if !searchField.stringValue.isEmpty {
            if value.starts(with: "malvon?") {
                print(value.string(after: 7))
                if let url = Bundle.main.url(forResource: value.string(after: 7), withExtension: "html") {
                    appProperties.tabManager.createNewTab(fileURL: url)
                }
            } else if value.starts(with: "file:///") {
                url = URL(string: value)!
            } else if value.isValidURL && !value.hasWhitespace {
                url = fixURL(URL(string: value)!)
            } else {
                url = fixURL(URL(string: "https://www.google.com/search?client=Malvon&q=\(searchField.stringValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)")!)
            }
        }
        
        if url != nil {
            searchEnter(url!)
        }
        
        close()
    }
    
    func updateSuggestions() {
        if !searchField.stringValue.isEmpty {
            // First one will always be equal to the text
            suggestions[0]!.isHidden = false
            suggestions[0]!.titleValue = searchField.stringValue
            
            SearchSuggestions.getQuerySuggestions(searchField.stringValue) { [self] results, error in
                if error != nil {
                    for index in 1..<suggestions.count {
                        let suggestion = suggestions[index]
                        DispatchQueue.main.async {
                            suggestion!.isHidden = true
                        }
                    }
                    return
                }
                
                let results = results!
                
                for index in 1..<suggestions.count {
                    let suggestion = suggestions[index]
                    
                    if index < results.count {
                        suggestion!.isHidden = false
                        suggestion!.titleValue = results[index]
                    } else {
                        suggestion!.isHidden = true
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
        appProperties.currentTab.view.alphaValue = 0.5
        
        // 300: Half the Width
        // 137: Half the Height
        suggestionWindow.setFrameOrigin(.init(x: appProperties.window.frame.midX - 300, y: appProperties.window.frame.midY - 137))
        
        appProperties.window.addChildWindow(suggestionWindow, ordered: .above)
        suggestionWindow.makeKey()
        self.suggestionWindow.makeFirstResponder(self.searchField)
        observer()
    }
    
    func close() {
        self.searchField.stringValue = ""
        appProperties.searchFieldShown = false
        self.newTabMode = true
        suggestions.forEach { suggestion in
            suggestion!.isHidden = true
        }
        
        appProperties.currentTab.view.alphaValue = 1.0
        appProperties.window.removeChildWindow(suggestionWindow)
        
        if let localMouseDownEventMonitor = localMouseDownEventMonitor {
            NSEvent.removeMonitor(localMouseDownEventMonitor)
            self.localMouseDownEventMonitor = nil
        }
        
        suggestionWindow.close()
    }
    
    func observer() {
        // When the user clicks outside of the window, we will exit
        localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown], handler: { [weak self] event -> NSEvent? in
            if event.window != self?.suggestionWindow {
                if event.window == self?.appProperties.window {
                    self!.close()
                    return nil
                }
            }
            
            return event
        })
        
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
