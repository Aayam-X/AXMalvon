//
//  AXSidebarPopoverView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-16.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import SwiftUI

protocol AXSidebarPopoverViewDelegate: AnyObject {
    func didSwitchProfile(to index: Int)
    func didSwitchTabGroup(to index: Int)
    func didAddTabGroup(_ newGroup: AXTabGroup)
    func popoverViewTabGroups() -> [AXTabGroup]
    func updatedTabGroupName(at: Int, to: String)
}

/// Custom view for managing tab groups
class AXSidebarPopoverView: NSView, NSTableViewDelegate, NSTableViewDataSource,
    NSTextFieldDelegate
{
    var hasDrawn = false
    weak var delegate: AXSidebarPopoverViewDelegate?
    var tabGroups: [AXTabGroup]!

    // MARK: - Properties
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let addButton = NSButton(
        title: "Add Tab Group", target: nil, action: #selector(addTabGroup))
    private let switchProfileButton = NSButton(
        title: "Switch Profile", target: nil, action: #selector(switchProfile))

    // MARK: - Initializer
    init() {
        super.init(frame: .zero)
        setupDoubleClickGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDraw() {
        guard !hasDrawn else {
            tableView.reloadData()
            return
        }
        defer { hasDrawn = true }
        setupView()
    }

    // MARK: - Setup
    private func setupView() {
        addButton.translatesAutoresizingMaskIntoConstraints = false
        switchProfileButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addButton.target = self
        addButton.action = #selector(addTabGroup)
        switchProfileButton.target = self
        switchProfileButton.action = #selector(switchProfile)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true

        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil

        let column = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("TabGroupColumn"))
        column.title = "Tab Groups"
        tableView.addTableColumn(column)

        addSubview(scrollView)
        addSubview(addButton)
        addSubview(switchProfileButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(
                equalTo: addButton.topAnchor, constant: -10),

            addButton.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 10),
            addButton.bottomAnchor.constraint(
                equalTo: bottomAnchor, constant: -10),
            addButton.heightAnchor.constraint(equalToConstant: 30),

            switchProfileButton.leadingAnchor.constraint(
                equalTo: addButton.trailingAnchor, constant: 10),
            switchProfileButton.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -10),
            switchProfileButton.bottomAnchor.constraint(
                equalTo: bottomAnchor, constant: -10),
            switchProfileButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }

    private func setupDoubleClickGesture() {
        let doubleClickGesture = NSClickGestureRecognizer(
            target: self, action: #selector(handleDoubleClick))
        doubleClickGesture.numberOfClicksRequired = 2
        tableView.addGestureRecognizer(doubleClickGesture)
    }

    // MARK: - Actions
    @objc private func addTabGroup() {
        let newGroup = AXTabGroup(name: "New Group")
        delegate?.didAddTabGroup(newGroup)
        tableView.reloadData()
    }

    @objc private func switchProfile() {
        delegate?.didSwitchProfile(to: tableView.selectedRow)
        tableView.reloadData()
    }

    @objc private func handleDoubleClick(_ sender: NSClickGestureRecognizer) {
        let location = sender.location(in: tableView)
        let row = tableView.row(at: location)
        if row >= 0 && row < tabGroups.count {
            guard
                let cell = tableView.view(
                    atColumn: 0, row: row, makeIfNecessary: false)
                    as? NSTextField
            else { return }
            cell.isEditable = true
            cell.becomeFirstResponder()
        }
    }

    // MARK: - NSTableView DataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let tabGroups = delegate?.popoverViewTabGroups() {
            self.tabGroups = tabGroups
            return tabGroups.count
        } else {
            return 0
        }
    }

    func tableView(
        _ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int
    ) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("TabGroupCell")
        let cell =
            tableView.makeView(withIdentifier: identifier, owner: self)
            as? NSTextField ?? NSTextField()

        cell.identifier = identifier
        cell.stringValue = tabGroups[row].name
        cell.isEditable = false
        cell.isBordered = false
        cell.drawsBackground = false
        cell.delegate = self
        cell.tag = row
        cell.bezelStyle = .roundedBezel
        return cell
    }

    // MARK: - NSTableView Delegate
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 && selectedRow < tabGroups.count {
            delegate?.didSwitchTabGroup(to: selectedRow)
        }
    }

    // MARK: - NSTextField Delegate
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let index = textField.tag
        if index >= 0 && index < tabGroups.count {
            delegate?.updatedTabGroupName(at: index, to: textField.stringValue)
            textField.isEditable = false  // Disable editing after finishing
        }
    }
}
