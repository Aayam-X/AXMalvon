//
//  AXContentView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXContentView: NSView {
    weak var appProperties: AXAppProperties!
    
    fileprivate var hasDrawn = false
    
    var isAnimating: Bool = false
    
    var sidebarTrackingArea: NSTrackingArea!
    
    let supportedDraggingTypes: [NSPasteboard.PasteboardType] = [.URL, .init("com.aayamx.malvon.tabButton")]
    
    override func viewWillDraw() {
        if !hasDrawn {
            sidebarTrackingArea = NSTrackingArea(rect: .init(x: bounds.origin.x - 100, y: bounds.origin.y, width: 101, height: bounds.size.height), options: [.activeAlways, .mouseMoved], owner: self)
            addTrackingArea(sidebarTrackingArea)
            self.registerForDraggedTypes(supportedDraggingTypes)
            
            if appProperties.isPrivate {
                self.layer?.backgroundColor = .black
            } else {
                // Create NSVisualEffectView
                let visualEffectView = NSVisualEffectView()
                visualEffectView.material = .popover
                visualEffectView.blendingMode = .behindWindow
                visualEffectView.state = .followsWindowActiveState
                
                visualEffectView.frame = bounds
                addSubview(visualEffectView)
                visualEffectView.autoresizingMask = [.height, .width]
            }
            
            // Setup progress bar
            appProperties.progressBar.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(appProperties.progressBar)
            appProperties.progressBar.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
            appProperties.progressBar.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            appProperties.progressBar.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            appProperties.progressBar.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            // To not have it collapsed at the start
            appProperties.sidebarView.frame.size.width = appProperties.sidebarWidth
            
            // Show/hide the sidebar
            if appProperties.sidebarToggled {
                appProperties.splitView.addArrangedSubview(appProperties.sidebarView)
            }
            
            appProperties.splitView.addArrangedSubview(appProperties.webContainerView)
            
            appProperties.splitView.frame = bounds
            addSubview(appProperties.splitView)
            appProperties.splitView.autoresizingMask = [.height, .width]
            
            // Create a tab if there are no tabs
            if appProperties.tabs.isEmpty {
                appProperties.tabManager.createNewTab()
            } else {
                appProperties.tabManager.updateAll()
            }
            
            appProperties.sidebarView.wantsLayer = true
            
            hasDrawn = true
        }
    }
    
    override func mouseMoved(with event: NSEvent) {
        if !appProperties.sidebarToggled && appProperties.sidebarView.superview == nil {
            sidebarHover()
        }
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if !appProperties.sidebarToggled && appProperties.sidebarView.superview == nil {
            sidebarHover()
        }
        
        return .generic
    }
    
    func sidebarHover() {
        appProperties.sidebarView.setFrameSize(.init(width: appProperties.sidebarWidth, height: bounds.height))
        appProperties.sidebarView.setFrameOrigin(.init(x: -appProperties.sidebarWidth, y: 0))
        addSubview(appProperties.sidebarView)
        appProperties.sidebarView.autoresizingMask = [.height]
        appProperties.sidebarView.layer?.backgroundColor = NSColor.systemGray.cgColor
        
        if !isAnimating {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.1
                appProperties.sidebarView.animator().frame.origin.x = 0
                isAnimating = true
            }, completionHandler: {
                self.isAnimating = false
            })
        }
        
        self.appProperties.window.hideTrafficLights(false)
    }
    
    override func viewDidEndLiveResize() {
        removeTrackingArea(sidebarTrackingArea)
        sidebarTrackingArea = NSTrackingArea(rect: .init(x: 0, y: 0, width: 5, height: bounds.height), options: [.activeAlways, .mouseMoved], owner: self)
        addTrackingArea(sidebarTrackingArea)
    }
    
    // Show a searchbar popover
    func displaySearchBarPopover() {
        appProperties.searchFieldShown = true
        appProperties.popOver.show()
    }
    
    func showSearchBar() {
        if !appProperties.searchFieldShown {
            appProperties.searchFieldShown = true
            appProperties.popOver.show()
            appProperties.popOver.searchField.stringValue = appProperties.tabs[appProperties.currentTab].view.url?.absoluteString ?? ""
        } else {
            appProperties.popOver.close()
        }
    }
    
    func displayMessage(message: String) {
        let alert = AXInformationAlertView(frame: .zero)
        alert.message = message
        
        alert.translatesAutoresizingMaskIntoConstraints = false
        addSubview(alert)
        
        alert.topAnchor.constraint(equalTo: topAnchor).isActive = true
        alert.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            alert.removeFromSuperview()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command, .shift] {
            if event.characters == "c" {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(appProperties.tabs[appProperties.currentTab].view.url?.absoluteString ?? "Malvon: Unable to copy link", forType: .string)
                displayMessage(message: "Copied Link!")
                return
            }
        } else if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command {
            switch event.characters {
            case "1": // There is always going to be one tab, so no checking
                appProperties.tabManager.switch(to: 0)
            case "2" where 2 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 1)
            case "3" where 3 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 2)
            case "4" where 4 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 3)
            case "5" where 5 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 4)
            case "6" where 6 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 5)
            case "7" where 7 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 6)
            case "8" where 8 <= appProperties.tabs.count:
                appProperties.tabManager.switch(to: 7)
            case "9":
                appProperties.tabManager.switch(to: appProperties.tabs.count - 1)
            case "r":
                appProperties.sidebarView.reloadButtonAction()
            default:
                super.keyDown(with: event)
            }
            return
        }
        
        super.keyDown(with: event)
    }
}
