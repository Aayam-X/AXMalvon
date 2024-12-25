//
//  AXWorkspaceSwapperView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-16.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

protocol AXWorkspaceSwapperViewDelegate: AnyObject {
    func didSwitchProfile(to index: Int)
    func didSwitchTabGroup(to index: Int)
    func didAddTabGroup(_ newGroup: AXTabGroup)
    func currentProfileName() -> String

    func popoverViewTabGroups() -> [AXTabGroup]
}

class AXWorkspaceSwapperView: NSView {
    weak var delegate: AXWorkspaceSwapperViewDelegate?

    // MARK: - UI Components
    private let titleLabel = NSTextField(labelWithString: "Workspace Navigator")
    private let tabGroupTableView = NSTableView()
    private let tabGroupScrollView = NSScrollView()

    private lazy var addButton: NSButton = {
        let button = NSButton(
            image: NSImage(named: NSImage.addTemplateName)!, target: self,
            action: #selector(addTabGroup))
        button.bezelStyle = .circular
        button.imagePosition = .imageOnly
        return button
    }()

    private lazy var profileNavigationStackView = NSStackView()
    private lazy var leftProfileButton = NSButton(
        title: "◀", target: nil, action: #selector(switchProfileLeft))
    private lazy var rightProfileButton = NSButton(
        title: "▶", target: nil, action: #selector(switchProfileRight))
    private lazy var currentProfileLabel = NSTextField(labelWithString: "")

    private var selectedProfileIndex: Int = 0

    // MARK: - Initializer
    var hasDrawn: Bool = false
    override func viewWillDraw() {
        hasDrawn ? () : setupView()
    }

    // MARK: - Setup
    private func setupView() {
        // Configure title
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure add button
        addButton.target = self
        addButton.action = #selector(addTabGroup)
        addButton.translatesAutoresizingMaskIntoConstraints = false

        // Configure table view
        configureTableView()

        // Configure profile navigation stack view
        configureProfileNavigationStackView()

        // Add subviews
        addSubview(titleLabel)
        addSubview(tabGroupScrollView)
        addSubview(profileNavigationStackView)
        addSubview(addButton)

        // Set up constraints
        setupConstraints()
    }

    private func configureTableView() {
        tabGroupTableView.delegate = self
        tabGroupTableView.dataSource = self
        tabGroupTableView.backgroundColor = .clear
        tabGroupTableView.selectionHighlightStyle = .regular

        let column = NSTableColumn(
            identifier: NSUserInterfaceItemIdentifier("TabGroups"))
        column.title = "Tab Groups"
        tabGroupTableView.addTableColumn(column)
        tabGroupTableView.headerView = nil

        tabGroupScrollView.documentView = tabGroupTableView
        tabGroupScrollView.hasVerticalScroller = true
        tabGroupScrollView.drawsBackground = false
        tabGroupScrollView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureProfileNavigationStackView() {
        // Configure profile navigation buttons
        leftProfileButton.bezelStyle = .rounded
        rightProfileButton.bezelStyle = .rounded

        // Configure profile label to be bold and larger
        currentProfileLabel.font = NSFont.boldSystemFont(ofSize: 16)
        currentProfileLabel.alignment = .center

        leftProfileButton.target = self
        rightProfileButton.target = self

        profileNavigationStackView.orientation = .horizontal
        profileNavigationStackView.distribution = .fillProportionally
        profileNavigationStackView.translatesAutoresizingMaskIntoConstraints =
            false

        profileNavigationStackView.addArrangedSubview(leftProfileButton)
        profileNavigationStackView.addArrangedSubview(currentProfileLabel)
        profileNavigationStackView.addArrangedSubview(rightProfileButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title constraints
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Add Button constraints (top right corner)
            addButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            addButton.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -10),
            addButton.widthAnchor.constraint(equalToConstant: 30),
            addButton.heightAnchor.constraint(equalToConstant: 30),

            // Table View Scroll View constraints
            tabGroupScrollView.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: 20),
            tabGroupScrollView.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 10),
            tabGroupScrollView.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -10),
            tabGroupScrollView.heightAnchor.constraint(equalToConstant: 200),  // Adjust height as needed

            // Profile Navigation Stack View constraints
            profileNavigationStackView.bottomAnchor.constraint(
                equalTo: bottomAnchor, constant: -10),
            profileNavigationStackView.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 10),
            profileNavigationStackView.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -10),
        ])
    }

    // MARK: - Tab Group Management
    func reloadTabGroups() {
        tabGroupTableView.reloadData()

        // Update profile label
        if let profileName = delegate?.currentProfileName() {
            currentProfileLabel.stringValue = profileName
        }
    }

    // MARK: - Actions
    @objc private func addTabGroup() {
        let newGroup = AXTabGroup(name: "New Group")
        delegate?.didAddTabGroup(newGroup)
        reloadTabGroups()
    }

    private func tabGroupSelected(_ row: Int) {
        guard row >= 0 else { return }

        delegate?.didSwitchTabGroup(to: row)
    }

    @objc private func switchProfileLeft() {
        delegate?.didSwitchProfile(to: max(0, selectedProfileIndex - 1))
        reloadTabGroups()
    }

    @objc private func switchProfileRight() {
        let tabGroups = delegate?.popoverViewTabGroups() ?? []
        delegate?.didSwitchProfile(
            to: min(tabGroups.count - 1, selectedProfileIndex + 1))
        reloadTabGroups()
    }
}

// Update the table view delegate extension
extension AXWorkspaceSwapperView: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return delegate?.popoverViewTabGroups().count ?? 0
    }

    func tableView(
        _ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int
    ) -> NSView? {
        guard let delegate = delegate else { return nil }

        let tabGroups = delegate.popoverViewTabGroups()
        guard row < tabGroups.count else { return nil }

        let tabGroup = tabGroups[row]

        // Dequeue or create a new cell
        let cellIdentifier = NSUserInterfaceItemIdentifier("TabGroupCell")
        let cell =
            tableView.makeView(withIdentifier: cellIdentifier, owner: self)
            as? AXWorkspaceTabGroupCell ?? AXWorkspaceTabGroupCell(frame: .zero)

        // Configure the cell
        cell.identifier = cellIdentifier
        cell.configure(with: tabGroup)

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40  // Increased height for table view rows
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else {
            return
        }

        tabGroupSelected(tableView.selectedRow)
    }
}

class AXWorkspaceTabGroupCell: NSTableCellView {
    private let iconImageView: NSImageView
    private let nameLabel: NSTextField
    private let divider: NSBox

    override init(frame frameRect: NSRect) {
        // Initialize the subviews
        iconImageView = NSImageView()
        nameLabel = NSTextField(labelWithString: "")
        divider = NSBox()

        super.init(frame: frameRect)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        // Configure image view
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        // Configure name label
        nameLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Configure divider
        divider.boxType = .custom
        divider.borderWidth = 1
        divider.borderColor = .separatorColor
        divider.translatesAutoresizingMaskIntoConstraints = false

        // Add subviews
        addSubview(iconImageView)
        addSubview(nameLabel)
        addSubview(divider)

        // Set up constraints
        NSLayoutConstraint.activate([
            // Icon constraints
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 5),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),

            // Label constraints
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.leadingAnchor.constraint(
                equalTo: iconImageView.trailingAnchor, constant: 5),
            nameLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -5),

            // Divider constraints
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(with tabGroup: AXTabGroup) {
        // Configure the cell with the given tab group
        iconImageView.image = NSImage(
            systemSymbolName: tabGroup.icon,
            accessibilityDescription: nil
        )

        nameLabel.stringValue = tabGroup.name
    }
}
