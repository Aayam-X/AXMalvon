//
//  AXProfileListView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-01.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import Cocoa

class AXProfileListView: NSView {
    weak var appProperties: AXAppProperties!
    
    let scrollView = NSScrollView()
    let clipView = AXFlippedClipViewCentered()
    let stackView = NSStackView()
    
    init(_ appProperties: AXAppProperties!) {
        self.appProperties = appProperties
        super.init(frame: .zero)
        
        if !appProperties.isPrivate {
            // Add scrollView
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.drawsBackground = false
            addSubview(scrollView)
            scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            // Add clipView
            clipView.translatesAutoresizingMaskIntoConstraints = false
            clipView.drawsBackground = false
            scrollView.contentView = clipView
            clipView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
            clipView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
            clipView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
            clipView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
            
            // Add stackView
            scrollView.documentView = stackView
            stackView.translatesAutoresizingMaskIntoConstraints = false
            addProfileButtons()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addProfileButtons() {
        for (index, profile) in AXGlobalProperties.shared.profiles.enumerated() {
            let item = AXHoverButton()
            item.translatesAutoresizingMaskIntoConstraints = false
            item.heightAnchor.constraint(equalToConstant: 30).isActive = true
            item.widthAnchor.constraint(equalToConstant: 35).isActive = true
            item.image = NSImage(systemSymbolName: profile.icon, accessibilityDescription: nil)
            item.toolTip = profile.name
            item.target = self
            item.tag = index
            stackView.addArrangedSubview(item)
            item.action = #selector(buttonClickAction(_:))
        }
        
        let profile = AXGlobalProperties.shared.profiles[appProperties.currentProfileIndex]
        (stackView.arrangedSubviews[appProperties.currentProfileIndex] as! AXHoverButton).image = NSImage(systemSymbolName: "\(profile.icon).fill", accessibilityDescription: nil)
    }
    
    @objc func buttonClickAction(_ sender: AXHoverButton) {
        // Forced because view wouldn't be shown on private windows
        appProperties.sidebarView.switchProfileFromButtonClick(sender.tag)
        appProperties.profileManager!.switchProfiles(to: sender.tag)
    }
    
    func updateSelection(from: Int, to: Int) {
        let fromProfile = AXGlobalProperties.shared.profiles[from]
        let toProfile = AXGlobalProperties.shared.profiles[to]
        
        (stackView.arrangedSubviews[from] as! AXHoverButton).image = NSImage(systemSymbolName: fromProfile.icon, accessibilityDescription: nil)
        (stackView.arrangedSubviews[to] as! AXHoverButton).image = NSImage(systemSymbolName: "\(toProfile.icon).fill", accessibilityDescription: nil)
    }
}
