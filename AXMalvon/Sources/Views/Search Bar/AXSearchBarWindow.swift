//
//  AXSearchBarWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-25.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

class AXSearchBarWindow: NSPanel, NSWindowDelegate {
    weak var appProperties: AXSessionProperties!
    lazy var searchBarView = AXSearchFieldPopoverView(appProperties: appProperties)
    
    private var localMouseDownEventMonitor: Any?
    private var isViewClosed = true
    
    init(appProperties: AXSessionProperties) {
        super.init(
            contentRect: .init(x: 0, y: 0, width: 600, height: 274),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.delegate = self
        self.appProperties = appProperties
        level = .mainMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false
        
        backgroundColor = .textBackgroundColor // NSWindow stuff
        
        self.contentView = searchBarView
    }
    
    func show() {
        guard isViewClosed else { self.close(); return }
        appProperties.containerView.alphaValue = 0.5
        
        self.setFrameOrigin(.init(x: appProperties.window.frame.midX - 300, y: appProperties.window.frame.midY - 137))
        
        appProperties.window.addChildWindow(self, ordered: .above)
        self.makeKeyAndOrderFront(nil)
        
        observer()
        
        _ = searchBarView.searchField.becomeFirstResponder()
    }
    
    func showCurrentURL() {
        // Implement this
        guard isViewClosed else { self.close(); return }
        appProperties.containerView.alphaValue = 0.5
        
        self.setFrameOrigin(.init(x: appProperties.window.frame.midX - 300, y: appProperties.window.frame.midY - 137))
        appProperties.window.addChildWindow(self, ordered: .above)
        self.makeKeyAndOrderFront(nil)
        
        searchBarView.newTabMode = false
        searchBarView.searchField.stringValue = appProperties.containerView.currentWebView?.url?.absoluteString ?? ""
        
        let range = NSRange(location: 0, length: searchBarView.searchField.stringValue.count)
        let editor = searchBarView.searchField.currentEditor()
        editor?.selectedRange = range
        
        observer()
        
        _ = searchBarView.searchField.becomeFirstResponder()
    }
    
    override func close() {
        isViewClosed = true
        searchBarView.windowClosed()
        
        appProperties.containerView.alphaValue = 1.0
        appProperties.window.removeChildWindow(self)
        removeMouseEventMonitor()
        
        super.close()
    }
    
    private func observer() {
        localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            if event.window != self && event.window == self?.appProperties.window {
                self?.close()
                return nil
            }
            return event
        }
    }
    
    private func removeMouseEventMonitor() {
        if let monitor = localMouseDownEventMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseDownEventMonitor = nil
        }
    }
}
