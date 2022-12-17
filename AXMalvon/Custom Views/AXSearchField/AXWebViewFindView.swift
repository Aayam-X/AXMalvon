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
    unowned var appProperties: AXAppProperties!
    
    var hasDrawn: Bool = false
    
    lazy var searchField: NSSearchField = {
        let searchField = NSSearchField()
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.drawsBackground = false
        searchField.controlSize = .large
        searchField.placeholderString = "Find in page..."
        searchField.focusRingType = .none
        searchField.sendsSearchStringImmediately = true
        
        return searchField
    }()
    
    lazy var previousButton: AXHoverButton = {
        let button = AXHoverButton()
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "chevron.backward", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyDown
        button.target = self
        //        button.action = #selector(backButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var nextButton: AXHoverButton = {
        let button = AXHoverButton()
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "chevron.forward", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyDown
        button.target = self
        //        button.action = #selector(backButtonAction)
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
            
            addSubview(nextButton)
            nextButton.widthAnchor.constraint(equalToConstant: 16).isActive = true
            nextButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            nextButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
            
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
    
    func searchForText(){
        
        
        
    }
    
    @objc func findInWebpage() {
        let webView = appProperties.tabs[appProperties.currentTab].view
        
        webView.find(searchField.stringValue) { result in
            guard result.matchFound else { return }
            webView.evaluateJavaScript(
                "window.getSelection().getRangeAt(0).getBoundingClientRect().top") { offset, _ in
                    guard let offset = offset as? CGFloat else { return }
                    webView.scroll(.init(x: 0, y: offset))
                }
        }
    }
    
    private func keyDown(with event: NSEvent) -> Bool {
        if event.keyCode == kVK_Escape {
            close()
            return true
        }
        
        return false
    }
    
    func close() {
        self.removeFromSuperview()
    }
}
