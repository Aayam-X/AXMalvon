//
//  AXSidebarDownloadButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-17.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXSidebarDownloadButton: NSButton {
    let titleView = NSTextField(frame: .zero)
    
    var closeButton = AXHoverButton()
    var progressBar = NSProgressIndicator()
    
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    
    var downloadItem: AXDownloadItem!
    var estimatedTimeRemainingObserver: NSKeyValueObservation?
    var isFinishedObserver: NSKeyValueObservation?
    
    weak var titleViewWidthAnchor: NSLayoutConstraint?
    
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
    
    var trackingArea : NSTrackingArea!
    
    init(_ appProperties: AXAppProperties) {
        self.appProperties = appProperties
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        self.layer?.borderColor = .white
        self.target = self
        self.action = #selector(openInFinder)
        title = ""
        
        self.setTrackingArea(WithDrag: false)
        
        // Setup circular progress bar
        progressBar.style = .spinning
        progressBar.isIndeterminate = false
        progressBar.minValue = 0
        progressBar.maxValue = 100
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressBar)
        progressBar.controlSize = .small
        progressBar.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        progressBar.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
        
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
        titleView.leftAnchor.constraint(equalTo: progressBar.rightAnchor, constant: 5).isActive = true
        titleView.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
        titleView.rightAnchor.constraint(equalTo: closeButton.leftAnchor).isActive = true
    }
    
    func startObserving() {
        tabTitle = downloadItem.fileName
        
        estimatedTimeRemainingObserver = downloadItem.download.progress.observe(\.fractionCompleted) { [self] _, _ in
            progressBar.doubleValue = downloadItem.download.progress.fractionCompleted * 100
        }
        
        isFinishedObserver = downloadItem.download.progress.observe(\.isFinished) { [self] _, _ in
            stopObserving()
        }
    }
    
    func stopObserving() {
        estimatedTimeRemainingObserver?.invalidate()
        isFinishedObserver?.invalidate()
        progressBar.removeFromSuperview()
        
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = NSWorkspace.shared.icon(forFile: downloadItem.location.relativePath)
        addSubview(imageView)
        imageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        imageView.topAnchor.constraint(equalTo: topAnchor, constant: 7).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        titleView.leftAnchor.constraint(equalTo: imageView.rightAnchor, constant: 5.0).isActive = true
    }
    
    // Opens the file in finder
    @objc func openInFinder() {
        NSWorkspace.shared.open(downloadItem.location)
    }
    
    @objc func closeTab() {
        // TODO:::::
        //        appProperties.tabManager.removeTab(self.tag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTrackingArea(WithDrag drag: Bool = false) {
        var options : NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited]
        if drag {
            options.insert(.enabledDuringMouseDrag)
        }
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.isMouseDown = false
        closeButton.isHidden = true
        self.removeTrackingArea(self.trackingArea)
        self.setTrackingArea(WithDrag: false)
        layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
        
        if self.isMousePoint(self.convert(event.locationInWindow, from: nil), in: self.bounds) {
            sendAction(action, to: target)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.removeTrackingArea(self.trackingArea)
        self.setTrackingArea(WithDrag: true)
        self.isMouseDown = true
        self.layer?.backgroundColor = selectedColor.cgColor
    }
    
    override func mouseEntered(with event: NSEvent) {
        titleViewWidthAnchor?.constant = 0
        
        closeButton.isHidden = false
        
        if !isSelected {
            self.layer?.backgroundColor = self.isMouseDown ? selectedColor.cgColor : hoverColor.cgColor
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        titleViewWidthAnchor?.constant = 20
        closeButton.isHidden = true
        self.layer?.backgroundColor = isSelected ? selectedColor.cgColor : .none
    }
}
