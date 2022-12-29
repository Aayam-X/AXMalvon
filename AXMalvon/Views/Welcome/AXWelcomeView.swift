//
//  AXWelcomeView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-28.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import Cocoa

class AXWelcomeView: NSView {
    lazy var welcomeToMalvonLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.stringValue = "Welcome to Malvon!"
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 35, weight: .medium)
        return label
    }()
    
    lazy var emailAddressTextField: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.drawsBackground = false
        label.bezelStyle = .roundedBezel
        label.placeholderString = "Enter email address"
        label.font = .systemFont(ofSize: 15)
        label.controlSize = .large
        label.focusRingType = .none
        return label
    }()
    
    lazy var passwordTextField: NSSecureTextField = {
        let label = NSSecureTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.drawsBackground = false
        label.bezelStyle = .roundedBezel
        label.placeholderString = "Enter password"
        label.font = .systemFont(ofSize: 15)
        label.controlSize = .large
        label.focusRingType = .none
        
        label.target = self
        label.action = #selector(enterAction(_:))
        return label
    }()
    
    lazy var retypeSecurePasswordTextField: NSSecureTextField = {
        let label = NSSecureTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.drawsBackground = false
        label.bezelStyle = .roundedBezel
        label.placeholderString = "Confirm your password"
        label.font = .systemFont(ofSize: 15)
        label.controlSize = .large
        label.focusRingType = .none
        
        label.target = self
        label.action = #selector(enterAction(_:))
        return label
    }()
    
    lazy var enterNameTextField: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.drawsBackground = false
        label.bezelStyle = .roundedBezel
        label.placeholderString = "Enter name"
        label.font = .systemFont(ofSize: 15)
        label.controlSize = .large
        label.focusRingType = .none
        return label
    }()
    
    lazy var signInButton: AXHoverButton = {
        let button = AXHoverButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer?.borderColor = NSColor.textColor.withAlphaComponent(0.4).cgColor
        button.layer?.borderWidth = 1.0
        button.title = "Sign in"
        button.target = self
        button.action = #selector(enterAction(_:))
        return button
    }()
    
    lazy var signUpButton: AXHoverButton = {
        let button = AXHoverButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer?.borderColor = NSColor.textColor.withAlphaComponent(0.4).cgColor
        button.layer?.borderWidth = 1.0
        button.title = "Sign Up"
        button.target = self
        button.action = #selector(showConfirmPassword)
        return button
    }()
    
    lazy var errorLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.stringValue = "Error: "
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = .systemRed
        return label
    }()
    
    private var hasDrawn: Bool = false
    
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
            
            // MARK: Welcome To Malvon Label
            addSubview(welcomeToMalvonLabel)
            welcomeToMalvonLabel.topAnchor.constraint(equalTo: topAnchor, constant: 50).isActive = true
            welcomeToMalvonLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            
            // MARK: Error label
            addSubview(errorLabel)
            errorLabel.topAnchor.constraint(equalTo: welcomeToMalvonLabel.bottomAnchor, constant: 5.0).isActive = true
            errorLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            errorLabel.isHidden = true
            
            // MARK: Email Adress Text Field
            emailAddressTextField.nextKeyView = passwordTextField
            addSubview(emailAddressTextField)
            emailAddressTextField.topAnchor.constraint(equalTo: welcomeToMalvonLabel.bottomAnchor, constant: 25).isActive = true
            emailAddressTextField.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            emailAddressTextField.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            // MARK: Password Text Field
            addSubview(passwordTextField)
            passwordTextField.topAnchor.constraint(equalTo: emailAddressTextField.bottomAnchor, constant: 10).isActive = true
            passwordTextField.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            passwordTextField.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            // MARK: Sign in button
            addSubview(signInButton)
            signInButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 50).isActive = true
            signInButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            signInButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            signInButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            // MARK: Sign up button
            addSubview(signUpButton)
            signUpButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 5).isActive = true
            signUpButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            signUpButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            signUpButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            hasDrawn = true
        }
    }
    
    @objc func enterAction(_ sender: Any?) {
        if emailAddressTextField.stringValue.isEmpty || passwordTextField.stringValue.isEmpty {
            showError("Fields cannot be empty")
        }
    }
    
    private func showError(_ message: String) {
        errorLabel.isHidden = false
        errorLabel.stringValue = message
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.errorLabel.isHidden = true
        }
    }
    
    @objc func showConfirmPassword(_ sender: AXHoverButton) {
        enterNameTextField.nextKeyView = retypeSecurePasswordTextField
        addSubview(enterNameTextField)
        enterNameTextField.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 10).isActive = true
        enterNameTextField.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
        enterNameTextField.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
        
        addSubview(retypeSecurePasswordTextField)
        retypeSecurePasswordTextField.topAnchor.constraint(equalTo: enterNameTextField.bottomAnchor, constant: 10).isActive = true
        retypeSecurePasswordTextField.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
        retypeSecurePasswordTextField.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
        
        window?.makeFirstResponder(enterNameTextField)
        
        sender.defaultColor = NSColor.controlAccentColor.withAlphaComponent(0.4).cgColor
        sender.hoverColor = NSColor.controlAccentColor.withAlphaComponent(0.6)
        sender.selectedColor = NSColor.controlAccentColor
    }
    
    // Doing this so people can't modify executable
    // by reverse engineering
    
    // Sign IN
    private func `in`() {
        // Database
    }
    
    // Sign UP
    private func up() {
        
    }
}


import SwiftUI

struct AppKitPreview: NSViewRepresentable {
    let viewBuilder: () -> NSView
    
    init(_ viewBuilder: @escaping () -> NSView) {
        self.viewBuilder = viewBuilder
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {}
    
    func makeNSView(context: Context) -> some NSView {
        return viewBuilder()
    }
}

struct AppKitPreview_Previews: PreviewProvider {
    static var previews: some View {
        AppKitPreview {
            AXWelcomeView()
        }
    }
}
