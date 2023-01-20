//
//  AXSidebarTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-11.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit

enum DraggingPositionState {
    case newWindow
    case newSplitView
    case addToSidebarView
    case reorder
}

fileprivate enum DraggingSide {
    case left
    case right
}

fileprivate let tempView: AXWebSplitViewAddItemView! = AXWebSplitViewAddItemView()

class AXSidebarTabButton: NSButton, NSDraggingSource, NSPasteboardWriting, NSPasteboardReading {
    weak var appProperties: AXAppProperties!
    var profile: AXBrowserProfile!
    
    // Subviews
    lazy var titleView: NSTextField! = NSTextField()
    lazy var favIconImageView: NSImageView! = NSImageView()
    lazy var closeButton: AXSidebarTabCloseButton! = AXSidebarTabCloseButton()
    
    // Drag and drop
    fileprivate var isDragging = false
    var dragItem: NSDraggingItem!
    var draggingState: DraggingPositionState! = .reorder
    fileprivate var draggingSide: DraggingSide! = .left
    
    // Colors
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    
    // Observers
    var titleObserver: NSKeyValueObservation?
    var urlObserver: NSKeyValueObservation?
    
    // Other
    weak var titleViewRightAnchor: NSLayoutConstraint?
    var trackingArea: NSTrackingArea!
    private var hasDrawn: Bool = false
    
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
    
    deinit {
        titleObserver?.invalidate()
        urlObserver?.invalidate()
        titleObserver = nil
        urlObserver = nil
    }
    
    init(_ appProperties: AXAppProperties, _ profile: AXBrowserProfile?) {
        self.profile = profile
        self.appProperties = appProperties
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        title = ""
        heightAnchor.constraint(equalToConstant: 30).isActive = true
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
        appProperties.tabManager.closeTab(self.tag)
    }
    
    public func stopObserving() {
        titleObserver?.invalidate()
        urlObserver?.invalidate()
        
        titleObserver = nil
        urlObserver = nil
    }
    
    public func startObserving() {
        let webView = profile.tabs[tag].view
        
        self.titleObserver = webView.observe(\.title, options: .new, changeHandler: { [weak self] _, _ in
            let title = webView.title ?? "Untitled"
            self?.profile.tabs[self!.tag].title = title
            self?.tabTitle = title
            
            Task { [weak self] in
                do {
                    let favIconURL = try await webView.getFavicon()
                    self?.favIconImageView.download(from: favIconURL)
                } catch {
                    self?.favIconImageView.image = NSImage(systemSymbolName: "square.fill", accessibilityDescription: nil)
                }
            }
            
            if self!.isSelected {
                if self!.profile.index == self!.appProperties.currentProfileIndex {
                    self?.appProperties.webContainerView.windowTitleLabel.stringValue = title
                    self?.window?.title = title
                }
            }
        })
        
        self.urlObserver = webView.observe(\.url, options: .new, changeHandler: { [weak self] _, _ in
            self?.profile.tabs[self!.tag].url = webView.url
        })
    }
    
    // MARK: - Mouse Functions
    
    func setTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .enabledDuringMouseDrag]
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseUp(with event: NSEvent) {
        layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
        
        isDragging = false
    }
    
    override func mouseDown(with event: NSEvent) {
        if self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds) {
            sendAction(action, to: target)
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
    }
    
    
    // MARK: - Drag and Drop
    
    override func mouseDragged(with event: NSEvent) {
        if !isDragging && !closeButton.mouseDown {
            dragItem = NSDraggingItem(pasteboardWriter: self)
            dragItem.setDraggingFrame(self.bounds, contents: self.toImage())
            let draggingSession = self.beginDraggingSession(with: [dragItem], event: event, source: self)
            draggingSession.animatesToStartingPositionsOnCancelOrFail = false
            
            closeButton.isHidden = false
            isDragging = true
            
            isHidden = true
        }
    }
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }
    
    func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        let offset = screenPoint - appProperties.window.frame.origin
        
        // Check if the user is hovering over the sidebar
        if appProperties.sidebarView.frame.contains(offset) {
            userMovedCursorRemovingSplitView()
            
            draggingState = .reorder
            
            let index = Int((offset.y - appProperties.sidebarView.tabView.frame.size.height - 44) / -31)
            if index <= appProperties.sidebarView.tabView.tabStackView.arrangedSubviews.count - 1 && index >= 0 {
                appProperties.tabManager.swapAt(self.tag, index)
            }
        } else {
            // Check if the user is hovering over the WebView
            if appProperties.webContainerView.frame.contains(offset) && profile.tabs.count != 1 {
                draggingState = .newSplitView
                inDragging_createSplitView(offsetX: offset.x)
            } else {
                // The user is hovering outside the application
                userMovedCursorRemovingSplitView()
                
                draggingState = .newWindow
            }
        }
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        self.isHidden = false
        
        switch draggingState {
        case .newWindow:
            moveTabToNewWindow()
            break
        case .newSplitView:
            createNewSplitView()
            break
        case .reorder:
            // Reorder is already done when the user is dragging the cursor
            break
        case .addToSidebarView:
            // Handled by sidebarview
            break
        case .none:
            break
        }
        
        isDragging = false
        dragItem = nil
        draggingState = nil
        draggingSide = nil
        closeButton.isHidden = false
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        isDragging = false
        dragItem = nil
        draggingState = nil
        draggingSide = nil
        closeButton.isHidden = false
    }
    
    // MARK: - Functions of Drag and Drop
    
    // The user is still dragging the view.
    private func inDragging_createSplitView(offsetX: CGFloat) {
        isHidden = false
        
        let betterOffset = offsetX - appProperties.sidebarWidth
        
        if profile.currentTab == self.tag {
            appProperties.sidebarView.tabView.updateCurrentTab(to: profile.previousTab)
        }
        
        tempView.frame.size.width = 200
        
        let position = appProperties.webContainerView.frame.size.width / 2
        
        // Calculate if left or right side.
        if betterOffset > position {
            draggingSide = .right
            appProperties.webContainerView.splitView.addArrangedSubview(tempView)
        } else {
            draggingSide = .left
            appProperties.webContainerView.splitView.insertArrangedSubview(tempView, at: 0)
        }
    }
    
    private func createNewSplitView() {
        tempView.removeFromSuperview()
        
        // Might need a better safe check..
        if profile.previousTab != -1 {
            let webView = profile.tabs[profile.previousTab].view
            let webView1 = appProperties.currentTab.view
            
            webView.isSplitView = true
            webView1.isSplitView = true
            
            webView.frame.size.width = appProperties.webContainerView.splitView.bounds.width / 2
            webView1.frame.size.width = appProperties.webContainerView.splitView.bounds.width / 2
            
            if draggingSide == .left {
                appProperties.webContainerView.splitView.insertArrangedSubview(webView, at: 0)
            } else {
                appProperties.webContainerView.splitView.addArrangedSubview(webView)
            }
            
            if let window = webView.window as? AXWindow {
                window.makeFirstResponder(webView)
            }
            
            webView.layer?.borderWidth = 1.0
        }
    }
    
    private func userMovedCursorRemovingSplitView() {
        isHidden = true
        tempView.removeFromSuperview()
        
        if profile.currentTab != self.tag {
            profile.currentTab = self.tag
            appProperties.webContainerView.update(view: appProperties.currentProfile.tabs[appProperties.currentProfile.currentTab].view)
        }
    }
    
    private func moveTabToNewWindow() {
        let window = AXWindow(restoresTab: false)
        window.appProperties.currentProfile.tabs.append(appProperties.currentProfile.tabs[tag])
        appProperties.tabManager.tabMovedToNewWindow(tag)
        
        DispatchQueue.main.async {
            // TODO: add self to stackview to prevent redrawing.
            window.appProperties.tabManager.updateAll()
        }
        
        self.removeFromSuperview()
        self.titleView = nil
        self.favIconImageView = nil
        self.closeButton = nil
        self.removeTrackingArea(trackingArea)
        self.dragItem = nil
        
        window.setFrameTopLeftPoint(.init(x: NSEvent.mouseLocation.x, y: NSEvent.mouseLocation.y))
        window.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - Pasteboard
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return [NSPasteboard.PasteboardType("com.aayamx.malvon.tabButton")]
    }
    
    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        // return "\(appProperties.window.windowNumber),\(self.tag)"
        return ""
    }
    
    static func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return [NSPasteboard.PasteboardType("com.aayamx.malvon.tabButton")]
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        super.init(frame: .zero)
        // if type == .init("com.aayamx.malvon.tabButton") {
        //  let value = propertyList as! String
        // }
    }
    
    static func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions {
        return .asString
    }
}
