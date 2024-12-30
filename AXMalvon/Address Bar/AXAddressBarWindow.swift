//
//  AXAddressBarWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//

import AppKit

private enum Section: Int, CaseIterable {
    case topSites
    case history
    case googleSearch

    var title: String {
        switch self {
        case .topSites: return "Top Searches"
        case .history: return "History"
        case .googleSearch: return "Google Search"
        }
    }
}

class AXAddressBarWindow: NSPanel, NSWindowDelegate {
    private var searchSuggestions: [Section: [String]] = [
        .topSites: [],
        .history: [],
        .googleSearch: [],
    ]

    private let scrollView = NSScrollView()

    private lazy var tableView: NSTableView = {
        let t = NSTableView()
        t.translatesAutoresizingMaskIntoConstraints = false
        t.addTableColumn(
            NSTableColumn(
                identifier: NSUserInterfaceItemIdentifier(
                    "AddressBarSuggestion")))
        t.dataSource = self
        t.delegate = self
        t.headerView = nil
        t.usesAlternatingRowBackgroundColors = true
        t.target = self
        t.action = #selector(onItemClicked)
        t.style = .sourceList
        return t
    }()

    @objc private func onItemClicked() {
        if let currentSuggestion = self.currentSuggestion {
            self.suggestionItemClickAction?(currentSuggestion)
            self.orderOut()
        }
    }

    var suggestionItemClickAction: ((String) -> Void)?

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [
                .borderless,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )

        self.backgroundColor = .clear
        isMovable = false
        self.delegate = self

        scrollView.wantsLayer = true
        scrollView.layer?.cornerRadius = 10.0
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.drawsBackground = false
        tableView.backgroundColor = .gridColor
        tableView.usesAlternatingRowBackgroundColors = false
        scrollView.hasVerticalScroller = true
        contentView = scrollView

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: scrollView.contentView.topAnchor),
            tableView.leadingAnchor.constraint(
                equalTo: scrollView.contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(
                equalTo: scrollView.contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(
                equalTo: scrollView.contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func orderOut() {
        tableView.deselectAll(nil)
        super.orderOut(nil)
    }

    func showSuggestions(
        topSearches: [String], history: [String], googleSuggestions: [String],
        for textField: NSTextField
    ) {
        searchSuggestions[.topSites] = topSearches
        searchSuggestions[.history] = history
        searchSuggestions[.googleSearch] = googleSuggestions

        let totalItems = Section.allCases.reduce(0) { count, section in
            return count + (searchSuggestions[section]?.count ?? 0)
                + (searchSuggestions[section]?.isEmpty == false ? 1 : 0)
        }

        if totalItems == 0 {
            orderOut()
            return
        }

        guard let textFieldWindow = textField.window else { return }
        var textFieldRect = textField.convert(textField.bounds, to: nil)
        textFieldRect = textFieldWindow.convertToScreen(textFieldRect)
        textFieldRect.origin.y -= 5
        setFrameTopLeftPoint(textFieldRect.origin)

        var frame = self.frame
        frame.size.width = textField.frame.width * 2

        setFrame(frame, display: false)
        textFieldWindow.addChildWindow(self, ordered: .above)

        tableView.reloadData()
        moveTo(position: 1)
    }

    func moveUp() {
        var selectedRow = tableView.selectedRow - 1
        while selectedRow >= 0 && isHeaderRow(selectedRow) {
            selectedRow -= 1
        }
        if selectedRow >= 0 {  // Ensure a valid row is selected
            tableView.selectRowIndexes(
                IndexSet(integer: selectedRow), byExtendingSelection: false)
        } else {
            tableView.deselectAll(nil)
        }
    }

    func moveDown() {
        var selectedRow = tableView.selectedRow + 1
        while selectedRow < totalRows && isHeaderRow(selectedRow) {
            selectedRow += 1
        }
        tableView.selectRowIndexes(
            IndexSet(integer: min(selectedRow, totalRows - 1)),
            byExtendingSelection: false)
    }

    func moveTo(position: Int) {
        tableView.selectRowIndexes(
            IndexSet(integer: min(position, totalRows - 1)),
            byExtendingSelection: false)
    }

    private func isHeaderRow(_ row: Int) -> Bool {
        var currentIndex = 0
        for section in Section.allCases {
            guard let sectionData = searchSuggestions[section],
                !sectionData.isEmpty
            else {
                continue
            }

            // Header row
            if row == currentIndex {
                return true
            }

            currentIndex += 1 + sectionData.count
        }

        return false
    }

    private var totalRows: Int {
        return Section.allCases.reduce(0) { count, section in
            return count + (searchSuggestions[section]?.count ?? 0)
                + (searchSuggestions[section]?.isEmpty == false ? 1 : 0)
        }
    }

    var currentSuggestion: String? {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return nil }

        var currentIndex = 0
        for section in Section.allCases {
            guard let sectionData = searchSuggestions[section],
                !sectionData.isEmpty
            else {
                continue
            }
            // Skip header row
            currentIndex += 1

            // Check if selection is in current section
            if selectedRow < currentIndex + sectionData.count {
                return sectionData[selectedRow - currentIndex]
            }

            currentIndex += sectionData.count
        }

        return nil
    }
}

extension AXAddressBarWindow: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return totalRows
    }
}

extension AXAddressBarWindow: NSTableViewDelegate {
    func tableView(
        _ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int
    ) -> NSView? {
        var currentIndex = 0

        for section in Section.allCases {
            guard let sectionData = searchSuggestions[section],
                !sectionData.isEmpty
            else {
                continue
            }

            // Header row
            if row == currentIndex {
                let headerView = AXAddressBarSectionHeaderView(frame: .zero)
                headerView.titleLabel.stringValue = section.title
                return headerView
            }

            currentIndex += 1

            // Check if row is in current section
            if row < currentIndex + sectionData.count {
                let suggestion = sectionData[row - currentIndex]
                let cellIdentifier = NSUserInterfaceItemIdentifier(
                    "AddressBarSuggestion")
                let cell =
                    tableView.makeView(
                        withIdentifier: cellIdentifier, owner: self)
                    as? AXAddressBarSuggestionCellView
                    ?? AXAddressBarSuggestionCellView(frame: .zero)

                cell.identifier = cellIdentifier
                cell.configure(with: suggestion)
                cell.onMouseEnter = { [weak self] in
                    self?.moveTo(position: row)
                }

                return cell
            }

            currentIndex += sectionData.count
        }

        return nil
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        var currentIndex = 0

        for section in Section.allCases {
            guard let sectionData = searchSuggestions[section],
                !sectionData.isEmpty
            else {
                continue
            }

            // Header row
            if row == currentIndex {
                return 30  // Header height
            }

            currentIndex += 1 + sectionData.count
        }

        return 24  // Regular cell height
    }
}

class AXAddressBarSectionHeaderView: NSTableCellView {
    let titleLabel: NSTextField

    override init(frame frameRect: NSRect) {
        titleLabel = NSTextField(labelWithString: "Section")
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = NSColor.secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -8),
        ])
    }
}

class AXAddressBarSuggestionCellView: NSTableCellView {
    //  let titleLabel: NSTextField
    let addressLabel: NSTextField
    let faviconImageView: NSImageView
    private var currentTask: URLSessionDataTask?

    var trackingArea: NSTrackingArea!
    var onMouseEnter: (() -> Void)?

    override init(frame frameRect: NSRect) {
        addressLabel = NSTextField(labelWithString: "Suggestion")
        //   titleLabel = NSTextField(labelWithString: "")

        faviconImageView = NSImageView(
            image: NSImage(named: NSImage.iconViewTemplateName)!)
        super.init(frame: frameRect)
        setupView()

        setTrackingArea()
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)

        onMouseEnter?()
    }

    func setTrackingArea() {
        let options: NSTrackingArea.Options = [
            .activeAlways, .inVisibleRect, .mouseEnteredAndExited,
        ]
        trackingArea = NSTrackingArea.init(
            rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    deinit {
        self.removeTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addressLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        addressLabel.translatesAutoresizingMaskIntoConstraints = false

        // titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        // titleLabel.translatesAutoresizingMaskIntoConstraints = false

        faviconImageView.translatesAutoresizingMaskIntoConstraints = false

        //addSubview(titleLabel)
        addSubview(addressLabel)
        addSubview(faviconImageView)

        NSLayoutConstraint.activate([
            faviconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            faviconImageView.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: 8),
            faviconImageView.widthAnchor.constraint(equalToConstant: 16),
            faviconImageView.heightAnchor.constraint(equalToConstant: 16),

            // titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            // titleLabel.leadingAnchor.constraint(
            //     equalTo: faviconImageView.trailingAnchor, constant: 5),

            addressLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            addressLabel.leadingAnchor.constraint(
                equalTo: faviconImageView.trailingAnchor, constant: 8),
            addressLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -8),
        ])
    }

    func configure(with suggestion: String) {
        addressLabel.stringValue = suggestion
    }
}
