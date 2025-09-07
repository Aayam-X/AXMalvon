//
//  AXVerticalTabHostingView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXVerticalTabHostingView: NSView, AXTabHostingViewProtocol,
                                AXGestureViewDelegate, AXTabBarViewDelegate
{
    func tabBarSwitchedTo(_ tabButton: any AXTabButton) {
        tabHostingDelegate?.tabBarSwitchedTo(tabButton)
    }
    
    func tabBarShouldClose(_ tabButton: any AXTabButton) -> Bool {
        return tabHostingDelegate?.tabBarShouldClose(tabButton) ?? true
    }
    
    func tabBarDidClose(_ tabAt: Int) {
        tabHostingDelegate?.tabBarDidClose(tabAt)
    }
    
    internal var tabBarView: any AXTabBarViewTemplate
    weak var tabHostingDelegate: (any AXTabHostingViewDelegate)?

    var tabGroupInfoView: AXTabGroupInfoView
    internal var searchButton: AXSidebarSearchButton
    private var gestureView: AXGestureView
    
    // Swipe gesture properties
    private var userSwipedDirection: SwipeDirection?
    private var scrollEventFinished: Bool = false
    private var scrollWithMice: Bool = false
    private var trackingArea: NSTrackingArea?
    private var swipeAccumulator: CGFloat = 0
    private var isSwipeInProgress: Bool = false
    
    enum SwipeDirection {
        case left
        case right
    }
    
    // Tab group switching UI
    private lazy var tabGroupSwitchBanner: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        view.layer?.cornerRadius = 12
        view.layer?.shadowColor = NSColor.black.cgColor
        view.layer?.shadowOpacity = 0.2
        view.layer?.shadowOffset = CGSize(width: 0, height: 2)
        view.layer?.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alphaValue = 0
        return view
    }()
    
    private lazy var tabGroupNameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = NSColor.labelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var progressIndicator: CircularProgressView = {
        let indicator = CircularProgressView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var bottomLine: NSBox = {
        let line = NSBox()
        line.boxType = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        return line
    }()

    private lazy var addNewTabButton: NSButton = {
        let button = NSButton(
            image: NSImage(named: NSImage.addTemplateName)!, target: self,
            action: #selector(addNewTab))
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    private lazy var workspaceSwapperButton: NSButton = {
        let buttonImage = NSImage(
            systemSymbolName: "rectangle.stack", accessibilityDescription: nil)!
        let button = NSButton(
            image: buttonImage, target: self,
            action: #selector(showWorkspaceSwapper))
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    private lazy var helloWorldExtensionButton: NSButton = {
        let buttonImage = NSImage(
            systemSymbolName: "doc", accessibilityDescription: nil)!
        let button = NSButton(
            image: buttonImage, target: self,
            action: #selector(helloWorldExtensionButtonAction))
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    // This standalone view is needed for the NSWindow to access its delegate
    lazy var workspaceSwapperView: AXWorkspaceSwapperView = {
        return AXWorkspaceSwapperView()
    }()

    lazy var workspaceSwapperPopoverView: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .transient

        let controller = NSViewController()
        controller.view = workspaceSwapperView
        popover.contentViewController = controller

        return popover
    }()

    required init(
        tabBarView: any AXTabBarViewTemplate,
        searchButton: AXSidebarSearchButton,
        tabGroupInfoView: AXTabGroupInfoView
    ) {
        self.tabBarView = tabBarView
        self.tabGroupInfoView = tabGroupInfoView
        self.searchButton = searchButton
        self.gestureView = AXGestureView(
            tabGroupInfoView: tabGroupInfoView, searchButton: searchButton)
        
        super.init(frame: .zero)
        self.wantsLayer = true
        setupView()
        setupTrackingArea()
        setupTabGroupSwitchBanner()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        tabBarView.delegate = self
        gestureView.delegate = self
        tabGroupInfoView.onRightMouseDown = showTabGroupCustomizer

        gestureView.translatesAutoresizingMaskIntoConstraints = false
        tabBarView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(gestureView)
        addSubview(addNewTabButton)
        addSubview(workspaceSwapperButton)
        addSubview(helloWorldExtensionButton)
        addSubview(tabBarView)
        addSubview(bottomLine)

        gestureView.activateConstraints([
            .top: .view(self),
            .left: .view(self),
            .right: .view(self, constant: 2),
            .height: .constant(80),
        ])

        bottomLine.activateConstraints([
            .horizontalEdges: .view(self),
            .bottom: .view(gestureView, constant: 10),
            .height: .constant(2),
        ])

        // Tab Bar View
        tabBarView.activateConstraints([
            .left: .view(self),
            .right: .view(self, constant: -2),
            .top: .view(bottomLine, constant: 8),
            .bottom: .view(addNewTabButton, constant: -2),
        ])

        // Workspace Swapper Button
        workspaceSwapperButton.activateConstraints([
            .bottom: .view(self, constant: -9),
            .left: .view(self, constant: 10),
            .height: .constant(30),
            .width: .constant(30),
        ])

        // Workspace Swapper Button
        helloWorldExtensionButton.activateConstraints([
            .bottom: .view(self, constant: -9),
            .leftRight: .view(workspaceSwapperButton, constant: 2),
            .height: .constant(30),
            .width: .constant(30),
        ])

        // New Tab Button
        addNewTabButton.activateConstraints([
            .right: .view(self, constant: -10),
            .bottom: .view(self, constant: -9),
            .height: .constant(30),
            .width: .constant(30),
        ])
    }
    
    private func setupTabGroupSwitchBanner() {
        // Add banner to view hierarchy (above other views)
        addSubview(tabGroupSwitchBanner)
        tabGroupSwitchBanner.addSubview(progressIndicator)
        tabGroupSwitchBanner.addSubview(tabGroupNameLabel)
        
        // Position banner in the center
        NSLayoutConstraint.activate([
            tabGroupSwitchBanner.centerXAnchor.constraint(equalTo: centerXAnchor),
            tabGroupSwitchBanner.centerYAnchor.constraint(equalTo: centerYAnchor),
            tabGroupSwitchBanner.widthAnchor.constraint(equalToConstant: 180),
            tabGroupSwitchBanner.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Position progress indicator
        NSLayoutConstraint.activate([
            progressIndicator.leadingAnchor.constraint(equalTo: tabGroupSwitchBanner.leadingAnchor, constant: 12),
            progressIndicator.centerYAnchor.constraint(equalTo: tabGroupSwitchBanner.centerYAnchor),
            progressIndicator.widthAnchor.constraint(equalToConstant: 36),
            progressIndicator.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Position label
        NSLayoutConstraint.activate([
            tabGroupNameLabel.leadingAnchor.constraint(equalTo: progressIndicator.trailingAnchor, constant: 12),
            tabGroupNameLabel.trailingAnchor.constraint(equalTo: tabGroupSwitchBanner.trailingAnchor, constant: -12),
            tabGroupNameLabel.centerYAnchor.constraint(equalTo: tabGroupSwitchBanner.centerYAnchor)
        ])
    }
    
    // MARK: - Swipe Gesture Handling
    
    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [
            .activeAlways, .inVisibleRect, .mouseEnteredAndExited,
        ]
        trackingArea = NSTrackingArea(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // Remove old tracking area if it exists
        if let existingTrackingArea = trackingArea {
            self.removeTrackingArea(existingTrackingArea)
        }
        
        // Add new tracking area
        setupTrackingArea()
    }
    
    override func scrollWheel(with event: NSEvent) {
        handleScrollEvent(event)
        
        // Pass the event to subviews if needed
        super.scrollWheel(with: event)
    }
    
    private func handleScrollEvent(_ event: NSEvent) {
        let deltaX = event.deltaX
        
        // Update scroll event phase state
        switch event.phase {
        case .began:
            scrollEventFinished = false
            isSwipeInProgress = true
            swipeAccumulator = 0
        case .mayBegin:
            return  // Cancelled, exit early
        case .changed:
            // Continue accumulating swipe
            if isSwipeInProgress {
                swipeAccumulator += deltaX
                updateSwipeProgress()
            }
        case .ended where !scrollEventFinished,
            .ended where event.momentumPhase == .ended:
            handleSwipeEnd()
            return
        case .cancelled:
            cancelSwipe()
            return
        default:
            break
        }
        
        // Determine if scrolling is from a mouse
        scrollWithMice = event.phase == [] && event.momentumPhase == []
        
        // Handle horizontal scroll/swipe
        if deltaX != 0 && isSwipeInProgress {
            userSwipedDirection = deltaX > 0 ? .left : .right
            swipeAccumulator += deltaX
            updateSwipeProgress()
        }
    }
    
    private func updateSwipeProgress() {
        let threshold: CGFloat = 100.0 // Amount of swipe needed to trigger tab group switch
        let progress = min(abs(swipeAccumulator) / threshold, 1.0)
        
        // Update banner alpha based on progress
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            context.allowsImplicitAnimation = true
            
            // Show banner with increasing alpha
            tabGroupSwitchBanner.alphaValue = progress * 0.95
            
            // Update progress indicator
            progressIndicator.progress = progress
            
            // Update label based on direction
            if let direction = userSwipedDirection {
                switch direction {
                case .left:
                    tabGroupNameLabel.stringValue = "Previous Tab Group"
                case .right:
                    tabGroupNameLabel.stringValue = "Next Tab Group"
                }
            }
            
            // Scale effect for emphasis when getting close
            if progress > 0.8 {
                tabGroupSwitchBanner.layer?.transform = CATransform3DMakeScale(1.05, 1.05, 1.0)
            } else {
                tabGroupSwitchBanner.layer?.transform = CATransform3DIdentity
            }
        })
        
        // Trigger tab group switch when threshold is reached
        if progress >= 1.0 && !scrollEventFinished {
            triggerTabGroupSwitch()
        }
    }
    
    private func triggerTabGroupSwitch() {
        // Haptic feedback if available
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
        
        // Perform the switch
        if let direction = userSwipedDirection {
            switch direction {
            case .left:
                print("Switch to previous tab group")
            case .right:
                print("Switch to next tab group")
            }
            print("New tab group")
        }
        
        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.resetSwipeState()
        }
        
        scrollEventFinished = true
    }
    
    private func cancelSwipe() {
        resetSwipeState()
    }
    
    private func resetSwipeState() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            
            tabGroupSwitchBanner.alphaValue = 0
            tabGroupSwitchBanner.layer?.transform = CATransform3DIdentity
        })
        
        progressIndicator.progress = 0
        swipeAccumulator = 0
        isSwipeInProgress = false
        scrollEventFinished = false
        userSwipedDirection = nil
    }
    
    override func mouseExited(with event: NSEvent) {
        if scrollWithMice {
            handleSwipeEnd()
            scrollEventFinished = false
        }
    }
    
    private func handleSwipeEnd() {
        scrollEventFinished = true
        
        // If we haven't reached the threshold, cancel the swipe
        if abs(swipeAccumulator) < 100.0 {
            cancelSwipe()
        }
        
        userSwipedDirection = nil
    }

    // MARK: - Mouse Functions
    @objc
    func addNewTab() {
        tabHostingDelegate?.tabHostingViewCreatedNewTab()
    }

    @objc
    func showWorkspaceSwapper() {
        tabHostingDelegate?.tabHostingViewDisplaysWorkspaceSwapperPanel(
            workspaceSwapperButton)
    }

    var buttonPressCount: Int = 0
    var helloWorldExtension: CRXExtension?
    @objc
    func helloWorldExtensionButtonAction() {
        if let helloWorldExtension = helloWorldExtension {
            // NSPopover with AXWebView
            guard let popupURL = helloWorldExtension.popupURL else { return }

            let popover = NSPopover()
            popover.contentSize = NSSize(width: 400, height: 300)  // Adjust size as needed
            popover.behavior = .semitransient
            popover.contentViewController = ExtensionPopupController(
                popupURL: popupURL)

            // Show the popover
            popover.show(
                relativeTo: helloWorldExtensionButton.bounds,
                of: helloWorldExtensionButton, preferredEdge: .maxY)

            // FIXME: Next Steps, run the `popup.js` script.
        } else {
            helloWorldExtension = CRXExtension(extensionName: "Hello-World")
            print(helloWorldExtension?.manifest as Any)
        }

        class ExtensionPopupController: NSViewController {
            var webView: AXWebView!

            init(popupURL: URL) {
                super.init(nibName: nil, bundle: nil)
                self.webView = AXWebView(frame: .zero)
                self.webView.configuration.enableDefaultMalvonPreferences()
                self.webView.loadFileURL(
                    popupURL,
                    allowingReadAccessTo: popupURL.deletingLastPathComponent())
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            override func loadView() {
                self.view = webView
            }
        }
    }

    func showTabGroupCustomizer() {
        tabHostingDelegate?.tabHostingViewDisplaysTabGroupCustomizationPanel(
            tabGroupInfoView)
    }

    func gestureView(didSwipe direction: AXGestureViewSwipeDirection!) {
        switch direction {
        case .backwards:
            tabHostingDelegate?.tabHostingViewNavigateBackwards()
        case .forwards:
            tabHostingDelegate?.tabHostingViewNavigateForward()
        case .reload:
            tabHostingDelegate?.tabHostingViewReloadCurrentPage()
        case .nothing, nil:
            break
        }
    }
}

// MARK: - Circular Progress View
class CircularProgressView: NSView {
    var progress: CGFloat = 0 {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 4
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + (2 * CGFloat.pi * progress)
        
        // Draw background circle
        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(3)
        context.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
        context.strokePath()
        
        // Draw progress arc
        if progress > 0 {
            context.setStrokeColor(NSColor.controlAccentColor.cgColor)
            context.setLineWidth(3)
            context.setLineCap(.round)
            context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            context.strokePath()
        }
    }
}
