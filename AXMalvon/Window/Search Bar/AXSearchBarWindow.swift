//
//  AXSearchBarWindow.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-25.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
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

    init(parentWindow1: AXWindow) {
        super.init(
            contentRect: .init(x: 0, y: 0, width: 600, height: 274),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.delegate = self
        self.parentWindow1 = parentWindow1
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

    func show() {
        guard !isDisplayed else { return }
        isDisplayed = true
        searchBarDelegate?.searchBarDidAppear()

        self.setFrameOrigin(
            .init(
                x: parentWindow1.frame.midX - 300,
                y: parentWindow1.frame.midY - 137))
        parentWindow1.addChildWindow(self, ordered: .above)
        self.makeKeyAndOrderFront(nil)

        observer()

        _ = searchBarView.searchField.becomeFirstResponder()
    }

    func showCurrentURL() {
        // Implement this
        searchBarDelegate?.searchBarDidAppear()

        self.setFrameOrigin(
            .init(
                x: parentWindow1.frame.midX - 300,
                y: parentWindow1.frame.midY - 137))
        parentWindow1.addChildWindow(self, ordered: .above)
        self.makeKeyAndOrderFront(nil)

        searchBarView.newTabMode = false
        searchBarView.searchField.stringValue =
            searchBarDelegate?.searchBarCurrentWebsiteURL() ?? ""

        let range = NSRange(
            location: 0, length: searchBarView.searchField.stringValue.count)
        let editor = searchBarView.searchField.currentEditor()
        editor?.selectedRange = range

        observer()

        _ = searchBarView.searchField.becomeFirstResponder()
    }

    override func close() {
        isDisplayed = false
        searchBarView.windowClosed()

        searchBarDelegate?.searchBarDidDisappear()
        parentWindow1.removeChildWindow(self)
        removeMouseEventMonitor()

        super.close()
    }

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
