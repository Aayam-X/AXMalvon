//
//  AXPreferenceView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-27.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

final class AXFlippedClipViewCentered: NSClipView {
    override var isFlipped: Bool {
        return true
    }
    
    // Center the views
    override func constrainBoundsRect(_ proposedBounds: NSRect) -> NSRect {
        var rect = super.constrainBoundsRect(proposedBounds)
        if let containerView = self.documentView {
            rect.origin.x = (containerView.frame.width - rect.width) / 2
        }
        
        return rect
    }
}

class AXPreferenceView: NSView {
    // Views
    lazy var settingPanes = [
        ("Account", "person.crop.circle", 0),
        ("General", "gearshape", 1),
        ("Search", "magnifyingglass", 2)
    ]
    
    lazy var windowTitleLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    let scrollView = NSScrollView()
    
    fileprivate let clipView = AXFlippedClipViewCentered()
    
    lazy var sidebarStackView: NSStackView = {
        let stackView = NSStackView()
        
        stackView.orientation = .vertical
        stackView.spacing = 5
        stackView.alignment = .left
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    let seperator = NSBox()
    
    let seperator2 = NSBox()
    
    // Other
    private var hasDrawn: Bool = false
    
    override func viewWillDraw() {
        if !hasDrawn {
            //            self.translatesAutoresizingMaskIntoConstraints = false
            
            // Add stackView
            addSubview(sidebarStackView)
            sidebarStackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            sidebarStackView.topAnchor.constraint(equalTo: topAnchor, constant: 55).isActive = true
            sidebarStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            sidebarStackView.widthAnchor.constraint(equalToConstant: 200).isActive = true
            
            setUpButtons()
            
            // Add seperator
            seperator.boxType = .separator
            seperator.translatesAutoresizingMaskIntoConstraints = false
            addSubview(seperator)
            seperator.leftAnchor.constraint(equalTo: sidebarStackView.rightAnchor).isActive = true
            seperator.topAnchor.constraint(equalTo: topAnchor).isActive = true
            seperator.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            // Add windowTitleLabel
            windowTitleLabel.stringValue = "General"
            addSubview(windowTitleLabel)
            windowTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true
            windowTitleLabel.leftAnchor.constraint(equalTo: seperator.rightAnchor, constant: 30).isActive = true
            
            // Add second seperator
            seperator2.boxType = .separator
            seperator2.translatesAutoresizingMaskIntoConstraints = false
            addSubview(seperator2)
            seperator2.leftAnchor.constraint(equalTo: seperator.rightAnchor).isActive = true
            seperator2.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            seperator2.topAnchor.constraint(equalTo: windowTitleLabel.bottomAnchor, constant: 15).isActive = true
            
            // Setup scrollview
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.automaticallyAdjustsContentInsets = false
            addSubview(scrollView)
            scrollView.drawsBackground = false
            scrollView.leftAnchor.constraint(equalTo: seperator.rightAnchor).isActive = true
            scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            scrollView.topAnchor.constraint(equalTo: windowTitleLabel.bottomAnchor, constant: 16).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            // Setup clipview
            clipView.translatesAutoresizingMaskIntoConstraints = false
            clipView.drawsBackground = false
            scrollView.contentView = clipView
            clipView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
            clipView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
            clipView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            clipView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
            
            let view = AXPreferenceGeneralView()
            scrollView.documentView = view
            
            hasDrawn = true
        }
    }
    
    func setUpButtons() {
        for pane in settingPanes {
            let button = AXPreferenceButton(title: pane.0, icon: pane.1, tag: pane.2)
            button.target = self
            button.action = #selector(buttonAction(_:))
            sidebarStackView.addArrangedSubview(button)
        }
        
        let firstButton = sidebarStackView.subviews[AXPreferenceGlobal.selectedTab] as! AXPreferenceButton
        firstButton.isSelected = true
    }
    
    @objc func buttonAction(_ sender: AXPreferenceButton) {
        let previousButton = sidebarStackView.subviews[AXPreferenceGlobal.selectedTab] as! AXPreferenceButton
        previousButton.isSelected = false
        
        AXPreferenceGlobal.selectedTab = sender.tag
        let currentButton = sidebarStackView.subviews[AXPreferenceGlobal.selectedTab] as! AXPreferenceButton
        self.windowTitleLabel.stringValue = currentButton.titleView.stringValue
        currentButton.isSelected = true
        
        switch sender.tag {
        case 0:
            let view = AXPreferenceAccountView()
            scrollView.documentView = view
        case 1:
            // General
            let view = AXPreferenceGeneralView()
            scrollView.documentView = view
        default:
            break
        }
    }
}
