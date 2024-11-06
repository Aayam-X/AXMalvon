//
//  AXWebContainerView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import AppKit

class AXWebContainerView: NSView {
    weak var appProperties: AXSessionProperties!
    private var hasDrawn: Bool = false
    weak var currentWebView: AXWebView?
    
    private lazy var splitView = AXWebContainerSplitView()
    
    var websiteTitleLabel: NSTextField = {
        let title = NSTextField()
        title.isEditable = false
        title.alignment = .left
        title.isBordered = false
        title.usesSingleLineMode = true
        title.drawsBackground = false
        title.alphaValue = 0.3
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
    
    lazy var testButton: AXButton = {
        let button = AXButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.target = self
        button.action = #selector(testButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        
        addSubview(websiteTitleLabel)
        websiteTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: -0.5).isActive = true
        websiteTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        websiteTitleLabel.stringValue = "Testing"
        
        addSubview(testButton)
        testButton.topAnchor.constraint(equalTo: topAnchor, constant: -0.5).isActive = true
        testButton.leftAnchor.constraint(equalTo: websiteTitleLabel.rightAnchor).isActive = true
        
        splitView.frame = bounds.insetBy(dx: 14, dy: 14)
        addSubview(splitView)
        splitView.autoresizingMask = [.height, .width]
    }
    
    init(appProperties: AXSessionProperties) {
        self.appProperties = appProperties
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateView(webView: AXWebView) {
        currentWebView?.removeFromSuperview()
        
        self.currentWebView = webView
        splitView.addArrangedSubview(webView)
    }
    
    @objc func testButtonAction() {
//        appProperties.tabManager.createNewTab(from: "https://www.apple.com/ca")
//        appProperties.tabManager.switchTab(to: 0)
        appProperties.searchBarWindow.show()
    }
    
    
}

fileprivate class AXWebContainerSplitView: NSSplitView, NSSplitViewDelegate {
    init() {
        super.init(frame: .zero)
        delegate = self
        isVertical = true
        dividerStyle = .thin
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 50
    }
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }
    
    override func drawDivider(in rect: NSRect) {
        // Make divider invisble
    }
    
    override func viewWillDraw() {
        self.layer?.cornerRadius = 5.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
