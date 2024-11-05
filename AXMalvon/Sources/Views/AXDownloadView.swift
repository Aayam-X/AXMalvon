//
//  AXDownloadView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-06.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit

class AXDownloadView: NSView, NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate {
    weak var appProperties: AXSessionProperties!
    
    // Items
    var items: [AXDownloadItem] = []
    var filteredItems: [AXDownloadItem] = []
    private var hasDrawn: Bool = false
    var changesMade: Bool = false
    
    // Views
    let searchField = NSSearchField()
    let tableView = NSTableView()
    let scrollView = NSScrollView()
    
    lazy var reloadButton: AXHoverButton = {
        let button = AXHoverButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: nil)
        button.imageScaling = .scaleProportionallyUpOrDown
        button.target = self
        button.action = #selector(reloadButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 20).isActive = true
        
        return button
    }()
    
    lazy var removeAllButton: AXHoverButton = {
        let button = AXHoverButton()
        
        button.imagePosition = .imageOnly
        button.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
        button.title = "Remove All"
        button.imagePosition = .imageLeading
        button.target = self
        button.action = #selector(removeAllButtonAction)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 81).isActive = true
        
        return button
    }()
    
    init(appProperties: AXSessionProperties) {
        self.appProperties = appProperties
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDraw() {
        if !hasDrawn {
            // Setup searchField
            searchField.translatesAutoresizingMaskIntoConstraints = false
            searchField.bezelStyle = .roundedBezel
            searchField.controlSize = .large
            searchField.action = #selector(searchAction)
            addSubview(searchField)
            searchField.topAnchor.constraint(equalTo: topAnchor).isActive = true
            searchField.rightAnchor.constraint(equalTo: rightAnchor, constant: 30).isActive = true
            
            // Setup removeAllButton
            addSubview(removeAllButton)
            removeAllButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
            removeAllButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor).isActive = true
            removeAllButton.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            removeAllButton.rightAnchor.constraint(equalTo: searchField.leftAnchor).isActive = true
            
            // Setup reloadButton
            addSubview(reloadButton)
            reloadButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
            reloadButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor).isActive = true
            reloadButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -5).isActive = true
            
            // Setup scrollview
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.hasVerticalScroller = true
            scrollView.drawsBackground = false
            addSubview(scrollView)
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor).isActive = true
            scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            // Setup tableView
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.delegate = self
            tableView.dataSource = self
            tableView.backgroundColor = .clear
            tableView.allowsMultipleSelection = true
            tableView.doubleAction = #selector(tableViewClickAction)
            tableView.frame = scrollView.bounds
            tableView.autoresizingMask = [.height, .width]
            
            scrollView.documentView = tableView
            
            // Setup tableView columns
            let downloadDateCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "downloadDateCol"))
            downloadDateCol.headerCell.title = "Date"
            downloadDateCol.width = 65
            tableView.addTableColumn(downloadDateCol)
            
            let filenameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "filenameCol"))
            filenameCol.headerCell.title = "File name"
            tableView.addTableColumn(filenameCol)
            
            let filelocationCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "filelocationCol"))
            filelocationCol.headerCell.title = "Location"
            tableView.addTableColumn(filelocationCol)
            
            reloadButtonAction()
            
            self.window?.delegate = self
            
            hasDrawn = true
        }
    }
    
    // MARK: - Table View
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredItems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // Create textLabel
        let text = NSTextField()
        text.alignment = .left
        text.lineBreakMode = .byTruncatingTail
        text.isSelectable = true
        text.isEditable = false
        text.drawsBackground = false
        text.isBordered = false
        text.translatesAutoresizingMaskIntoConstraints = false
        
        // Assign value to label
        if tableColumn?.identifier.rawValue == "filenameCol" {
            text.stringValue = filteredItems[row].fileName
        } else if tableColumn?.identifier.rawValue == "filelocationCol" {
            text.stringValue = filteredItems[row].location
        } else {
            text.stringValue = filteredItems[row].date
        }
        
        // Display the label
        let cell = NSTableCellView()
        cell.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(text)
        text.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true
        text.leftAnchor.constraint(equalTo: cell.leftAnchor).isActive = true
        text.rightAnchor.constraint(equalTo: cell.rightAnchor, constant: 5).isActive = true
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        if edge == .trailing {
            let deleteAction = NSTableViewRowAction(style: .destructive, title: "Delete", handler: { (rowAction, row) in
                // Delete Action
                self.items.remove(at: row)
                self.changesMade = true
                tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideLeft)
            })
            deleteAction.backgroundColor = NSColor.red
            return [deleteAction]
        }
        
        return []
    }
    
    // MARK: - Actions
    
    @objc func tableViewClickAction() {
        let selectedRows = tableView.selectedRowIndexes
        
        for rowIndex in selectedRows {
            if let url = filteredItems[rowIndex].url {
                NSWorkspace.shared.open(url)
            }
        }
        self.window?.close()
    }
    
    @objc func searchAction() {
        let query = searchField.stringValue
        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { item in
                return item.fileName.contains(query) || item.location.contains(query) || item.date.contains(query)
            }
        }
        
        tableView.reloadData()
    }
    
    @objc func reloadButtonAction() {
        items = AXDownload.getAllItems().reversed()
        filteredItems = items
        tableView.reloadData()
    }
    
    @objc func removeAllButtonAction() {
        AXDownload.removeAll()
        reloadButtonAction()
    }
    
    // MARK: - Functions
    
    func updateChanges() {
        if changesMade {
            AXDownload.updateDownloadFile(items: self.items)
            changesMade = false
        }
    }
    
    func deleteAtHighlightedRows() {
        for index in tableView.selectedRowIndexes.reversed() {
            items.remove(at: index)
            filteredItems = items
        }
        
        tableView.reloadData()
        changesMade = true
        updateChanges()
    }
    
    override func keyDown(with event: NSEvent) {
        let key = event.charactersIgnoringModifiers
        
        if key == String(UnicodeScalar(NSDeleteCharacter)!)  {
            deleteAtHighlightedRows()
        } else {
            super.keyDown(with: event)
        }
    }
    
    // MARK: - Window
    
    func windowDidResignKey(_ notification: Notification) {
        updateChanges()
    }
    
    func windowWillClose(_ notification: Notification) {
        updateChanges()
    }
}
