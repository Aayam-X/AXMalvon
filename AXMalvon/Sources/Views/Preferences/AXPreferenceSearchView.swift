//
//  AXPreferenceSearchView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-07.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit

class AXPreferenceSearchView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    private var hasDrawn: Bool = false
    
    lazy var mostVisitedWebsites: [String] = {
        return UserDefaults.standard.stringArray(forKey: "MostVisitedWebsite") ?? []
    }()
    
    // Views
    let tableView = NSTableView()
    let scrollView = NSScrollView()
    
    lazy var mostVisitedWebsitesLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.alignment = .left
        label.isBordered = false
        label.drawsBackground = false
        label.stringValue = "Most visited Websites"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        return label
    }()
    
    lazy var addButton: AXPreferenceButton = {
        let button = AXPreferenceButton()
        button.imageView.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)
        button.isBordered = true
        button.bezelStyle = .texturedSquare
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleView.stringValue = "Add"
        button.action = #selector(addButtonAction)
        return button
    }()
    
    lazy var removeButton: AXPreferenceButton = {
        let button = AXPreferenceButton()
        button.imageView.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
        button.isBordered = true
        button.bezelStyle = .texturedSquare
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleView.stringValue = "Remove"
        button.titleView.textColor = .systemRed.withSystemEffect(.disabled)
        button.imageView.contentTintColor = .systemRed.withSystemEffect(.disabled)
        return button
    }()
    
    override func viewWillDraw() {
        if !hasDrawn {
            self.setFrameSize(.init(width: 500, height: 400))
            
            addSubview(mostVisitedWebsitesLabel)
            mostVisitedWebsitesLabel.topAnchor.constraint(equalTo: topAnchor, constant: 15).isActive = true
            mostVisitedWebsitesLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            mostVisitedWebsitesLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            
            // Setup scrollView
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.hasVerticalScroller = true
            scrollView.drawsBackground = true
            addSubview(scrollView)
            scrollView.topAnchor.constraint(equalTo: mostVisitedWebsitesLabel.bottomAnchor).isActive = true
            scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -55).isActive = true
            
            // Setup tableView
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.delegate = self
            tableView.dataSource = self
            tableView.allowsMultipleSelection = true
            tableView.rowHeight = 30
            tableView.usesAlternatingRowBackgroundColors = true
            tableView.headerView = nil
            tableView.frame = scrollView.bounds
            scrollView.documentView = tableView
            tableView.autoresizingMask = [.height, .width]
            
            // Setup tableView columns
            let websiteDateCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "mostVisitedWebsite"))
            websiteDateCol.width = 65
            tableView.addTableColumn(websiteDateCol)
            
            // Setup addButton
            addSubview(addButton)
            addButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 15).isActive = true
            addButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
            addButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
            addButton.widthAnchor.constraint(equalToConstant: 125).isActive = true
            
            // Setup removeButton
            addSubview(removeButton)
            removeButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 15).isActive = true
            removeButton.leftAnchor.constraint(equalTo: addButton.rightAnchor, constant: 10).isActive = true
            removeButton.widthAnchor.constraint(equalToConstant: 125).isActive = true
            removeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
            
            hasDrawn = true
        }
    }
    
    // MARK: - Action
    @objc func removeButtonAction() {
        if tableView.selectedRow != -1 {
            for index in tableView.selectedRowIndexes.reversed() {
                mostVisitedWebsites.remove(at: index)
            }
            
            UserDefaults.standard.set(mostVisitedWebsites, forKey: "MostVisitedWebsite")
            tableView.reloadData()
            removeButton.titleView.textColor = .systemRed.withSystemEffect(.disabled)
            removeButton.imageView.contentTintColor = .systemRed.withSystemEffect(.disabled)
        }
    }
    
    @objc func addButtonAction() {
        // Show an alert
        let alert = NSAlert()
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Add Search Term"
        alert.informativeText = "When typing on the search bar, this term will appear first"
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "Enter Search Term"
        alert.window.initialFirstResponder = textField
        
        alert.accessoryView = textField
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            mostVisitedWebsites.append(textField.stringValue)
            UserDefaults.standard.set(mostVisitedWebsites, forKey: "MostVisitedWebsite")
            tableView.reloadData()
        } else {
            return
        }
    }
    
    // MARK: - TableView delegates
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return mostVisitedWebsites.count
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
        text.stringValue = mostVisitedWebsites[row]
        
        // Display the label
        let cell = NSTableCellView()
        cell.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(text)
        text.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true
        text.leftAnchor.constraint(equalTo: cell.leftAnchor).isActive = true
        text.rightAnchor.constraint(equalTo: cell.rightAnchor, constant: 5).isActive = true
        
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tableView.selectedRow == -1 {
            removeButton.titleView.textColor = .systemRed.withSystemEffect(.disabled)
            removeButton.imageView.contentTintColor = .systemRed.withSystemEffect(.disabled)
        } else {
            removeButton.titleView.textColor = .systemRed
            removeButton.imageView.contentTintColor = .systemRed
        }
    }
}
