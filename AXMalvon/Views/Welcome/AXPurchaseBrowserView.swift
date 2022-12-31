//
//  AXPurchaseBrowserView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-29.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import Cocoa
import WebKit

class AXPurchaseBrowserView: NSView {
    lazy var welcomeToMalvonLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.stringValue = "Purchase Malvon+"
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 35, weight: .medium)
        return label
    }()
    
    lazy var reasonsToBuyLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.isSelectable = true
        label.alignment = .center
        label.stringValue = """
        At just $2.88, you will be given these astonishing and life changing features:
            - Something
            - Something
            - Something
            - And more...
        """
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    lazy var purchaseButton: AXHoverButton = {
        let button = AXHoverButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer?.borderColor = NSColor.textColor.withAlphaComponent(0.4).cgColor
        button.layer?.borderWidth = 1.0
        button.title = "Purchase"
        button.target = self
        button.action = #selector(purchaseAction)
        return button
    }()
    
    lazy var viewCompleteFeatureListButton: AXHoverButton = {
        let button = AXHoverButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer?.borderColor = NSColor.textColor.withAlphaComponent(0.4).cgColor
        button.layer?.borderWidth = 1.0
        button.title = "View complete feature list"
        button.target = self
        // button.action = #selector(enterAction)
        return button
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
            
            // MARK: Reasons to buy text view
            addSubview(reasonsToBuyLabel)
            reasonsToBuyLabel.topAnchor.constraint(equalTo: welcomeToMalvonLabel.bottomAnchor, constant: 50).isActive = true
            reasonsToBuyLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10.8).isActive = true
            reasonsToBuyLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10.8).isActive = true
            
            // MARK: Sign up button
            addSubview(purchaseButton)
            purchaseButton.topAnchor.constraint(equalTo: reasonsToBuyLabel.bottomAnchor, constant: 50).isActive = true
            purchaseButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            purchaseButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            purchaseButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            // MARK: View complete feature list button
            addSubview(viewCompleteFeatureListButton)
            viewCompleteFeatureListButton.topAnchor.constraint(equalTo: purchaseButton.bottomAnchor, constant: 5).isActive = true
            viewCompleteFeatureListButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            viewCompleteFeatureListButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            viewCompleteFeatureListButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -15).isActive = true
            
            hasDrawn = true
        }
    }
    
    @objc func viewFeatureList(_ sender: AXHoverButton) {
        // Add a link
    }
    
    @objc func purchaseAction(_ sender: AXHoverButton) {
        // Display a webview
        // TODO: Check if using AXWebView would be safe or not
        let webView = WKWebView()
        
        // Display a popover
        let window = NSWindow.create(styleMask: [.fullSizeContentView, .closable, .miniaturizable, .resizable], size: .init(width: 650, height: 500))
        window.contentView = webView
        self.window?.setContentSize(.init(width: 800, height: 600))
        self.window?.center()
        self.window?.beginSheet(window)
    }
}
