//
//  AXHorizontalTabButton.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-21.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

//class AXHorizontalTabButton: NSButton, AXTabButton {
//    unowned var tab: AXTab!
//    var delegate: (any AXTabButtonDelegate)?
//
//    private var closeButton = AXHorizontalTabCloseButton()
//    var titleView = NSTextField()
//    var trackingArea: NSTrackingArea!
//
//    var webTitle: String = "Untitled" {
//        didSet {
//            titleView.stringValue = webTitle
//        }
//    }
//
//    var favicon: NSImage? {
//        didSet {
//            closeButton.favicon = favicon
//        }
//    }
//
//    var isSelected: Bool = false {
//        didSet {
//            self.updateAppearance()
//
//            if isSelected, tab.titleObserver == nil {
//                forceCreateWebview()
//            }
//        }
//    }
//
//    required init(tab: AXTab!) {
//        self.tab = tab
//        super.init(frame: .zero)
//        self.translatesAutoresizingMaskIntoConstraints = false
//        self.isBordered = false
//        self.bezelStyle = .smallSquare
//        title = ""
//
//        self.wantsLayer = true
//        self.layer?.cornerRadius = 7
//        self.layer?.masksToBounds = false
//        setupShadow()
//        setupViews()
//        setupTrackingArea()
//
//        if let tab {
//            tab.onWebViewInitialization =
//                self.onWebViewInitializationListenerHandler
//        }
//
//        if tab?.titleObserver == nil {
//            titleView.stringValue = "New Tab"
//        }
//    }
//
//    func onWebViewInitializationListenerHandler(webView: AXWebView) {
//        mxPrint(#function, "CALLEDDDD")
//        self.createObserver(webView)
//    }
//
//    override func viewWillDraw() {
//        updateAppearance()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private func setupViews() {
//        self.heightAnchor.constraint(equalToConstant: 33).isActive = true
//
//        closeButton.translatesAutoresizingMaskIntoConstraints = false
//        closeButton.favicon =
//            tab?.icon
//            ?? NSImage(
//                systemSymbolName: "moon.fill", accessibilityDescription: nil)
//        addSubview(closeButton)
//
//        closeButton.activateConstraints([
//            .centerY: .view(self),
//            .left: .view(self, constant: 10),
//            .width: .constant(20),
//            .height: .constant(20),
//        ])
//        closeButton.target = self
//        closeButton.action = #selector(closeTab)
//
//        titleView.translatesAutoresizingMaskIntoConstraints = false
//        titleView.isEditable = false
//        titleView.isBordered = false
//        titleView.usesSingleLineMode = true
//        titleView.drawsBackground = false
//        titleView.lineBreakMode = .byTruncatingTail
//        titleView.textColor = .textColor
//        addSubview(titleView)
//
//        titleView.activateConstraints([
//            .leftRight: .view(closeButton, constant: 5),
//            .centerY: .view(self),
//            .right: .view(self, constant: -7),
//        ])
//    }
//
//    @objc
//    func closeTab() {
//        tab?.stopAllObservations()
//        delegate?.tabButtonWillClose(self)
//    }
//
//    // This would be called directly from a button click
//    @objc
//    func switchTab() {
//        delegate?.tabButtonDidSelect(self)
//    }
//
//    private func setupTrackingArea() {
//        let options: NSTrackingArea.Options = [
//            .activeAlways, .inVisibleRect, .mouseEnteredAndExited,
//        ]
//        trackingArea = NSTrackingArea(
//            rect: self.bounds, options: options, owner: self, userInfo: nil)
//        self.addTrackingArea(trackingArea)
//    }
//
//    override func mouseDown(with event: NSEvent) {
//        closeButton.hideCloseButton()
//        NSAnimationContext.runAnimationGroup { context in
//            context.duration = 0.1
//            self.animator().layer?.setAffineTransform(
//                CGAffineTransform(scaleX: 1, y: 0.95))
//        }
//
//        self.switchTab()
//        isSelected = true
//    }
//
//    override func mouseUp(with event: NSEvent) {
//        NSAnimationContext.runAnimationGroup { context in
//            context.duration = 0.1
//            self.animator().layer?.setAffineTransform(.identity)
//        }
//    }
//
//    override func mouseEntered(with event: NSEvent) {
//        if !isSelected {
//            self.layer?.backgroundColor =
//                NSColor.systemGray.withAlphaComponent(0.3).cgColor
//        }
//        closeButton.showCloseButton()
//    }
//
//    override func mouseExited(with event: NSEvent) {
//        closeButton.hideCloseButton()
//        updateAppearance()
//    }
//
//    private func updateAppearance() {
//        let backgroundColor: CGColor
//        if isSelected {
//            if effectiveAppearance.name == .vibrantDark
//                || effectiveAppearance.name == .darkAqua
//            {
//                backgroundColor = .black
//                layer?.shadowColor = .white
//            } else {
//                backgroundColor = .white
//                layer?.shadowColor = .black
//            }
//            layer?.shadowOpacity = 0.3
//        } else {
//            backgroundColor = .clear
//            layer?.shadowOpacity = 0.0
//        }
//
//        self.layer?.backgroundColor = backgroundColor
//    }
//
//    private func setupShadow() {
//        layer?.shadowColor = NSColor.textColor.cgColor
//        layer?.shadowOpacity = 0.0
//        layer?.shadowRadius = 4.0
//        layer?.shadowOffset = CGSize(width: 0, height: 0)
//    }
//}
//
//// MARK: - Close Button + Favicon
//class AXHorizontalTabCloseButton: NSButton {
//    // swiftlint:disable:next identifier_name
//    var _favicon: NSImage?
//
//    var favicon: NSImage? {
//        get {
//            return _favicon
//        }
//        set {
//            self._favicon = newValue
//            self.image =
//                newValue ?? AXTabButtonConstants.defaultFavicon
//        }
//    }
//
//    init(isSelected: Bool = false) {
//        super.init(frame: .zero)
//        self.isBordered = false
//        self.bezelStyle = .smallSquare
//
//        self.imagePosition = .imageOnly
//        self.image = AXTabButtonConstants.defaultFavicon
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func showCloseButton() {
//        self.image = AXTabButtonConstants.defaultCloseButton
//    }
//
//    func hideCloseButton() {
//        self.image = _favicon
//    }
//}
