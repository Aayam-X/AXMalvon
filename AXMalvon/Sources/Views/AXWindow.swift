//
//  AXWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

class AXWindow: NSWindow, NSWindowDelegate {
    var sessionProperties = AXSessionProperties()
    lazy var trafficLightManager = AXTrafficLightOverlayManager(window: self)
    let splitView = AXSplitView()
    
    init() {
        super.init(
            contentRect: sessionProperties.windowFrame,
            styleMask: [.closable, .titled, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        // Window Configurations
        self.titlebarAppearsTransparent = true
        trafficLightManager.updateTrafficLights()
        self.delegate = self
        backgroundColor = .textBackgroundColor // NSWindow has hidden NSVisualEffectView, to remove we must use this code
        isMovableByWindowBackground = true
        
        // Other Configurations
        sessionProperties.window = self
        
        splitView.addArrangedSubview(sessionProperties.sidebarView)
        splitView.addArrangedSubview(sessionProperties.containerView)
        
        self.contentView = splitView
        sessionProperties.sidebarView.frame.size.width = 180
    }
    
    func toggleTabSidebar() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25 // Adjust duration as needed
            context.allowsImplicitAnimation = true
            
            if splitView.subviews.count == 2 {
                splitView.arrangedSubviews[0].removeFromSuperview()
                trafficLightManager.hideTrafficLights(true)
            } else {
                splitView.insertArrangedSubview(sessionProperties.sidebarView, at: 0)
                trafficLightManager.hideTrafficLights(false)
            }
            
            splitView.layoutSubtreeIfNeeded()
        }
    }
    
    
    // MARK: Window Events
    func windowDidResize(_ notification: Notification) {
        trafficLightManager.updateTrafficLights()
    }
    
    override func mouseUp(with event: NSEvent) {
        // Double-click in title bar
        if event.clickCount >= 2 && isPointInTitleBar(point: event.locationInWindow) {
            self.zoom(nil)
        }
        super.mouseUp(with: event)
    }
    
    fileprivate func isPointInTitleBar(point: CGPoint) -> Bool {
        if let windowFrame = self.contentView?.frame {
            let titleBarRect = NSRect(x: self.contentLayoutRect.origin.x, y: self.contentLayoutRect.origin.y+self.contentLayoutRect.height, width: self.contentLayoutRect.width, height: windowFrame.height-self.contentLayoutRect.height)
            return titleBarRect.contains(point)
        }
        return false
    }
}

class AXSplitView: NSSplitView, NSSplitViewDelegate, CAAnimationDelegate {
    private var progress: CGFloat = 0.0
    
    var topBorderLayer: CAShapeLayer! = CAShapeLayer()
    var topPointPath: NSBezierPath! = NSBezierPath()
    var topAnimation: CABasicAnimation! = CABasicAnimation(keyPath: "strokeEnd")
    
    var rightBorderLayer: CAShapeLayer! = CAShapeLayer()
    var rightPointPath: NSBezierPath! = NSBezierPath()
    var rightAnimation: CABasicAnimation! = CABasicAnimation(keyPath: "strokeEnd")
    
    var bottomBorderLayer: CAShapeLayer! = CAShapeLayer()
    var bottomPointPath: NSBezierPath! = NSBezierPath()
    var bottomAnimation: CABasicAnimation! = CABasicAnimation(keyPath: "strokeEnd")
    
    var leftBorderLayer: CAShapeLayer! = CAShapeLayer()
    var leftPointPath: NSBezierPath! = NSBezierPath()
    var leftAnimation: CABasicAnimation! = CABasicAnimation(keyPath: "strokeEnd")
    
    init() {
        super.init(frame: .zero)
        
        delegate = self
        isVertical = true
        dividerStyle = .thin
        
        topBorderLayer.lineWidth = 9
        rightBorderLayer.lineWidth = 9
        bottomBorderLayer.lineWidth = 9
        leftBorderLayer.lineWidth = 9
        
        leftAnimation.delegate = self
        leftAnimation.isRemovedOnCompletion = true
        rightAnimation.isRemovedOnCompletion = true
        bottomAnimation.isRemovedOnCompletion = true
        topAnimation.isRemovedOnCompletion = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 160
    }
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 500
    }
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        //        removeLayers()
        return view.tag == 0x01 ? false : true
    }
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return false
    }
    
    func smoothProgress(_ newValue: CGFloat, increment by: CGFloat = 0.3) {
        if newValue - progress >= by {
            updateProgress(newValue, 0.3)
        }
    }
    
    func updateProgress(_ newValue: CGFloat, _ duration: CGFloat = 0.2) {
        let color = NSColor.textColor.withAlphaComponent(CGFloat.random(in: 0.5..<1.0)).cgColor
        
        // Top Point
        topPointPath.move(to: .init(x: 0, y: bounds.height))
        topPointPath.line(to: .init(x: bounds.width * newValue, y: self.bounds.height))
        
        // Right Point
        rightPointPath.move(to: .init(x: bounds.width, y: bounds.height))
        rightPointPath.line(to: .init(x: bounds.width, y: (bounds.height - (newValue) * bounds.height)))
        
        // Bottom Point
        bottomPointPath.move(to: .init(x: bounds.width, y: 0))
        bottomPointPath.line(to: .init(x: (bounds.width - (bounds.width * newValue)), y: 0))
        
        // Left Point
        leftPointPath.move(to: .zero)
        leftPointPath.line(to: .init(x: 0, y: bounds.height * newValue))
        
        topBorderLayer.path = topPointPath.cgPath
        topBorderLayer.strokeColor = color
        
        rightBorderLayer.path = rightPointPath.cgPath
        rightBorderLayer.strokeColor = color
        
        bottomBorderLayer.path = bottomPointPath.cgPath
        bottomBorderLayer.strokeColor = color
        
        leftBorderLayer.path = leftPointPath.cgPath
        leftBorderLayer.strokeColor = color
        
        layer?.addSublayer(topBorderLayer)
        layer?.addSublayer(rightBorderLayer)
        layer?.addSublayer(bottomBorderLayer)
        layer?.addSublayer(leftBorderLayer)
        
        topAnimation.fromValue = progress
        topAnimation.toValue = newValue
        topAnimation.duration = duration
        topBorderLayer.add(topAnimation, forKey: "ANIMATION:Progress:top")
        
        rightAnimation.fromValue = progress
        rightAnimation.toValue = newValue
        rightAnimation.duration = duration
        rightBorderLayer.add(rightAnimation, forKey: "ANIMATION:Progress:right")
        
        bottomAnimation.fromValue = progress
        bottomAnimation.toValue = newValue
        bottomAnimation.duration = duration
        bottomBorderLayer.add(bottomAnimation, forKey: "ANIMATION:Progress:bottom")
        
        leftAnimation.fromValue = progress
        leftAnimation.toValue = newValue
        leftAnimation.duration = duration
        leftBorderLayer.add(leftAnimation, forKey: "ANIMATION:Progress:left")
        
        progress = newValue
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if progress >= 0.93 {
            close()
        }
    }
    
    override func removeFromSuperview() {
        topBorderLayer = nil
        topPointPath = nil
        topAnimation = nil
        rightBorderLayer = nil
        rightPointPath = nil
        rightAnimation = nil
        bottomBorderLayer = nil
        bottomPointPath = nil
        bottomAnimation = nil
        leftBorderLayer = nil
        leftPointPath = nil
        leftAnimation = nil
        
        super.removeFromSuperview()
    }
    
    override func viewDidEndLiveResize() {
        topPointPath.removeAllPoints()
        rightPointPath.removeAllPoints()
        bottomPointPath.removeAllPoints()
        leftPointPath.removeAllPoints()
    }
    
    func close() {
        progress = 0.0
        topBorderLayer?.removeFromSuperlayer()
        rightBorderLayer?.removeFromSuperlayer()
        bottomBorderLayer?.removeFromSuperlayer()
        leftBorderLayer?.removeFromSuperlayer()
        
        topPointPath.removeAllPoints()
        rightPointPath.removeAllPoints()
        bottomPointPath.removeAllPoints()
        leftPointPath.removeAllPoints()
    }
}

extension AXWindow {
    // MARK: - Menu Bar Item Actions
    @IBAction func toggleSearchField(_ sender: Any) {
        sessionProperties.searchBarWindow.showCurrentURL()
    }
    
    @IBAction func closeWindow(_ sender: Any) {
        self.close()
    }
    
    @IBAction func createNewTab(_ sender: Any) {
        sessionProperties.searchBarWindow.show()
    }
    
    @IBAction func createNewWindow(_ sender: Any) {
        let window = AXWindow()
        
        // Create new window and create blank window
        //        window.sessionProperties.profiles.forEach { $0.retriveTabs() }
        
        window.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func closeTab(_ sender: Any) {
        sessionProperties.tabManager.currentTabGroup.removeTab()
    }
    
    @IBAction func showSidebar(_ sender: Any) {
        toggleTabSidebar()
    }
    
    override var acceptsFirstResponder: Bool {
        true
    }
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.keyCode {
            case 18: // '1' key
                switchToTab(index: 0)
            case 19: // '2' key
                switchToTab(index: 1)
            case 20: // '3' key
                switchToTab(index: 2)
            case 21: // '4' key
                switchToTab(index: 3)
            case 22: // '5' key
                switchToTab(index: 4)
            case 23: // '6' key
                switchToTab(index: 5)
            case 26: // '7' key
                switchToTab(index: 6)
            default:
                break
            }
        } else {
            super.keyDown(with: event)
        }
    }
    
    func switchToTab(index: Int) {
        // Check if the tab index is valid
        if index < sessionProperties.tabManager.currentTabGroup.tabs.count {
            // Hide all tabs
            sessionProperties.tabManager.currentTabGroup.switchTab(to: index)
        } else {
            guard sessionProperties.tabManager.currentTabGroup.tabs.count > 0 else { return }
            // Switch to the last tab if the index is out of range
            sessionProperties.tabManager.currentTabGroup.switchTab(to: sessionProperties.tabManager.currentTabGroup.tabs.count - 1)
        }
    }
}
