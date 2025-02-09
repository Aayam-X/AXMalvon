//
//  AXAddressBarWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-24.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

// MARK: - Main Window Class
class AXAddressBarWindow: NSPanel, NSWindowDelegate {
    // MARK: - UI Components
    private let scrollView = NSScrollView()
    
    let view = NSView()
    
    private let currentQueryStackView = NSStackView()
    private let topSitesStackView = NSStackView()
    private let googleSearchStackView = NSStackView()
    private let historyStackView = NSStackView()

    var suggestionItemClickAction: ((String) -> Void)?

    private var highlightedCell: AXAddressBarSuggestionCellView?

    // MARK: - Initialization
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        setupWindow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Methods
    private func setupWindow() {
        backgroundColor = .clear
        isMovable = false
        delegate = self
        
        
        view.wantsLayer = true
        view.layer?.cornerRadius = 9.0
        view.layer?.backgroundColor = .black
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.activateConstraints([
            .width: .constant(800),
            .height: .constant(300),
        ])
        
        self.contentView = view
        
        setupStackViews()
    }
    
    private func setupStackViews() {
        for stackView in [currentQueryStackView, topSitesStackView, googleSearchStackView, historyStackView] {
            stackView.orientation = .vertical
            stackView.alignment = .left
            
            let redView = NSView()
            redView.wantsLayer = true
            redView.layer?.backgroundColor = NSColor.red.cgColor
            
            stackView.addArrangedSubview(redView)
            
            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 1).isActive = true
        }
        
        setupStackViewsConstraints()
    }
    
    private func setupStackViewsConstraints() {
        // Current Query
        currentQueryStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentQueryStackView)
        
        currentQueryStackView.activateConstraints([
            .top: .view(view),
            .left: .view(view, constant: 15),
        ])
        
        // Top Sites
        topSitesStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topSitesStackView)
        
        topSitesStackView.activateConstraints([
            .topBottom: .view(currentQueryStackView, constant: 5),
            .left: .view(view, constant: 15),
        ])
        
        // Google Suggestions
        googleSearchStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(googleSearchStackView)
        
        googleSearchStackView.activateConstraints([
            .topBottom: .view(topSitesStackView, constant: 5),
            .left: .view(view, constant: 15),
        ])
        
        // History
        historyStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(historyStackView)
        
        historyStackView.activateConstraints([
            .topBottom: .view(googleSearchStackView, constant: 5),
            .left: .view(view, constant: 15),
        ])
    }

    // MARK: - Public Methods
    func orderOut() {
        highlightedCell = nil
        super.orderOut(nil)
    }

    func showSuggestions(for textField: NSTextField) {
        updateWindowPosition(for: textField)
    }

    private func updateWindowPosition(for textField: NSTextField) {
        guard let textFieldWindow = textField.window else { return }
        var textFieldRect = textField.convert(textField.bounds, to: nil)
        textFieldRect = textFieldWindow.convertToScreen(textFieldRect)
        textFieldRect.origin.y -= 5
        textFieldRect.origin.x -= 18

        setFrameTopLeftPoint(textFieldRect.origin)

        var frame = self.frame
        frame.size.width = textField.frame.width * 2
        setFrame(frame, display: false)

        textFieldWindow.addChildWindow(self, ordered: .above)
    }
    
    func updateCurrentQuery(_ string: String) {
        Self.updateSuggestions([string], in: currentQueryStackView)
    }
    
    func updateTopSiteItems(_ searches: [String]) {
        Self.updateSuggestions(searches, in: topSitesStackView)
    }
    
    func updateHistoryItems(_ items: [(title: String, url: String)]) {
        let titles = items.map(\.title)
        Self.updateSuggestions(titles, in: historyStackView)
    }
    
    func updateGoogleSuggestionsItems(_ searches: [String]) {
        Self.updateSuggestions(searches, in: googleSearchStackView)
    }
}

// MARK: Private Methods
private extension AXAddressBarWindow {
    static func updateSuggestions(_ suggestions: [String], in stackView: NSStackView) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        suggestions.forEach { suggestion in
            let cell = AXAddressBarSuggestionCellView()
            cell.translatesAutoresizingMaskIntoConstraints = false
            cell.webTitle = suggestion
            stackView.addArrangedSubview(cell)
            cell.activateConstraints([
                .horizontalEdges: .view(stackView)
            ])
        }
    }
}
