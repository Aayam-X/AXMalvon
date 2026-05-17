//
//  AXCommandBar.swift
//  AXMalvon
//
//  ⌘T / ⌘L floating command bar. A borderless ``NSPanel`` that floats
//  centered over the active window with a glass background, animates
//  in with a scale+fade, and runs three suggestion streams from
//  ``SuggestionsManager`` (history, frequent URLs, Google) plus an
//  inline "Open <url>" entry when the query parses as a URL.
//
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

// MARK: - Suggestion model

/// A single row in the command bar. The order in which these are emitted
/// reflects the source-priority rule: direct-URL match first, then
/// history (most-visited + recent), then Google's autocomplete.
enum AXCommandBarSuggestion: Sendable, Equatable {
    case directURL(URL)
    case history(title: String, urlString: String)
    case search(query: String)
}

extension AXCommandBarSuggestion {
    var displayTitle: String {
        switch self {
        case .directURL(let url): return url.absoluteString
        case .history(let title, _):
            return title.isEmpty ? "Untitled" : title
        case .search(let query): return query
        }
    }

    var displaySubtitle: String {
        switch self {
        case .directURL: return "Open URL"
        case .history(_, let urlString):
            return URL(string: urlString)?.host ?? urlString
        case .search: return "Search"
        }
    }

    var symbolName: String {
        switch self {
        case .directURL: return "arrow.up.right.square"
        case .history: return "clock.arrow.circlepath"
        case .search: return "magnifyingglass"
        }
    }

    @MainActor
    func resolveURL() -> URL? {
        switch self {
        case .directURL(let url): return url
        case .history(_, let urlString): return URL(string: urlString)
        case .search(let query):
            return AXSearchQueryToURL.shared.convert(query: query)
        }
    }
}

// MARK: - Panel

@MainActor
final class AXCommandBarPanel: NSPanel {
    var onCommit: ((URL) -> Void)?
    var onCancel: (() -> Void)?

    private let controller = AXCommandBarController()

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 64),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .modalPanel
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = true
        animationBehavior = .none

        contentViewController = controller
        controller.onCommit = { [weak self] url in
            guard let self else { return }
            self.onCommit?(url)
            self.dismiss()
        }
        controller.onCancel = { [weak self] in
            self?.dismiss()
            self?.onCancel?()
        }
        controller.onLayoutChange = { [weak self] in
            self?.fitToContent()
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Show the panel centered (slightly above center) on `window`, with
    /// the supplied prefill text and live suggestion stream.
    func present(
        in window: NSWindow,
        prefill: String,
        suggestionsManager: SuggestionsManager
    ) {
        controller.prepare(text: prefill, suggestionsManager: suggestionsManager)
        positionRelativeTo(window: window)

        contentView?.wantsLayer = true
        contentView?.layer?.opacity = 0
        contentView?.layer?.setAffineTransform(
            CGAffineTransform(scaleX: 0.94, y: 0.94))

        window.addChildWindow(self, ordered: .above)
        makeKey()
        controller.focusInput()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(
                controlPoints: 0.2, 0.8, 0.2, 1.0)
            contentView?.animator().layer?.opacity = 1
            contentView?.animator().layer?.setAffineTransform(.identity)
        }
    }

    /// Slide out / fade and detach from the parent window.
    func dismiss() {
        guard isVisible else { return }
        NSAnimationContext.runAnimationGroup(
            { ctx in
                ctx.duration = 0.14
                ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                contentView?.animator().layer?.opacity = 0
                contentView?.animator().layer?.setAffineTransform(
                    CGAffineTransform(scaleX: 0.96, y: 0.96))
            },
            completionHandler: {
                MainActor.assumeIsolated {
                    self.parent?.removeChildWindow(self)
                    self.orderOut(nil)
                }
            }
        )
    }

    /// Re-layout when the suggestions list grows or shrinks. The panel
    /// keeps its top edge fixed so the text field doesn't jump.
    private func fitToContent() {
        guard let preferred = controller.currentLayoutSize else { return }
        var f = frame
        let oldTop = f.maxY
        f.size.height = preferred.height
        f.origin.y = oldTop - preferred.height
        setFrame(f, display: true, animate: false)
    }

    private func positionRelativeTo(window: NSWindow) {
        let parent = window.frame
        let size = NSSize(width: 680, height: controller.currentLayoutSize?.height ?? 64)
        let origin = NSPoint(
            x: parent.midX - size.width / 2,
            y: parent.midY - size.height / 2 + 120
        )
        setFrame(NSRect(origin: origin, size: size), display: true)
    }
}

// MARK: - Controller

@MainActor
final class AXCommandBarController: NSViewController, NSTextFieldDelegate {

    // MARK: Public

    var onCommit: ((URL) -> Void)?
    var onCancel: (() -> Void)?
    var onLayoutChange: (() -> Void)?

    var currentLayoutSize: NSSize? {
        guard let _ = viewIfLoaded else { return nil }
        let rowsHeight: CGFloat =
            suggestions.isEmpty
            ? 0
            : CGFloat(min(suggestions.count, 8)) * AXCommandBarRow.height
                + suggestionsStackInsets
        let separatorHeight: CGFloat = suggestions.isEmpty ? 0 : 1
        return NSSize(
            width: 680,
            height: searchRowHeight + separatorHeight + rowsHeight)
    }

    // MARK: Subviews

    private let glassContainer: NSGlassEffectView = {
        let v = NSGlassEffectView()
        v.style = .regular
        v.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let magnifyingGlass: NSImageView = {
        let v = NSImageView()
        v.image = NSImage(
            systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        v.symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: 16, weight: .medium)
        v.contentTintColor = .secondaryLabelColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var textField: NSTextField = {
        let f = NSTextField()
        f.isBordered = false
        f.drawsBackground = false
        f.focusRingType = .none
        f.font = .systemFont(ofSize: 18, weight: .regular)
        f.placeholderString = "Search or enter address…"
        f.delegate = self
        f.translatesAutoresizingMaskIntoConstraints = false
        return f
    }()

    private let separator: NSBox = {
        let s = NSBox()
        s.boxType = .separator
        s.translatesAutoresizingMaskIntoConstraints = false
        s.isHidden = true
        return s
    }()

    private let suggestionsStack: NSStackView = {
        let s = NSStackView()
        s.orientation = .vertical
        s.spacing = 2
        s.alignment = .leading
        s.distribution = .fill
        s.edgeInsets = .init(top: 6, left: 8, bottom: 8, right: 8)
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: Geometry

    private let searchRowHeight: CGFloat = 60
    private let suggestionsStackInsets: CGFloat = 14  // top 6 + bottom 8

    // MARK: State

    private var suggestionsManager: SuggestionsManager?
    private var rowViews: [AXCommandBarRow] = []

    private var historyResults: [(title: String, url: String)] = []
    private var googleResults: [String] = []
    private var topSearches: [String] = []

    private var suggestions: [AXCommandBarSuggestion] = [] {
        didSet {
            rebuildRows()
        }
    }

    private var selectedIndex: Int = 0 {
        didSet {
            updateSelectionAppearance()
        }
    }

    // MARK: Lifecycle

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 680, height: 64))
        root.wantsLayer = true

        let inner = NSView()
        inner.translatesAutoresizingMaskIntoConstraints = false

        let searchRow = NSView()
        searchRow.translatesAutoresizingMaskIntoConstraints = false
        searchRow.addSubview(magnifyingGlass)
        searchRow.addSubview(textField)

        inner.addSubview(searchRow)
        inner.addSubview(separator)
        inner.addSubview(suggestionsStack)

        root.addSubview(glassContainer)
        glassContainer.contentView = inner

        NSLayoutConstraint.activate([
            // Glass fills root
            glassContainer.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            glassContainer.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            glassContainer.topAnchor.constraint(equalTo: root.topAnchor),
            glassContainer.bottomAnchor.constraint(equalTo: root.bottomAnchor),

            // Magnifying glass leading inside searchRow
            magnifyingGlass.leadingAnchor.constraint(
                equalTo: searchRow.leadingAnchor, constant: 22),
            magnifyingGlass.centerYAnchor.constraint(
                equalTo: searchRow.centerYAnchor),
            magnifyingGlass.widthAnchor.constraint(equalToConstant: 20),
            magnifyingGlass.heightAnchor.constraint(equalToConstant: 20),

            // Text field fills the rest of searchRow
            textField.leadingAnchor.constraint(
                equalTo: magnifyingGlass.trailingAnchor, constant: 14),
            textField.trailingAnchor.constraint(
                equalTo: searchRow.trailingAnchor, constant: -22),
            textField.centerYAnchor.constraint(equalTo: searchRow.centerYAnchor),

            // Search row at top of inner
            searchRow.topAnchor.constraint(equalTo: inner.topAnchor),
            searchRow.leadingAnchor.constraint(equalTo: inner.leadingAnchor),
            searchRow.trailingAnchor.constraint(equalTo: inner.trailingAnchor),
            searchRow.heightAnchor.constraint(equalToConstant: searchRowHeight),

            // Separator under search row
            separator.topAnchor.constraint(equalTo: searchRow.bottomAnchor),
            separator.leadingAnchor.constraint(
                equalTo: inner.leadingAnchor, constant: 10),
            separator.trailingAnchor.constraint(
                equalTo: inner.trailingAnchor, constant: -10),
            separator.heightAnchor.constraint(equalToConstant: 1),

            // Suggestions stack under separator
            suggestionsStack.topAnchor.constraint(equalTo: separator.bottomAnchor),
            suggestionsStack.leadingAnchor.constraint(equalTo: inner.leadingAnchor),
            suggestionsStack.trailingAnchor.constraint(equalTo: inner.trailingAnchor),
            suggestionsStack.bottomAnchor.constraint(equalTo: inner.bottomAnchor),
        ])

        view = root
    }

    func prepare(
        text: String, suggestionsManager: SuggestionsManager
    ) {
        self.suggestionsManager = suggestionsManager
        textField.stringValue = text

        // Reset stream caches before re-attaching callbacks so we don't
        // show stale results from a previous invocation.
        historyResults = []
        googleResults = []
        topSearches = []

        suggestionsManager.onHistoryUpdated = { [weak self] history in
            guard let self else { return }
            self.historyResults = history
            self.rebuildSuggestions()
        }
        suggestionsManager.onTopSearchesUpdated = { [weak self] top in
            guard let self else { return }
            self.topSearches = top
            self.rebuildSuggestions()
        }
        suggestionsManager.onGoogleSuggestionsUpdated = { [weak self] google in
            guard let self else { return }
            self.googleResults = google
            self.rebuildSuggestions()
        }
        suggestionsManager.onQueryUpdated = { _ in }

        if !text.isEmpty {
            suggestionsManager.updateSuggestions(with: text)
        }
        rebuildSuggestions()
    }

    func focusInput() {
        view.window?.makeFirstResponder(textField)
        textField.currentEditor()?.selectAll(nil)
    }

    // MARK: Suggestion rebuilding

    private func rebuildSuggestions() {
        let query = textField.stringValue
        var built: [AXCommandBarSuggestion] = []

        if let direct = directURL(from: query) {
            built.append(.directURL(direct))
        }

        // Frequently-typed URLs that prefix-match the query.
        let frequentURLs = topSearches
            .prefix(2)
            .filter { url in !built.contains(.directURL(URL(string: url) ?? URL(fileURLWithPath: "/"))) }
        for url in frequentURLs {
            built.append(.history(title: url, urlString: url))
        }

        // Browsing history matches.
        for entry in historyResults.prefix(5) {
            built.append(
                .history(title: entry.title, urlString: entry.url))
        }

        // Google's autocomplete (deduped against direct URL match).
        for s in googleResults.prefix(5) where !s.isEmpty {
            built.append(.search(query: s))
        }

        suggestions = built
        selectedIndex = min(selectedIndex, max(0, built.count - 1))
    }

    /// Returns a URL when the user's input looks like a URL — either has
    /// an explicit scheme, or looks like a domain we can prepend
    /// https:// to. Returns nil for things that should be treated as a
    /// search query.
    private func directURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(" ") else { return nil }

        if let url = URL(string: trimmed),
            url.scheme != nil, url.host != nil
        {
            return url
        }

        // Looks like a domain (one or more dots, no leading/trailing dot).
        if trimmed.contains("."),
            !trimmed.hasPrefix("."),
            !trimmed.hasSuffix(".")
        {
            return URL(string: "https://\(trimmed)")
        }
        return nil
    }

    // MARK: Row management

    private func rebuildRows() {
        for row in rowViews { row.removeFromSuperview() }
        rowViews.removeAll()

        for (idx, suggestion) in suggestions.enumerated() {
            let row = AXCommandBarRow(suggestion: suggestion, index: idx)
            row.onClick = { [weak self] commitIndex in
                self?.commit(at: commitIndex)
            }
            row.onHover = { [weak self] hoverIndex in
                self?.selectedIndex = hoverIndex
            }
            suggestionsStack.addArrangedSubview(row)

            // Rows need to span the stack's width.
            row.widthAnchor.constraint(
                equalTo: suggestionsStack.widthAnchor,
                constant: -16
            ).isActive = true

            rowViews.append(row)
        }

        separator.isHidden = suggestions.isEmpty
        updateSelectionAppearance()
        onLayoutChange?()
    }

    private func updateSelectionAppearance() {
        for (idx, row) in rowViews.enumerated() {
            row.isHighlighted = (idx == selectedIndex)
        }
    }

    // MARK: Commit / cancel

    private func commit(at index: Int) {
        if let url = suggestions[safe: index]?.resolveURL() {
            onCommit?(url)
            return
        }
        // Nothing selected (or empty list) → fall back to query.
        let query = textField.stringValue
        guard !query.isEmpty else {
            onCancel?()
            return
        }
        onCommit?(AXSearchQueryToURL.shared.convert(query: query))
    }

    // MARK: NSTextFieldDelegate

    func controlTextDidChange(_ obj: Notification) {
        suggestionsManager?.updateSuggestions(with: textField.stringValue)
        rebuildSuggestions()
    }

    func control(
        _ control: NSControl, textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.moveDown(_:)):
            guard !suggestions.isEmpty else { return true }
            selectedIndex = min(selectedIndex + 1, suggestions.count - 1)
            return true
        case #selector(NSResponder.moveUp(_:)):
            guard !suggestions.isEmpty else { return true }
            selectedIndex = max(selectedIndex - 1, 0)
            return true
        case #selector(NSResponder.insertNewline(_:)):
            commit(at: selectedIndex)
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            onCancel?()
            return true
        default:
            return false
        }
    }
}

// MARK: - Row view

@MainActor
final class AXCommandBarRow: NSView {
    static let height: CGFloat = 44

    let suggestion: AXCommandBarSuggestion
    let index: Int
    var onClick: ((Int) -> Void)?
    var onHover: ((Int) -> Void)?

    var isHighlighted: Bool = false {
        didSet { applyAppearance() }
    }

    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private var trackingArea: NSTrackingArea?

    init(suggestion: AXCommandBarSuggestion, index: Int) {
        self.suggestion = suggestion
        self.index = index
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 10
        setupSubviews()
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentTintColor = .secondaryLabelColor
        iconView.symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: 14, weight: .medium)

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .tertiaryLabelColor
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.height),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.leadingAnchor.constraint(
                equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            subtitleLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -16),
            subtitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        titleLabel.setContentCompressionResistancePriority(
            .defaultLow, for: .horizontal)
        subtitleLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func configure() {
        iconView.image = NSImage(
            systemSymbolName: suggestion.symbolName,
            accessibilityDescription: nil)
        titleLabel.stringValue = suggestion.displayTitle
        subtitleLabel.stringValue = suggestion.displaySubtitle
        subtitleLabel.isHidden = suggestion.displaySubtitle.isEmpty
    }

    private func applyAppearance() {
        layer?.backgroundColor =
            isHighlighted
            ? NSColor.controlAccentColor.withAlphaComponent(0.18).cgColor
            : NSColor.clear.cgColor
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [
                .activeInActiveApp, .mouseEnteredAndExited, .inVisibleRect,
            ],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        onHover?(index)
    }

    override func mouseDown(with event: NSEvent) {
        onClick?(index)
    }
}

// MARK: - Tiny helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
