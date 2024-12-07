//
//  AXSearchBarWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-25.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

protocol AXSearchBarWindowDelegate: AnyObject {
    func searchBarDidAppear()
    func searchBarDidDisappear()

    func searchBarCreatesNewTab(with url: URL)
    func searchBarUpdatesCurrentTab(with url: URL)

    func searchBarCurrentWebsiteURL() -> String
}

class AXSearchBarWindow: NSPanel, NSWindowDelegate {
    weak var searchBarDelegate: AXSearchBarWindowDelegate?

    unowned var parentWindow1: AXWindow!
    var isDisplayed = false

    lazy var searchBarView = AXSearchFieldPopoverView(searchBarWindow: self)

    private var localMouseDownEventMonitor: Any?

    init() {
        super.init(
            contentRect: .init(x: 0, y: 0, width: 600, height: 274),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.delegate = self
        level = .mainMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovable = false

        backgroundColor = .textBackgroundColor  // NSWindow stuff

        self.contentView = searchBarView
    }

    deinit {
        removeMouseEventMonitor()
    }

    // MARK: - Show/Hide Functions
    func show() {
        guard !isDisplayed else { return }
        isDisplayed = true

        show(
            at: .init(
                x: parentWindow1.frame.midX - 300,
                y: parentWindow1.frame.midY - 137))
    }

    func showCurrentURL() {
        showCurrentURL(
            at:
                .init(
                    x: parentWindow1.frame.midX - 300,
                    y: parentWindow1.frame.midY - 137))
    }

    func show(at point: NSPoint) {
        searchBarDelegate?.searchBarDidAppear()

        self.setFrameOrigin(point)
        parentWindow1.addChildWindow(self, ordered: .above)
        self.makeKeyAndOrderFront(nil)

        observer()

        _ = searchBarView.searchField.becomeFirstResponder()
    }

    func showCurrentURL(at point: NSPoint) {
        searchBarDelegate?.searchBarDidAppear()

        // Position the panel using the screen coordinate
        self.setFrameOrigin(point)
        parentWindow1.addChildWindow(self, ordered: .above)
        self.makeKeyAndOrderFront(nil)

        searchBarView.newTabMode = false
        searchBarView.searchField.stringValue =
            searchBarDelegate?.searchBarCurrentWebsiteURL() ?? ""

        // Select the entire text in the search field
        let range = NSRange(
            location: 0, length: searchBarView.searchField.stringValue.count)
        let editor = searchBarView.searchField.currentEditor()
        editor?.selectedRange = range

        // Set up observers if required
        observer()

        // Make the search field the first responder
        _ = searchBarView.searchField.becomeFirstResponder()
    }

    override func close() {
        isDisplayed = false
        searchBarView.windowClosed()

        searchBarDelegate?.searchBarDidDisappear()

        if parentWindow1 != nil {
            parentWindow1.removeChildWindow(self)
        }

        removeMouseEventMonitor()

        super.close()
    }

    // MARK: - Mouse Monitor
    private func observer() {
        localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) {
                [weak self] event in
                if event.window != self && event.window == self?.parentWindow1 {
                    self?.close()
                    return nil
                }
                return event
            }
    }

    private func removeMouseEventMonitor() {
        if let monitor = localMouseDownEventMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseDownEventMonitor = nil
        }
    }
}
