//
//  AXPreferenceAccountView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-27.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import Cocoa

class AXPreferenceAccountView: NSView {
    private var hasDrawn: Bool = false
    
    lazy var nameLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 35, weight: .medium)
        return label
    }()
    
    lazy var emailLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 15)
        label.textColor = .systemGray
        return label
    }()
    
    lazy var validUntilLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 9)
        return label
    }()
    
    lazy var inviteAFriendButton: AXPreferenceButton = {
        let button = AXPreferenceButton()
        button.imageView.image = NSImage(systemSymbolName: "person.fill.badge.plus", accessibilityDescription: nil)
        button.isBordered = true
        button.bezelStyle = .texturedSquare
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleView.stringValue = "Invite a friend"
        return button
    }()
    
    lazy var getSupportButton: AXPreferenceButton = {
        let button = AXPreferenceButton()
        button.imageView.image = NSImage(systemSymbolName: "hand.wave.fill", accessibilityDescription: nil)
        button.isBordered = true
        button.bezelStyle = .texturedSquare
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleView.stringValue = "Get support"
        return button
    }()
    
    lazy var cancelSubscriptionButton: AXPreferenceButton = {
        let button = AXPreferenceButton()
        button.imageView.image = NSImage(systemSymbolName: "xmark.octagon.fill", accessibilityDescription: nil)
        button.isBordered = true
        button.bezelStyle = .texturedSquare
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleView.stringValue = "Cancel Subscription"
        button.titleView.textColor = .systemRed
        button.imageView.contentTintColor = .systemRed
        return button
    }()
    
    override func viewWillDraw() {
        if !hasDrawn {
            self.setFrameSize(.init(width: 500, height: 300))
            
            // Name label
            nameLabel.stringValue = "Name Name"
            addSubview(nameLabel)
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 25).isActive = true
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            
            // Email Label
            emailLabel.stringValue = "email@gmail.com"
            addSubview(emailLabel)
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5).isActive = true
            emailLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            
            // Valid Until Label
            validUntilLabel.stringValue = "License Valid Until: DATE"
            addSubview(validUntilLabel)
            validUntilLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
            validUntilLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
            
            // Invite a friend button
            addSubview(inviteAFriendButton)
            inviteAFriendButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 10).isActive = true
            inviteAFriendButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            inviteAFriendButton.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            inviteAFriendButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            // Get support button
            addSubview(getSupportButton)
            getSupportButton.topAnchor.constraint(equalTo: inviteAFriendButton.bottomAnchor, constant: 5).isActive = true
            getSupportButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            getSupportButton.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            getSupportButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            // Cancel Subscription Button
            addSubview(cancelSubscriptionButton)
            cancelSubscriptionButton.topAnchor.constraint(equalTo: getSupportButton.bottomAnchor, constant: 5).isActive = true
            cancelSubscriptionButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            cancelSubscriptionButton.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
            cancelSubscriptionButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            hasDrawn = true
        }
    }
    
}
