//
//  AXAddressBarWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//

import AppKit

// MARK: - Main Window Class
class AXAddressBarWindow: NSPanel, NSWindowDelegate {
    // MARK: - UI Components
    private let scrollView = NSScrollView()
    private lazy var tableView: NSTableView = createTableView()

    var suggestionItemClickAction: ((String) -> Void)?

    // MARK: - Initialization
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupScrollView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Methods
    private func setupWindow() {
        backgroundColor = .clear
        isMovable = false
        delegate = self
    }

    private func setupScrollView() {
        scrollView.wantsLayer = true
        scrollView.layer?.cornerRadius = 10.0
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        contentView = scrollView

        tableView.backgroundColor = .gridColor
        tableView.usesAlternatingRowBackgroundColors = false
    }

    private func createTableView() -> NSTableView {
        let tableView = NSTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.addTableColumn(
            NSTableColumn(
                identifier: NSUserInterfaceItemIdentifier(
                    "AddressBarSuggestion")))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.headerView = nil
        tableView.target = self
        tableView.action = #selector(onItemClicked)
        tableView.style = .sourceList
        return tableView
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: scrollView.contentView.topAnchor),
            tableView.leadingAnchor.constraint(
                equalTo: scrollView.contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(
                equalTo: scrollView.contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(
                equalTo: scrollView.contentView.bottomAnchor)
        ])
    }

    // MARK: - Actions
    @objc
    private func onItemClicked() {
        if let suggestion = currentSuggestion {
            suggestionItemClickAction?(suggestion)
            orderOut()
        }
    }

    // MARK: - Public Methods
    func orderOut() {
        tableView.deselectAll(nil)
        super.orderOut(nil)
    }

    func showSuggestions(for textField: NSTextField) {
        if !shouldShowWindow {
            orderOut()
            return
        }

        updateWindowPosition(for: textField)
        tableView.reloadData()
        moveTo(position: 0)
    }

    private var shouldShowWindow: Bool {
        return 1 + topSiteItems.count + historyItems.count
            + googleSearchItems.count > 0
    }

    private func updateWindowPosition(for textField: NSTextField) {
        guard let textFieldWindow = textField.window else { return }
        var textFieldRect = textField.convert(textField.bounds, to: nil)
        textFieldRect = textFieldWindow.convertToScreen(textFieldRect)
        textFieldRect.origin.y -= 5

        setFrameTopLeftPoint(textFieldRect.origin)

        var frame = self.frame
        frame.size.width = textField.frame.width * 2
        setFrame(frame, display: false)

        textFieldWindow.addChildWindow(self, ordered: .above)
    }

    // MARK: - Navigation Methods
    func moveUp() {
        var selectedRow = tableView.selectedRow - 1
        while selectedRow >= 0 && isHeaderRow(selectedRow) {
            selectedRow -= 1
        }
        if selectedRow >= 0 {
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

    // MARK: - Helper Methods
    private func isHeaderRow(_ row: Int) -> Bool {
        var currentIndex = 0

        // Current query section (no header)
        currentIndex += 1

        // Top sites section
        if !topSiteItems.isEmpty && row == currentIndex {
            return true
        }
        currentIndex += topSiteItems.count + (topSiteItems.isEmpty ? 0 : 1)

        // History section
        if !historyItems.isEmpty && row == currentIndex {
            return true
        }
        currentIndex += historyItems.count + (historyItems.isEmpty ? 0 : 1)

        // Google search section
        if !googleSearchItems.isEmpty && row == currentIndex {
            return true
        }

        return false
    }

    private var totalRows: Int {
        var count = 1

        if !topSiteItems.isEmpty {
            count += 1 + topSiteItemCount
        }

        if !historyItems.isEmpty {
            count += 1 + historyItemCount
        }

        if !googleSearchItems.isEmpty {
            count += 1 + googleSearchItemCount
        }

        return count
    }

    var currentSuggestion: String? {
        let selectedRow = tableView.selectedRow
        guard selectedRow >= 0 else { return nil }

        var currentIndex = 0

        // Check current query section
        if selectedRow < 1 {
            return currentQuery
        }
        currentIndex += 1

        // Check top sites section
        if !topSiteItems.isEmpty {
            currentIndex += 1  // Header
            if selectedRow < currentIndex + topSiteItems.count {
                return topSiteItems[selectedRow - currentIndex]
            }
            currentIndex += topSiteItems.count
        }

        // Check history section
        if !historyItems.isEmpty {
            currentIndex += 1  // Header
            if selectedRow < currentIndex + historyItems.count {
                return historyItems[selectedRow - currentIndex].url
            }
            currentIndex += historyItems.count
        }

        // Check google search section
        if !googleSearchItems.isEmpty {
            currentIndex += 1  // Header
            if selectedRow < currentIndex + googleSearchItems.count {
                return googleSearchItems[selectedRow - currentIndex]
            }
        }

        return nil
    }

    private var topSiteItemCount: Int = 0
    private var historyItemCount: Int = 0
    private var googleSearchItemCount: Int = 0

    private func reloadTableViewRow(_ row: Int) {
        guard row < tableView.numberOfRows else { return }
        tableView.reloadData(
            forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet())
    }

    private func reloadTopSiteItems() {
        guard topSiteItemCount > 0 else { return }
        let range = 1..<(1 + topSiteItemCount)
        guard range.upperBound <= tableView.numberOfRows else { return }
        tableView.reloadData(
            forRowIndexes: IndexSet(integersIn: range),
            columnIndexes: IndexSet())
    }

    private func reloadHistoryItems() {
        guard historyItemCount > 0 else { return }
        let start = 1 + topSiteItemCount
        let range = start..<(start + historyItemCount)
        guard range.upperBound <= tableView.numberOfRows else { return }
        tableView.reloadData(
            forRowIndexes: IndexSet(integersIn: range),
            columnIndexes: IndexSet())
    }

    private func reloadGoogleSearchItems() {
        guard googleSearchItemCount > 0 else { return }
        let start = 1 + topSiteItemCount + historyItemCount
        let range = start..<(start + googleSearchItemCount)
        guard range.upperBound <= tableView.numberOfRows else { return }
        tableView.reloadData(
            forRowIndexes: IndexSet(integersIn: range),
            columnIndexes: IndexSet())
    }

    var currentQuery: String = "" {
        didSet {
            reloadTableViewRow(0)
        }
    }

    var topSiteItems: [String] = [] {
        didSet {
            topSiteItemCount = topSiteItems.count
            reloadTopSiteItems()
        }
    }

    var historyItems: [(title: String, url: String)] = [] {
        didSet {
            historyItemCount = historyItems.count
            reloadHistoryItems()
        }
    }

    var googleSearchItems: [String] = [] {
        didSet {
            googleSearchItemCount = googleSearchItems.count
            tableView.reloadData()
            moveTo(position: 0)
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension AXAddressBarWindow: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return totalRows
    }

    func tableView(
        _ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int
    ) -> NSView? {
        var currentIndex = 0

        // Current query section
        if row < 1 {
            return createSuggestionCell(for: currentQuery, at: row)
        }
        currentIndex += 1

        // Top sites section
        if !topSiteItems.isEmpty {
            if row == currentIndex {
                return createHeaderView(with: "Top Sites")
            }
            currentIndex += 1
            if row < currentIndex + topSiteItems.count {
                return createSuggestionCell(
                    for: topSiteItems[row - currentIndex], at: row)
            }
            currentIndex += topSiteItems.count
        }

        // History section
        if !historyItems.isEmpty {
            if row == currentIndex {
                return createHeaderView(with: "History")
            }
            currentIndex += 1
            if row < currentIndex + historyItems.count {
                return createSuggestionCell(
                    for: historyItems[row - currentIndex], at: row)
            }
            currentIndex += historyItems.count
        }

        // Google search section
        if !googleSearchItems.isEmpty {
            if row == currentIndex {
                return createHeaderView(with: "Google Search")
            }
            currentIndex += 1
            if row < currentIndex + googleSearchItems.count {
                return createSuggestionCell(
                    for: googleSearchItems[row - currentIndex], at: row)
            }
        }

        return nil
    }

    private func createHeaderView(with name: String) -> NSView {
        let headerView = AXAddressBarSectionHeaderView(frame: .zero)
        headerView.titleLabel.stringValue = name
        return headerView
    }

    private func createSuggestionCell(for suggestion: Any, at row: Int)
        -> NSView {
        let cellIdentifier = NSUserInterfaceItemIdentifier(
            "AddressBarSuggestion")
        let cell =
            tableView.makeView(withIdentifier: cellIdentifier, owner: self)
            as? AXAddressBarSuggestionCellView
            ?? AXAddressBarSuggestionCellView(frame: .zero)

        cell.identifier = cellIdentifier

        if let historyItem = suggestion as? (title: String, url: String) {
            cell.configure(title: historyItem.title, subtitle: historyItem.url)
        } else if let stringValue = suggestion as? String {
            cell.configure(title: stringValue)
        }

        cell.onMouseEnter = { [weak self] in
            self?.moveTo(position: row)
        }

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if isHeaderRow(row) {
            return 30  // Header height
        }
        return 24  // Regular cell height
    }
}
