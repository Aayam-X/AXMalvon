//
//  AXAboutView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-24.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXAboutView: NSView {
    lazy var appIconImageView = NSImageView(frame: .init(x: 0, y: 0, width: 225, height: 225))
    
    lazy var appNameLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 35, weight: .medium)
        return label
    }()
    
    lazy var appVersionLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.isSelectable = true
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .systemGray
        return label
    }()
    
    lazy var copyrightLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 9)
        label.textColor = .systemGray
        return label
    }()
    
    lazy var taglineLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.isSelectable = true
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .systemGray
        return label
    }()
    
    lazy var donateButton = NSButton()
    lazy var feedbackButton = NSButton()
    
    fileprivate var hasDrawn: Bool = false
    
    lazy var bundleInfoDic = Bundle.main.infoDictionary
    
    override func viewWillDraw() {
        if !hasDrawn {
            let name = bundleInfoDic?["CFBundleDisplayName"] as! String
            let version = bundleInfoDic?["CFBundleShortVersionString"] as! String
            let build = bundleInfoDic?["CFBundleVersion"] as! String
            let copyright = bundleInfoDic?["NSHumanReadableCopyright"] as! String
            let tagline = "A cool tagline here :)"
            
            // MARK: - Visual Effect View
            let visualEffectView = NSVisualEffectView()
            visualEffectView.material = .headerView
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.state = .followsWindowActiveState
            visualEffectView.frame = bounds
            addSubview(visualEffectView)
            visualEffectView.autoresizingMask = [.height, .width]
            
            // MARK: - App Icon
            appIconImageView.image = NSImage(named: NSImage.applicationIconName)
            appIconImageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(appIconImageView)
            appIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            appIconImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 35).isActive = true
            
            // MARK: - Tagline
            taglineLabel.stringValue = tagline
            addSubview(taglineLabel)
            taglineLabel.centerXAnchor.constraint(equalTo: appIconImageView.centerXAnchor).isActive = true
            taglineLabel.topAnchor.constraint(equalTo: appIconImageView.bottomAnchor).isActive = true
            
            // MARK: - App Name
            appNameLabel.stringValue = name
            appNameLabel.font = .systemFont(ofSize: 35, weight: .medium)
            addSubview(appNameLabel)
            appNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 25).isActive = true
            appNameLabel.leftAnchor.constraint(equalTo: appIconImageView.rightAnchor, constant: 35).isActive = true
            
            // MARK: - App Version
            appVersionLabel.stringValue = "Version \(version) (\(build))"
            addSubview(appVersionLabel)
            appVersionLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor).isActive = true
            appVersionLabel.leftAnchor.constraint(equalTo: appIconImageView.rightAnchor, constant: 35).isActive = true
            
            // MARK: - Copyright
            copyrightLabel.stringValue = copyright
            addSubview(copyrightLabel)
            copyrightLabel.topAnchor.constraint(equalTo: appVersionLabel.bottomAnchor, constant: 40).isActive = true
            copyrightLabel.leftAnchor.constraint(equalTo: appIconImageView.rightAnchor, constant: 35).isActive = true
            copyrightLabel.widthAnchor.constraint(equalToConstant: 270).isActive = true
            
            // MARK: - Donate Button
            donateButton.title = "Donate"
            donateButton.translatesAutoresizingMaskIntoConstraints = false
            donateButton.bezelStyle = .rounded
            addSubview(donateButton)
            donateButton.widthAnchor.constraint(equalToConstant: 153.5).isActive = true
            donateButton.leftAnchor.constraint(equalTo: appIconImageView.rightAnchor, constant: 35).isActive = true
            donateButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
            
            // MARK: - Submit Feedback Button
            feedbackButton.title = "Submit Feedback"
            feedbackButton.translatesAutoresizingMaskIntoConstraints = false
            feedbackButton.bezelStyle = .rounded
            addSubview(feedbackButton)
            feedbackButton.widthAnchor.constraint(equalToConstant: 153.5).isActive = true
            feedbackButton.leftAnchor.constraint(equalTo: donateButton.rightAnchor, constant: 11).isActive = true
            feedbackButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15).isActive = true
            
            hasDrawn = true
        }
    }
    
    static func createAboutViewWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: .init(x: 0, y: 0, width: 530, height: 220),
            styleMask: [.closable, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.backgroundColor = .black
        
        return window
    }
}
