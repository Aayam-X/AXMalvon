//
//  AXPreferenceProfileView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-24.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit

class AXPreferenceProfileView: NSView {
    private var hasDrawn: Bool = false
    var currentProfileName: String = ""
    
    var nameTextField: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.drawsBackground = false
        label.bezelStyle = .roundedBezel
        label.placeholderString = "Profile Name"
        label.font = .systemFont(ofSize: 15)
        label.controlSize = .large
        label.focusRingType = .none
        return label
    }()
    
    var profileNameErrorLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.textColor = .red
        return label
    }()
    
    var profileListComboButton: NSPopUpButton = {
        let button = NSPopUpButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.title = "General"
        
        return button
    }()
        
    override func viewWillDraw() {
        if !hasDrawn {
            self.setFrameSize(.init(width: 530, height: 220))
            
            addSubview(profileListComboButton)
            profileListComboButton.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true
            profileListComboButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            
            addSubview(nameTextField)
            nameTextField.topAnchor.constraint(equalTo: topAnchor, constant: 50).isActive = true
            nameTextField.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            nameTextField.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            addSubview(profileNameErrorLabel)
            profileNameErrorLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
            profileNameErrorLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            profileNameErrorLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            // Setup profiles
            let profileListMenu = NSMenu()
            
            // Get profiles
            let profileNames: [String] = UserDefaults.standard.stringArray(forKey: "Profiles")!
            
            for name in profileNames {
                profileListMenu.addItem(withTitle: name, action: #selector(profileMenuItemClick), keyEquivalent: "")
            }
            
            profileListComboButton.menu = profileListMenu
            swapCurrentlyEditingProfile(title: profileNames[0])

            
            hasDrawn = true
        }
    }
    
    @objc func profileMenuItemClick(_ sender: NSMenuItem) {
        swapCurrentlyEditingProfile(title: sender.title)
    }
    
    func swapCurrentlyEditingProfile(title: String) {
        currentProfileName = title
        
        
        nameTextField.stringValue = title
    }
    
    @objc func profileNameTextFieldAction() {
        let newProfileName = nameTextField.stringValue
        
        if newProfileName.isEmpty {
            nameTextField.stringValue = currentProfileName
            return
        }
    }
}
