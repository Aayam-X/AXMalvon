//
//  AXSidebarDownloadButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-17.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

class AXSidebarDownloadButton: NSButton {
    weak var appProperties: AXSessionProperties!
    var downloadItem: AXDownloadItem!
    
    // Colors
    var hoverColor: NSColor = NSColor.lightGray.withAlphaComponent(0.3)
    var selectedColor: NSColor = NSColor.lightGray.withAlphaComponent(0.6)
    
    // Observers
    var estimatedTimeRemainingOberver: NSKeyValueObservation?
    var isFinishedObserver: NSKeyValueObservation?
    
    // Other
    var trackingArea: NSTrackingArea!
    weak var titleViewRightAnchor: NSLayoutConstraint?
    private var hasDrawn: Bool = false
    
    // Views
    var fileNameLabel: NSTextField = NSTextField()
    var fileIconImageView: NSImageView = NSImageView()
    var closeButton: AXHoverButton = AXHoverButton()
    var progressBar = NSProgressIndicator()
    
    var tabTitle: String = "Untitled" {
        didSet {
            fileNameLabel.stringValue = tabTitle
        }
    }
    
    deinit {
        estimatedTimeRemainingOberver?.invalidate()
        isFinishedObserver?.invalidate()
        estimatedTimeRemainingOberver = nil
        isFinishedObserver = nil
    }
    
    init(_ appProperties: AXSessionProperties, _ downloadItem: AXDownloadItem) {
        self.appProperties = appProperties
        self.downloadItem = downloadItem
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5.0
        self.isBordered = false
        self.bezelStyle = .shadowlessSquare
        self.title = ""
        self.layer?.backgroundColor = .clear
        self.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        
        self.setTrackingArea()
        
        // Setup imageView
        fileIconImageView.translatesAutoresizingMaskIntoConstraints = false
        fileIconImageView.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: nil)
        addSubview(fileIconImageView)
        fileIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        fileIconImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        fileIconImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        fileIconImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
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
        fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fileNameLabel.isEditable = false // This should be set to true in a while :)
        fileNameLabel.alignment = .left
        fileNameLabel.isBordered = false
        fileNameLabel.usesSingleLineMode = true
        fileNameLabel.drawsBackground = false
        fileNameLabel.lineBreakMode = .byTruncatingTail
        addSubview(fileNameLabel)
        fileNameLabel.leftAnchor.constraint(equalTo: fileIconImageView.rightAnchor, constant: 5).isActive = true
        fileNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        titleViewRightAnchor = fileNameLabel.rightAnchor.constraint(equalTo: closeButton.leftAnchor, constant: 5)
        titleViewRightAnchor!.isActive = true
        
        // Add progress bar
        progressBar.style = .bar
        progressBar.isIndeterminate = downloadItem.download.progress.isIndeterminate
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressBar)
        progressBar.controlSize = .small
        progressBar.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        progressBar.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        progressBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 5).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func closeTab() {
        self.removeFromSuperview()
    }
    
    func startObserving() {
        tabTitle = downloadItem.fileName
        
        progressBar.startAnimation(self)
        
        estimatedTimeRemainingOberver = downloadItem.download.progress.observe(\.fractionCompleted, options: .new, changeHandler: { [weak self] _, _ in
            self?.progressBar.isIndeterminate = false
            self?.progressBar.doubleValue = self!.downloadItem.download.progress.fractionCompleted * 100
        })
        
        isFinishedObserver = downloadItem.download.progress.observe(\.isFinished, changeHandler: { [weak self] _, _ in
            self?.stopObserving()
        })
    }
    
    func stopObserving() {
        estimatedTimeRemainingOberver?.invalidate()
        isFinishedObserver?.invalidate()
        
        estimatedTimeRemainingOberver = nil
        isFinishedObserver = nil
        
        if downloadItem.download.progress.isIndeterminate {
            progressBar.stopAnimation(nil)
        } else {
            progressBar.isHidden = true
        }
        
        fileIconImageView.image = NSWorkspace.shared.icon(forFile: downloadItem.url.relativePath)
    }
    
    func setTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .enabledDuringMouseDrag]
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseDown(with event: NSEvent) {
        self.layer?.backgroundColor = selectedColor.cgColor
    }
    
    override func mouseUp(with event: NSEvent) {
        self.layer?.backgroundColor = .none
        openFileButtonAction()
    }
    
    override func mouseEntered(with event: NSEvent) {
        titleViewRightAnchor?.constant = 0
        closeButton.isHidden = false
        
        self.layer?.backgroundColor = hoverColor.cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        titleViewRightAnchor?.constant = 20
        closeButton.isHidden = true
        self.layer?.backgroundColor = .none
    }
    
    @objc func openFileButtonAction() {
        if let location = URL(string: downloadItem.location) {
            NSWorkspace.shared.open(location)
        }
    }
}
