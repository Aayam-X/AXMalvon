//
//  AXNavigationGestureView.swift
//  AXMalvon
//
//  Created by Baba Paudel on 2024-11-10.
//

import Cocoa

private enum SwipeDirection {
    case backwards
    case forwards
    case reload
    case nothing
}

class AXNavigationGestureView: NSView {
    private var hasDrawn: Bool = false
    private var swipeColorValue: SwipeDirection?
    weak var appProperties: AXSessionProperties!
    
    private var scrollEventFinished: Bool = false
    var trackingArea: NSTrackingArea!
    
    lazy var swipeDirectionLabel: NSTextField = {
        let title = NSTextField()
        title.isEditable = false
        title.alignment = .center
        title.isBordered = false
        title.usesSingleLineMode = true
        title.drawsBackground = false
        title.translatesAutoresizingMaskIntoConstraints = false
        
        title.isHidden = true
        return title
    }()
    
    lazy var tabGroupSwapperView = AXTabGroupSwapperView()
    
    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        
        self.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.3).cgColor
        self.wantsLayer = true
        
        addSubview(swipeDirectionLabel)
        swipeDirectionLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        swipeDirectionLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        swipeDirectionLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        tabGroupSwapperView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tabGroupSwapperView)
        tabGroupSwapperView.leftAnchor.constraint(equalTo: leftAnchor, constant: 80).isActive = true
        tabGroupSwapperView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        tabGroupSwapperView.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
    }
    
    init(appProperties: AXSessionProperties) {
        self.appProperties = appProperties
        super.init(frame: .zero)
        setTrackingArea()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseEnteredAndExited]
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    
    override func scrollWheel(with event: NSEvent) {
        let x = event.deltaX
        let y = event.deltaY
        
        // Handle event phase
        switch event.phase {
        case .began:
            scrollEventFinished = false
        case .mayBegin:
            swipeDirectionLabel.stringValue = "Cancelled"
            print(event.phase.rawValue)
            return
        default:
            break
        }
        
        // Early return for small delta values or if the scroll event is finished
        guard abs(x) > 0.5 || abs(y) > 0.5, !scrollEventFinished else {
            return
        }
        
        
        // Handle X-axis scroll
        if x != 0 {
            swipeColorValue = x > 0 ? .backwards : .forwards
            swipeDirectionLabel.stringValue = x > 0 ? "Go Back" : "Go Forward"
        }
        
        // Handle Y-axis scroll
        if y != 0 {
            swipeColorValue = y > 0 ? .reload : .nothing
            swipeDirectionLabel.stringValue = y > 0 ? "Refresh" : ""
        }
    }
    
    
    override func mouseEntered(with event: NSEvent) {
        print("Mouse entered")
        swipeDirectionLabel.isHidden = false
    }
    
    override func mouseExited(with event: NSEvent) {
        print("Mouse exited")
        scrollEventFinished = true
        swipeDirectionLabel.stringValue = ""
        swipeDirectionLabel.isHidden = true
        appProperties.window.trafficLightManager.showButtons()
        
        switch swipeColorValue {
        case .backwards:
            goBack()
        case .forwards:
            goForward()
        case .reload:
            refresh()
        case .nothing, nil:
            break
        }
        
        swipeColorValue = nil
    }
    
    override func rightMouseDown(with event: NSEvent) {
        print("Hide sidebar")
        appProperties.window.toggleTabSidebar()
    }
    
    func goForward() {
        appProperties.containerView.currentWebView?.goForward()
    }
    
    func goBack() {
        appProperties.containerView.currentWebView?.goBack()
    }
    
    func refresh() {
        appProperties.containerView.currentWebView?.reload()
    }
}
