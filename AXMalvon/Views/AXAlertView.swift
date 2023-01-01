//
//  AXAlertView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-31.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import Carbon.HIToolbox

class AXAlertView: NSView {
    var hasDrawn: Bool = false
    
    var completionHandler: ((Bool) -> Void)?
    
    lazy var alertTitle: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 35, weight: .medium)
        return label
    }()
    
    lazy var okayButton: AXHoverButton = {
        let button = AXHoverButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer?.borderColor = NSColor.textColor.withAlphaComponent(0.4).cgColor
        button.layer?.borderWidth = 1.0
        button.title = "Yes"
        button.target = self
        button.defaultColor = NSColor.controlAccentColor.withAlphaComponent(0.4).cgColor
        button.hoverColor = NSColor.controlAccentColor.withAlphaComponent(0.6)
        button.selectedColor = NSColor.controlAccentColor
        button.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.4).cgColor
        button.action = #selector(yesButtonAction)
        return button
    }()
    
    lazy var noButton: AXHoverButton = {
        let button = AXHoverButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer?.borderColor = NSColor.textColor.withAlphaComponent(0.4).cgColor
        button.layer?.borderWidth = 1.0
        button.title = "No"
        button.target = self
        button.action = #selector(noButtonAction)
        return button
    }()
    
    override func viewWillDraw() {
        if !hasDrawn {
            alertTitle.stringValue = "Do you want to open 'Riot Client'"
            addSubview(alertTitle)
            alertTitle.topAnchor.constraint(equalTo: topAnchor, constant: 50).isActive = true
            alertTitle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            
            addSubview(okayButton)
            okayButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            okayButton.widthAnchor.constraint(equalToConstant: 250).isActive = true
            okayButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            okayButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
            
            addSubview(noButton)
            noButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            noButton.widthAnchor.constraint(equalToConstant: 250).isActive = true
            noButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            noButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
            
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
                if self.keyDown(with: $0) {
                    return nil // needed to get rid of purr sound
                } else {
                    return $0
                }
            }
            
            hasDrawn = true
        }
    }
    
    static func presentAlert(window: NSWindow, completionHandler: @escaping (Bool) -> Void) {
        let view = AXAlertView()
        view.completionHandler = completionHandler
        
        let localWindow = NSWindow.create(styleMask: .fullSizeContentView, size: .init(width: 550, height: 550))
        localWindow.contentView = view
        
        window.beginSheet(localWindow)
    }
    
    @objc func yesButtonAction() {
        self.window?.close()
        completionHandler?(true)
    }
    
    @objc func noButtonAction() {
        self.window?.close()
        completionHandler?(false)
    }
    
    private func keyDown(with event: NSEvent) -> Bool {
        if event.keyCode == kVK_Return {
            yesButtonAction()
            return true
        } else if event.keyCode == kVK_Escape {
            noButtonAction()
            return true
        }
        
        super.keyDown(with: event)
        return false
    }
}
