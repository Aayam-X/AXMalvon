//
//  AXUpdaterView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-08.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import SwiftUI

class AXUpdaterView: NSView {
    private var hasDrawn: Bool = false
    private var signUpButtonClicked: Bool = false
    
    var updateFoundLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.stringValue = "Update found!"
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 35, weight: .medium)
        return label
    }()
    
    var textStorage: NSTextStorage!
    var scrollView: NSScrollView!
    var textView: NSTextView!
    
    var updateButton = AXHoverButton()
    var remindMeLaterButton = AXHoverButton()
    
    override func viewWillDraw() {
        if !hasDrawn {
            // MARK: Visual Effect View
            let visualEffectView = NSVisualEffectView()
            visualEffectView.material = .sidebar
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.state = .followsWindowActiveState
            visualEffectView.frame = bounds
            addSubview(visualEffectView)
            visualEffectView.autoresizingMask = [.height, .width]
            
            // MARK: Update Found Label
            addSubview(updateFoundLabel)
            updateFoundLabel.topAnchor.constraint(equalTo: topAnchor, constant: 30).isActive = true
            updateFoundLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            
            // MARK: Release Notes Label
            scrollView = NSTextView.scrollableTextView()
            textView = scrollView.documentView as? NSTextView
            
            textView.isEditable = false
            textView.isSelectable = false
            textView.alignment = .left
            textView.backgroundColor = .black
            
            Task {
                try? await getReleaseNotes()
            }
            
            textView.wantsLayer = true
            textView.layer?.cornerRadius = 5.0
            
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(scrollView)
            scrollView.topAnchor.constraint(equalTo: updateFoundLabel.bottomAnchor, constant: 15).isActive = true
            scrollView.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            scrollView.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -60).isActive = true
            
            // MARK: Update button
            updateButton.title = "Update"
            updateButton.translatesAutoresizingMaskIntoConstraints = false
            updateButton.target = self
            updateButton.action = #selector(update)
            addSubview(updateButton)
            updateButton.defaultColor = NSColor.controlAccentColor.withAlphaComponent(0.7).cgColor
            updateButton.layer?.backgroundColor = updateButton.defaultColor
            updateButton.hoverColor = NSColor.controlAccentColor.withAlphaComponent(0.9)
            updateButton.selectedColor = NSColor.controlAccentColor
            updateButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
            updateButton.widthAnchor.constraint(equalToConstant: 225).isActive = true
            updateButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            updateButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
            
            remindMeLaterButton.title = "Remind me later"
            remindMeLaterButton.translatesAutoresizingMaskIntoConstraints = false
            remindMeLaterButton.target = self
            remindMeLaterButton.action = #selector(quitApp)
            addSubview(remindMeLaterButton)
            remindMeLaterButton.defaultColor = NSColor.darkGray.cgColor
            remindMeLaterButton.layer?.backgroundColor = remindMeLaterButton.defaultColor
            remindMeLaterButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
            remindMeLaterButton.widthAnchor.constraint(equalToConstant: 225).isActive = true
            remindMeLaterButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            remindMeLaterButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
            
            
            
            hasDrawn = true
        }
    }
    
    func getReleaseNotes() async throws {
        let string = "Release Notes"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.boldSystemFont(ofSize: 36)
        ]
        let releaseNotesTitleString = NSAttributedString(string: string, attributes: attributes)
        
        let url = URL(string: "https://raw.githubusercontent.com/Aayam-X/Releases/main/releaseNotes.txt")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let contents = String(data: data, encoding: .utf8)
        let attributes1: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 14)
        ]
        let contentsAttributedString = NSAttributedString(string: "\n" + (contents ?? "Error"), attributes: attributes1)
        
        let attributedStrings = NSMutableAttributedString()
        attributedStrings.append(releaseNotesTitleString)
        attributedStrings.append(contentsAttributedString)
        
        textView.textStorage?.setAttributedString(attributedStrings)
    }
    
    @objc func quitApp() {
        self.window?.close()
    }
    
    @objc func update() {
        let url = URL(string: "https://github.com/Aayam-X/Releases/raw/main/Malvon.zip")!
        do {
            let safariURL = try FileManager.default.url(for: .applicationDirectory, in: .localDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Safari.app")
            print(safariURL)
            NSWorkspace.shared.open([url], withApplicationAt: safariURL, configuration: NSWorkspace.OpenConfiguration())
        } catch {
            print(error)
        }
        self.window?.close()
    }
    
}
