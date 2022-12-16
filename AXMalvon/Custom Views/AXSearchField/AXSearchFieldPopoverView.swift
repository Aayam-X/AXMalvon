//
//  AXSearchFieldPopoverView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-12.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import Carbon.HIToolbox

class AXSearchFieldPopoverView: NSView {
    unowned var appProperties: AXAppProperties!
    
    var hasDrawn: Bool = false
    var newTabMode: Bool = true
    
    lazy var searchField: NSTextField = {
        let searchField = NSTextField()
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.alignment = .left
        searchField.isBordered = false
        searchField.usesSingleLineMode = true
        searchField.drawsBackground = false
        searchField.lineBreakStrategy = .pushOut
        searchField.placeholderString = "Search or Enter URL..."
        searchField.font = .systemFont(ofSize: 25)
        searchField.focusRingType = .none
        
        return searchField
    }()
    
    override func viewWillDraw() {
        if !hasDrawn {
            layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
            layer?.cornerRadius = 50.0
            layer?.borderColor = NSColor.systemGray.cgColor
            layer?.borderWidth = 1.5
            hasDrawn = true
            
            searchField.target = self
            searchField.action = #selector(searchFieldAction)
            addSubview(searchField)
            searchField.leftAnchor.constraint(equalTo: leftAnchor, constant: 50).isActive = true
            searchField.rightAnchor.constraint(equalTo: rightAnchor, constant: -50).isActive = true
            searchField.topAnchor.constraint(equalTo: topAnchor, constant: 50).isActive = true
            
            searchField.becomeFirstResponder()
            
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
                if self.keyDown(with: $0) {
                    return nil // needed to get rid of purr sound
                } else {
                    return $0
                }
            }
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
    
    @objc func searchFieldAction() {
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
    
    private func keyDown(with event: NSEvent) -> Bool {
        if event.keyCode == kVK_Escape {
            close()
            return true
        }
        
        return false
    }
    
    func close() {
        self.searchField.stringValue = ""
        appProperties.searchFieldShown = false
        self.newTabMode = true
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
