//
//  AXSidebarTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-11.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXSidebarTabButton: NSButton {
    let titleView = NSTextField(frame: .zero)
    
    var closeButton = AXHoverButton()
    
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    
    var titleObserver: NSKeyValueObservation?
    var urlObserver: NSKeyValueObservation?
    
    weak var titleViewRightAnchor: NSLayoutConstraint?
    
    var tryingToCreateNewWindow: Bool = false
    
    unowned var appProperties: AXAppProperties
    
    var isSelected: Bool = false {
        didSet {
            self.layer?.backgroundColor = isSelected ? selectedColor.cgColor : .clear
        }
    }
    
    var tabTitle: String = "Untitled" {
        didSet {
            titleView.stringValue = tabTitle
        }
    }
    
    var isMouseDown = false
    
    var trackingArea: NSTrackingArea!
    
    init(_ appProperties: AXAppProperties) {
        self.appProperties = appProperties
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        self.layer?.borderColor = .white
        title = ""
        
        self.setTrackingArea(WithDrag: false)
        
        // Setup closeButton
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.target = self
        closeButton.action = #selector(closeTab)
        addSubview(closeButton)
        closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)
        closeButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
        closeButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
        closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
        closeButton.isHidden = true
        
        // Setup titleView
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.isEditable = false // This should be set to true in a while :)
        titleView.alignment = .left
        titleView.isBordered = false
        titleView.usesSingleLineMode = true
        titleView.drawsBackground = false
        addSubview(titleView)
        titleView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        titleView.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
        titleViewRightAnchor = titleView.rightAnchor.constraint(equalTo: closeButton.leftAnchor, constant: 20)
        titleViewRightAnchor?.isActive = true
    }
    
    public func stopObserving() {
        titleObserver?.invalidate()
        urlObserver?.invalidate()
    }
    
    public func startObserving() {
        titleObserver = self.appProperties.tabs[tag].view.observe(\.title, changeHandler: { [self] _, _ in
            appProperties.tabs[tag].title = appProperties.tabs[tag].view.title ?? "Untitled"
            tabTitle = appProperties.tabs[tag].title ?? "Untitled"
        })
        
        urlObserver = self.appProperties.tabs[tag].view.observe(\.url, changeHandler: { [self] _, _ in
            appProperties.tabs[tag].url = appProperties.tabs[tag].view.url
        })
    }
    
    @objc func closeTab() {
        appProperties.tabManager.removeTab(self.tag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTrackingArea(WithDrag drag: Bool = false) {
        var options : NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .enabledDuringMouseDrag]
        if drag {
            options.insert(.enabledDuringMouseDrag)
        }
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseUp(with event: NSEvent) {
        NSCursor.arrow.set()
        self.isMouseDown = false
        self.removeTrackingArea(self.trackingArea)
        self.setTrackingArea(WithDrag: false)
        layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
        closeButton.isHidden = true
        
        if tryingToCreateNewWindow {
            let window = AXWindow(restoresTab: false)
            window.setFrameOrigin(.init(x: NSEvent.mouseLocation.x, y: NSEvent.mouseLocation.y))
            window.makeKeyAndOrderFront(nil)
            window.appProperties.tabs.append(appProperties.tabs[tag])
            appProperties.tabManager.tabMovedToNewWindow(tag)
            DispatchQueue.main.async {
                window.appProperties.tabManager.updateAll()
            }
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.removeTrackingArea(self.trackingArea)
        if self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds) {
            sendAction(action, to: target)
        }
        self.setTrackingArea(WithDrag: true)
        self.isMouseDown = true
        self.layer?.backgroundColor = selectedColor.cgColor
    }
    
    override func mouseEntered(with event: NSEvent) {
        titleViewRightAnchor?.constant = 0
        
        closeButton.isHidden = false
        
        if !isSelected {
            self.layer?.backgroundColor = self.isMouseDown ? selectedColor.cgColor : hoverColor.cgColor
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        titleViewRightAnchor?.constant = 20
        closeButton.isHidden = true
        self.layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
    }
    
    override func mouseDragged(with event: NSEvent) {
        NSCursor.closedHand.set()
        
        if event.locationInWindow.x <= appProperties.sidebarView.scrollView.frame.width && event.locationInWindow.x > 0.0 {
            // We gotta subtract cause we're using a FlippedView
            let index = Int((event.locationInWindow.y - appProperties.sidebarView.scrollView.frame.height) / -31)
            
            if index <= appProperties.sidebarView.stackView.arrangedSubviews.count - 1 && index >= 0 {
                appProperties.tabManager.swapAt(self.tag, index)
                
                if tryingToCreateNewWindow {
                    self.layer?.borderWidth = 0.0
                    tryingToCreateNewWindow = false
                    self.tabTitle = appProperties.tabs[tag].title ?? "Untitled"
                }
            } else {
                // Create new window if the index dragged on isn't valid
                tabTitle = "Create new window"
                
                self.layer?.borderWidth = 1.08
                tryingToCreateNewWindow = true
            }
        } else {
            // User wants to put in webView
            if event.locationInWindow.x >= appProperties.sidebarView.scrollView.frame.width && event.locationInWindow.x <= appProperties.sidebarView.scrollView.frame.width + appProperties.webContainerView.frame.width {
                // Other
                self.layer?.borderWidth = 0.0
                self.tabTitle = appProperties.tabs[tag].title ?? "Untitled"
                tryingToCreateNewWindow = false
                
                if tag + 1 < appProperties.tabs.count {
                    appProperties.webContainerView.splitView.addArrangedSubview(appProperties.tabs[tag + 1].view)
                    (appProperties.sidebarView.stackView.arrangedSubviews[tag + 1] as? AXSidebarTabButton)?.isSelected = true
                }
            } else {
                // Create new window
                tabTitle = "Create new window"
                
                self.layer?.borderWidth = 1.08
                tryingToCreateNewWindow = true
            }
        }
    }
}
