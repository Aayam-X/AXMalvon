//
//  AXWebViewFindView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-17.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import Carbon.HIToolbox

class AXWebViewFindView: NSView {
    weak var appProperties: AXAppProperties!
    
    fileprivate var hasDrawn = false
    
    lazy var searchField: NSSearchField = {
        let searchField = NSSearchField()
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.drawsBackground = false
        searchField.controlSize = .large
        searchField.placeholderString = "Find in page..."
        searchField.focusRingType = .none
        searchField.sendsSearchStringImmediately = false
        
        return searchField
    }()
    
    lazy var occurancesCountLabel: NSTextField = {
        let label = NSTextField()
        label.isEditable = false // This should be set to true in a while :)
        label.alignment = .left
        label.isBordered = false
        label.usesSingleLineMode = true
        label.drawsBackground = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var previousButton: AXHoverButton = {
        let button = AXHoverButton()
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "chevron.backward", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyDown
        button.target = self
        button.action = #selector(previousButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var nextButton: AXHoverButton = {
        let button = AXHoverButton()
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "chevron.forward", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyDown
        button.target = self
        button.action = #selector(nextButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewWillDraw() {
        if !hasDrawn {
            layer?.backgroundColor = .black
            layer?.cornerRadius = 5.0
            layer?.borderColor = NSColor.systemGray.cgColor
            layer?.borderWidth = 0.9
            hasDrawn = true
            
            addSubview(occurancesCountLabel)
            occurancesCountLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
            occurancesCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
            addSubview(nextButton)
            nextButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
            nextButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            nextButton.rightAnchor.constraint(equalTo: occurancesCountLabel.leftAnchor, constant: -5).isActive = true
            
            addSubview(previousButton)
            previousButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
            previousButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
            previousButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            previousButton.rightAnchor.constraint(equalTo: nextButton.leftAnchor, constant: -5).isActive = true
            
            searchField.target = self
            searchField.action = #selector(findInWebpage)
            addSubview(searchField)
            searchField.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
            searchField.rightAnchor.constraint(equalTo: previousButton.leftAnchor, constant: -5).isActive = true
            searchField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            
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
    
    func searchForText() {
        let webView = appProperties.tabs[appProperties.currentTab].view
        webView.removeAllHighlights()
        
        if !searchField.stringValue.isEmpty {
            webView.highlightAllOccurencesOfString(string: searchField.stringValue)
            
            // Number of words found
            let countCompletionHandler: (Int) -> Void = {
                self.occurancesCountLabel.stringValue = "\($0) Found"
            }
            
            // Get the count
            webView.handleSearchResultCount( completionHandler: countCompletionHandler )
        }
    }
    
    @objc func nextButtonAction() {
        let webView = appProperties.tabs[appProperties.currentTab].view
        webView.searchNext()
    }
    
    @objc func previousButtonAction() {
        let webView = appProperties.tabs[appProperties.currentTab].view
        webView.searchPrevious()
    }
    
    @objc func findInWebpage() {
        searchForText()
    }
    
    private func keyDown(with event: NSEvent) -> Bool {
        if event.keyCode == kVK_Escape {
            close()
            return true
        }
        
        super.keyDown(with: event)
        return false
    }
    
    func close() {
        self.removeFromSuperview()
    }
}
