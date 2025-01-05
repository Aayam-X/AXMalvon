//
//  AXTabGroupCustomizerView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-07.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

protocol AXTabGroupCustomizerViewDelegate: AnyObject {
    func tabGroupCustomizerDidUpdateName(_ tabGroup: AXTabGroup)
    func tabGroupCustomizerDidUpdateColor(_ tabGroup: AXTabGroup)
    func tabGroupCustomizerDidUpdateIcon(_ tabGroup: AXTabGroup)

    func tabGroupCustomizerActiveTabGroup() -> AXTabGroup?
}

class AXTabGroupCustomizerView: NSView, NSTextFieldDelegate {
    weak var delegate: AXTabGroupCustomizerViewDelegate?
    weak var tabGroup: AXTabGroup? {
        delegate?.tabGroupCustomizerActiveTabGroup()
    }

    private let tabGroupLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Tab Group Name")
        label.font = NSFont.boldSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var tabGroupNameTextField: NSTextField = {
        let textField = NSTextField()
        textField.delegate = self
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let iconLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Tab Group Icon")
        label.font = NSFont.boldSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var iconDropdown: NSPopUpButton = {
        let dropdown = NSPopUpButton()
        dropdown.addItems(withTitles: ["star", "bookmark", "pencil", "folder"])
        dropdown.target = self
        dropdown.action = #selector(iconSelectionChanged)
        dropdown.translatesAutoresizingMaskIntoConstraints = false
        return dropdown
    }()

    private let colorLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Tab Group Color")
        label.font = NSFont.boldSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var colorWell: NSColorWell = {
        let colorWell = NSColorWell()
        colorWell.color = tabGroup?.color ?? .white
        colorWell.action = #selector(colorWellUpdated)
        colorWell.target = self
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        return colorWell
    }()

    var hasDrawn: Bool = false
    override func viewWillDraw() {
        hasDrawn ? () : setupView()
    }

    private func setupView() {
        tabGroupNameTextField.stringValue = tabGroup?.name ?? "Null Tab Group"
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor

        addSubview(tabGroupLabel)
        addSubview(tabGroupNameTextField)
        addSubview(iconLabel)
        addSubview(iconDropdown)
        addSubview(colorLabel)
        addSubview(colorWell)

        setupConstraints()
    }

    private func setupConstraints() {
        tabGroupLabel.activateConstraints([
            .top: .view(self, constant: 10),
            .left: .view(self, constant: 10),
        ])

        tabGroupNameTextField.activateConstraints([
            .topBottom: .view(tabGroupLabel, constant: 5),
            .left: .view(self, constant: 10),
            .right: .view(self, constant: -10),
        ])

        iconLabel.activateConstraints([
            .topBottom: .view(tabGroupNameTextField, constant: 10),
            .left: .view(self, constant: 10),
        ])

        iconDropdown.activateConstraints([
            .topBottom: .view(iconLabel, constant: 5),
            .left: .view(self, constant: 10),
            .right: .view(self, constant: -10),
        ])

        colorLabel.activateConstraints([
            .topBottom: .view(iconDropdown, constant: 10),
            .left: .view(self, constant: 10),
        ])

        colorWell.activateConstraints([
            .topBottom: .view(colorLabel, constant: 5),
            .left: .view(self, constant: 10),
            .right: .view(self, constant: -10),
        ])
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField,
            textField == tabGroupNameTextField,
            let tabGroup = delegate?.tabGroupCustomizerActiveTabGroup()
        else { return }
        tabGroup.name = textField.stringValue
        delegate?.tabGroupCustomizerDidUpdateName(tabGroup)
    }

    @objc
    private func iconSelectionChanged() {
        guard let selectedIcon = iconDropdown.titleOfSelectedItem,
            let tabGroup = delegate?.tabGroupCustomizerActiveTabGroup()
        else {
            return
        }
        tabGroup.icon = selectedIcon

        delegate?.tabGroupCustomizerDidUpdateIcon(tabGroup)
    }

    @objc
    private func colorWellUpdated() {
        guard let tabGroup = delegate?.tabGroupCustomizerActiveTabGroup() else {
            return
        }
        tabGroup.color = colorWell.color
        delegate?.tabGroupCustomizerDidUpdateColor(tabGroup)
    }
}
