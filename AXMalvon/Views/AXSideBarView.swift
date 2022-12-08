//
//  AXSideBarView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-04.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXSideBarView: NSView {
    var appProperties: AXAppProperties!
    
    let scrollView = NSScrollView()
    
    var tableView = NSTableView()
    
    lazy var toggleSidebarButton: AXHoverButton = {
        let button = AXHoverButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.controlSize = .large
        button.target = self
        button.action = #selector(toggleSidebar)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    weak var toggleSidebarButtonLeftConstaint: NSLayoutConstraint?
    
    override func viewWillDraw() {
        appProperties = (window as! AXWindow).appProperties
        
        // Constraints for toggleSidebarButton
        addSubview(toggleSidebarButton)
        toggleSidebarButton.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        toggleSidebarButtonLeftConstaint = toggleSidebarButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 76)
        toggleSidebarButtonLeftConstaint?.isActive = true
        toggleSidebarButton.widthAnchor.constraint(equalToConstant: 23).isActive = true
        toggleSidebarButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        // Setup the scrollView
        addSubview(scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0))
        addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .top, relatedBy: .equal, toItem: self.toggleSidebarButton, attribute: .top, multiplier: 1.0, constant: 30))
        addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0))
        addConstraint(NSLayoutConstraint(item: self.scrollView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0))
        
        // Setup tableView
        tableView.frame = scrollView.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.action = #selector(tableViewDoubleClickAction)
        tableView.headerView = nil
        tableView.rowHeight = 30.0
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        tableView.backgroundColor = .clear

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "col"))
//        col.minWidth = 200
        tableView.addTableColumn(col)
        
        scrollView.documentView = tableView
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true
    }
    
    func enteredFullScreen() {
        toggleSidebarButtonLeftConstaint?.constant = 5
    }
    
    func exitedFullScreen() {
        toggleSidebarButtonLeftConstaint?.constant = 76
    }
    
    @objc func toggleSidebar() {
        appProperties!.sidebarToggled.toggle()
        
        if appProperties!.sidebarToggled {
            // TODO: THINK PROPERLY | toggleSidebarButtonLeftConstaint?.constant = appProperties!.isFullScreen ? 5 : 76
            appProperties?.splitView.insertArrangedSubview(self, at: 0)
            (self.window as! AXWindow).hideTrafficLights(false)
        } else {
            (self.window as! AXWindow).hideTrafficLights(true)
            self.removeFromSuperview()
            
        }
    }
    
    override var tag: Int {
        return 0x01
    }
    
    override func viewDidHide() {
        (self.window as! AXWindow).hideTrafficLights(true)
    }
    
    override func viewDidUnhide() {
        (self.window as! AXWindow).hideTrafficLights(false)
    }
    
    override public func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    
    @objc func tableViewDoubleClickAction() {
        appProperties.currentTab = tableView.selectedRow
        appProperties.webContainerView.update()
    }
}

extension AXSideBarView: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return appProperties.tabs.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let text = NSTextField()
        text.stringValue = appProperties.tabs[row].title ?? "Untitled"
        let cell = NSTableCellView()
        cell.addSubview(text)
        text.drawsBackground = false
        text.isBordered = false
        text.translatesAutoresizingMaskIntoConstraints = false
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .centerY, relatedBy: .equal, toItem: cell, attribute: .centerY, multiplier: 1, constant: 0))
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .left, relatedBy: .equal, toItem: cell, attribute: .left, multiplier: 1, constant: 13))
        
        cell.addConstraint(NSLayoutConstraint(item: text, attribute: .right, relatedBy: .equal, toItem: cell, attribute: .right, multiplier: 1, constant: -13))
        return cell
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.isEmphasized = false
        return rowView
    }
}
