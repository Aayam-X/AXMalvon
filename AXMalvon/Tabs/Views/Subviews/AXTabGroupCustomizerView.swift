//
//  AXTabGroupCustomizerView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-07.
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
        NSLayoutConstraint.activate([
            tabGroupLabel.topAnchor.constraint(
                equalTo: topAnchor, constant: 10),
            tabGroupLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 10),

            tabGroupNameTextField.topAnchor.constraint(
                equalTo: tabGroupLabel.bottomAnchor, constant: 5),
            tabGroupNameTextField.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 10),
            tabGroupNameTextField.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -10),

            iconLabel.topAnchor.constraint(
                equalTo: tabGroupNameTextField.bottomAnchor, constant: 10),
            iconLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 10),

            iconDropdown.topAnchor.constraint(
                equalTo: iconLabel.bottomAnchor, constant: 5),
            iconDropdown.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 10),
            iconDropdown.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -10),

            colorLabel.topAnchor.constraint(
                equalTo: iconDropdown.bottomAnchor, constant: 10),
            colorLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 10),

            colorWell.topAnchor.constraint(
                equalTo: colorLabel.bottomAnchor, constant: 5),
            colorWell.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            colorWell.rightAnchor.constraint(
                equalTo: rightAnchor, constant: -10)
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
