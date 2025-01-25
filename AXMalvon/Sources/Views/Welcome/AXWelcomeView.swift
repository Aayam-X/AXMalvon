//
//  AXWelcomeView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-28.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import Cocoa
import WebKit

class AXWelcomeView: NSView, NSTextFieldDelegate {
    private var hasDrawn: Bool = false
    private var signUpButtonClicked: Bool = false
    
    var welcomeToMalvonLabel: NSTextField = {
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
        label.delegate = self
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
        
        label.delegate = self
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
    
    var enterNameTextField: NSTextField = {
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
        button.action = #selector(displaySecondTextField)
        return button
    }()
    
    var errorLabel: NSTextField = {
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
        self.in()
    }
    
    func validateFields() -> Bool {
        if emailAddressTextField.stringValue.isEmpty || passwordTextField.stringValue.isEmpty {
            showError("Fields cannot be empty")
            return false
        }
        
        if !emailAddressTextField.stringValue.isValidEmail() {
            showError("Enter valid email address")
            return false
        }
        
        if passwordTextField.stringValue.count < 8 {
            showError("Password must be 8 or more characters long")
            return false
        }
        
        if !passwordTextField.stringValue.isValidPassword() {
            showError("Password must have an uppercase letter, a numbers and a special character")
            return false
        }
        
        return true
    }
    
    func validateFields2() -> Bool {
        if enterNameTextField.stringValue.isEmpty || retypeSecurePasswordTextField.stringValue.isEmpty {
            showError("Fields cannot be empty")
            return false
        }
        
        if enterNameTextField.stringValue.hasWhitespace() {
            showError("Names may not have space, wait next update")
            return false
        }
        
        if retypeSecurePasswordTextField.stringValue != passwordTextField.stringValue {
            showError("Passwords must match")
            return false
        }
        
        return true
    }
    
    private func showError(_ message: String, time: CGFloat = 3.0) {
        errorLabel.isHidden = false
        errorLabel.stringValue = message
        
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            self.errorLabel.isHidden = true
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        enterNameTextField.isHidden = true
        retypeSecurePasswordTextField.isHidden = true
        signUpButton.defaultColor = .none
        signUpButton.hoverColor = NSColor.lightGray.withAlphaComponent(0.3)
        signUpButton.selectedColor = NSColor.lightGray.withAlphaComponent(0.6)
        signUpButton.layer?.backgroundColor = .none
        
        signUpButton.action = #selector(displaySecondTextField(_:))
    }
    
    // Prevent reverse engineering
    // This is signUpButtonAction
    @objc func displaySecondTextField(_ sender: AXHoverButton) {
        enterNameTextField.isHidden = false
        retypeSecurePasswordTextField.isHidden = false
        
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
        
        sender.action = #selector(up)
    }
    
    // Doing this so people can't modify executable
    // by reverse engineering
    
    // Sign IN
    private func `in`() {
        // Database
        guard validateFields() else { return }
        
        let email = emailAddressTextField.stringValue
        guard let password = passwordTextField.stringValue.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            showError("Unknown error")
            return
        }
        let encryptedPassword = encrypt(string: password, key: email).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        // TODO: Security flaw, do not use HTTPS URL for password
        AXGlobalProperties.shared.userEmail = email
        AXGlobalProperties.shared.userPassword = encryptedPassword
        
        let url = URL(string: "https://axmalvon.web.app/?email=\(emailAddressTextField.stringValue)&password=\(encryptedPassword)")!
        
        let privateConfig = WKWebViewConfiguration()
        privateConfig.websiteDataStore = .nonPersistent()
        privateConfig.processPool = .init()
        let webView = WKWebView(frame: .zero, configuration: privateConfig)
        webView.load(URLRequest(url: url))
        
        addSubview(webView)
        webView.frame = .init(x: 0, y: 0, width: 0, height: 0)
        
        self.welcomeToMalvonLabel.stringValue = "Loading..."
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            
            do {
                let result = try await webView.evaluateJavaScript("document.getElementById('status').innerText")
                if (result as? String) == "success: false" {
                    AXGlobalProperties.shared.hasPaid = false
                    self.welcomeToMalvonLabel.stringValue = "Payment needed to use Malvon"
                    self.showError("You must pay for Malvon", time: 5.0)
                    
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    exit(1)
                } else if (result as? String) == "success: true" {
                    AXGlobalProperties.shared.hasPaid = true
                    self.window?.sheetParent?.endSheet(self.window!)
                } else {
                    self.showError("Error: \(result)", time: 6.0)
                }
            } catch {
                print("Error reading contents of web page: \(error.localizedDescription)")
            }
        }
        
        self.welcomeToMalvonLabel.stringValue = "Welcome to Malvon!"
    }
    
    // Sign Up
    @objc func up() {
        guard validateFields() else { return }
        guard validateFields2() else { return }
        
        let email = emailAddressTextField.stringValue
        let name = enterNameTextField.stringValue
        let password = passwordTextField.stringValue
        let encryptedPassword = encrypt(string: password, key: email).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        
        AXGlobalProperties.shared.userEmail = email
        AXGlobalProperties.shared.userPassword = encryptedPassword
        
        let url = URL(string: "https://axmalvon.web.app/?name=\(name)&email=\(emailAddressTextField.stringValue)&password=\(encryptedPassword)")!
        
        let privateConfig = WKWebViewConfiguration()
        privateConfig.websiteDataStore = .nonPersistent()
        privateConfig.processPool = .init()
        let webView = WKWebView(frame: .zero, configuration: privateConfig)
        webView.load(URLRequest(url: url))
        
        addSubview(webView)
        webView.frame = .init(x: 0, y: 0, width: 0, height: 0)
        
        self.welcomeToMalvonLabel.stringValue = "Loading..."
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            
            do {
                let result = try await webView.evaluateJavaScript("document.getElementById('status').innerText")
                self.welcomeToMalvonLabel.stringValue = "Welcome to Malvon!"
                
                if (result as? String) == "success: false" {
                    AXGlobalProperties.shared.hasPaid = false
                    self.welcomeToMalvonLabel.stringValue = "Payment needed to use Malvon"
                    self.showError("You must pay for Malvon", time: 5.0)
                    
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    exit(1)
                } else {
                    self.showError("Error: \(result)", time: 6.0)
                }
            } catch {
                print("Error reading contents of web page: \(error.localizedDescription)")
            }
        }
    }
}

fileprivate func encrypt(string: String, key: String) -> String {
    var characters = [Character](string)
    
    // Encrypt the characters
    for i in 0..<characters.count {
        let character = characters[i]
        let encryptionKey = (i + key.count) * key.count ^ string.count / ((key.count * string.count) - key.count)
        characters[i] = Character(UnicodeScalar((Int(character.unicodeScalars.first!.value) + encryptionKey))!)
    }
    
    return String(characters)
}

fileprivate func decrypt(string: String, key: String) -> String {
    var characters = [Character](string)
    
    // Encrypt the characters
    for i in 0..<characters.count {
        let character = characters[i]
        let encryptionKey = (i + key.count) * key.count ^ string.count / ((key.count * string.count) - key.count)
        characters[i] = Character(UnicodeScalar((Int(character.unicodeScalars.first!.value) - encryptionKey))!)
    }
    
    return String(characters)
}
