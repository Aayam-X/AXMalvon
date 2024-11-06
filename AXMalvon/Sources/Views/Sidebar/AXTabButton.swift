//
//  AXTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-06.
//

import AppKit

class AXTabButton: NSButton {
    var tabGroup: AXTabGroup
    
    // Subviews
    var titleView: NSTextField! = NSTextField()
    var favIconImageView: NSImageView! = NSImageView()
    var closeButton: AXSidebarTabCloseButton! = AXSidebarTabCloseButton()
    
    // Colors
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    
    // Observers
    var titleObserver: NSKeyValueObservation?
    
    // Other
    weak var titleViewRightAnchor: NSLayoutConstraint?
    weak var heightConstraint: NSLayoutConstraint?
    var trackingArea: NSTrackingArea!
    private var hasDrawn: Bool = false
    
    var isSelected: Bool = false {
        didSet {
            self.layer?.backgroundColor = isSelected ? selectedColor.cgColor : .clear
        }
    }
    
    var hasCustomTitle = false
    var userDoubleClicked = false
    
    var tabTitle: String = "Untitled" {
        didSet {
            if !hasCustomTitle {
                titleView.stringValue = tabTitle
            }
        }
    }
    
    var webTitle: String = "Untitled" {
        didSet {
            tabTitle = webTitle
        }
    }
    
    deinit {
        titleObserver?.invalidate()
//        urlObserver?.invalidate()
        titleObserver = nil
//        urlObserver = nil
    }
    
    init(tabGroup: AXTabGroup) {
        self.tabGroup = tabGroup
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        title = ""
        self.heightConstraint = heightAnchor.constraint(equalToConstant: 30)
        heightConstraint!.isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDraw() {
        if !hasDrawn {
            // Setup trackingArea
            self.setTrackingArea()
            
            // Setup imageView
            favIconImageView.translatesAutoresizingMaskIntoConstraints = false
            favIconImageView.image = NSImage(systemSymbolName: "square.fill", accessibilityDescription: nil)
            favIconImageView.contentTintColor = .textBackgroundColor.withAlphaComponent(0.2)
            addSubview(favIconImageView)
            favIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            favIconImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
            favIconImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
            favIconImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
            
            // Setup closeButton
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.target = self
            closeButton.action = #selector(closeTab)
            addSubview(closeButton)
            closeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)
            closeButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
            closeButton.heightAnchor.constraint(equalToConstant: 16).isActive = true
            closeButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            closeButton.isHidden = true
            
            // Setup titleView
            titleView.translatesAutoresizingMaskIntoConstraints = false
            titleView.isEditable = false // This should be set to true in a while :)
            titleView.alignment = .left
            titleView.isBordered = false
            titleView.usesSingleLineMode = true
            titleView.drawsBackground = false
            titleView.lineBreakMode = .byTruncatingTail
            addSubview(titleView)
            titleView.leftAnchor.constraint(equalTo: favIconImageView.rightAnchor, constant: 5).isActive = true
            titleView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            titleViewRightAnchor = titleView.rightAnchor.constraint(equalTo: closeButton.leftAnchor, constant: 5)
            titleViewRightAnchor?.isActive = true
            
            hasDrawn = true
        }
    }
    
    @objc func closeTab() {
        stopObserving()
//        appProperties.tabManager.closeTab(self.tag)
    }
    
    public func stopObserving() {
        titleObserver?.invalidate()
        
        titleObserver = nil
    }
    
    public func startObserving() {
        let webView = tabGroup.tabs[self.tag].webView
        
        self.titleObserver = webView.observe(\.title, options: .new, changeHandler: { [weak self] _, _ in
            let title = webView.title ?? "Untitled"
            self?.tabGroup.updateTitle(fromTab: self!.tag, to: title)
            
            self?.webTitle = title
        })
    }
    
    // MARK: - Mouse Functions
    
    func setTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .enabledDuringMouseDrag]
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseDown(with event: NSEvent) {
        
        // I had the code here, but don't know what it was for: self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds)
        
        if event.clickCount == 1 {
            sendAction(action, to: target)
            self.isSelected = true
        } else if event.clickCount == 2 {
            // Edit the title.
            print("Double click")
            
            userDoubleClicked = true
            titleView.isEditable = true
            titleView.placeholderString = titleView.stringValue
            window?.makeFirstResponder(titleView)
        }
        self.layer?.backgroundColor = selectedColor.cgColor
    }
    
    override func mouseEntered(with event: NSEvent) {
        titleViewRightAnchor?.constant = 0
        closeButton.isHidden = false
        
        if !isSelected {
            self.layer?.backgroundColor = hoverColor.cgColor
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        titleViewRightAnchor?.constant = 20
        closeButton.isHidden = true
        self.layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
        
        if userDoubleClicked {
            if titleView.stringValue.isEmpty || titleView.stringValue == titleView.placeholderString {
                hasCustomTitle = false
                titleView.stringValue = webTitle
            } else {
                hasCustomTitle = true
            }
            
            titleView.currentEditor()?.selectedRange = .init(location: -1, length: 0)
            titleView.isEditable = false
            userDoubleClicked = false
        }
    }
}

class AXSidebarTabCloseButton: NSButton {
    var trackingArea: NSTrackingArea!
    
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    var defaultColor: CGColor? = .none
    var mouseDown: Bool = false
    
    init(isSelected: Bool = false) {
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        self.setTrackingArea()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseUp(with event: NSEvent) {
        mouseDown = false
        if self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds) {
            sendAction(action, to: target)
        }
        
        layer?.backgroundColor = defaultColor
    }
    
    override func mouseDown(with event: NSEvent) {
        mouseDown = true
        self.layer?.backgroundColor = hoverColor.cgColor
    }
    
    override func mouseEntered(with event: NSEvent) {
        if isEnabled {
            self.layer?.backgroundColor = hoverColor.cgColor
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        mouseDown = false
    }
    
    override func mouseExited(with event: NSEvent) {
        self.layer?.backgroundColor = defaultColor
    }
}
