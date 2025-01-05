//
//  AXWindow+MenuActions.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import Carbon.HIToolbox
import WebKit

extension AXWindow {
    @IBAction func toggleSearchField(_ sender: Any?) {
        makeFirstResponder(layoutManager.searchButton.addressField)
    }

    @IBAction func toggleSearchBarForNewTab(_ sender: Any?) {
        let config = activeProfile.configuration

        currentTabGroup.addEmptyTab(configuration: config)
    }

    @IBAction func find(_ sender: Any) {
        layoutManager.containerView.webViewPerformSearch()
    }

    @IBAction func backWebpage(_ sender: Any?) {
        layoutManager.containerView.back()
    }

    @IBAction func forwardWebpage(_ sender: Any?) {
        layoutManager.containerView.forward()
    }

    @IBAction func reloadWebpage(_ sender: Any?) {
        layoutManager.containerView.reload()
    }

    @IBAction func downloadWebpage(_ sender: Any) {
        // This code doesn't work
        //        Task { @MainActor in
        //            if let webView = layoutManager.containerView.currentWebView,
        //               let url = webView.url {
        //                await webView.startDownload(using: URLRequest(url: url))
        //            }
        //        }
    }

    @IBAction func enableContentBlockers(_ sender: Any) {
        activeProfile.enableContentBlockers()
    }

    @IBAction func enableYouTubeAdBlocker(_ sender: Any) {
        if let sender = sender as? NSMenuItem {
            sender.title = "Disable YouTube Ad Blocker (Restart App)"
        }

        activeProfile.enableYouTubeAdBlocker()
    }

    @IBAction func closeTab(_ sender: Any) {
        guard currentTabGroup.tabs.count != 0 else {
            self.close()
            return
        }

        currentTabGroup.removeCurrentTab()
    }

    @IBAction func closeWindow(_ sender: Any) {
        self.close()
    }

    @IBAction func switchViewLayout(_ sender: Any?) {
        usesVerticalTabs.toggle()

        layoutManager.removeLayout(in: self)

        let newTabBarView: AXTabBarViewTemplate =
            usesVerticalTabs
            ? AXVerticalTabBarView(tabGroup: currentTabGroup)
            : AXHorizontalTabBarView(tabGroup: currentTabGroup)
        self.tabBarView = newTabBarView

        let newLayoutManager =
            usesVerticalTabs
            ? AXVerticalLayoutManager(tabBarView: newTabBarView)
            : AXHorizontalLayoutManager(tabBarView: newTabBarView)
        self.layoutManager = newLayoutManager

        layoutManager.tabHostingDelegate = self
        layoutManager.setupLayout(in: self)
        layoutManager.searchButton.delegate = self
        tabBarView.delegate = self
        layoutManager.containerView.delegate = self

        self.setFrame(
            AXWindow.updateWindowFrame(), display: true, animate: true)

        currentTabGroupIndex = 0
        self.switchToTabGroup(currentTabGroup)
    }

    @IBAction func showHideSidebar(_ sender: Any) {
        guard let layoutManager = layoutManager as? AXVerticalLayoutManager
        else { return }
        let sidebarState = layoutManager.toggleTabSidebar(in: self)

        sidebarState ? trafficLightsPositionCompact() : trafficLightsPosition()
    }

    //    @IBAction func importCookiesFromChrome(_ sender: Any) {
    //        guard let webView = containerView.currentWebView else { return }
    //
    //        ChromeCookieImporter.importChromeCookes(into: webView) { result in
    //            mxPrint("Chrome Import Cookie Result, Successful cookies: \(result)")
    //        }
    //    }

    @IBAction func showReaderView(_ sender: Any) {
        // This code crashes the browser for some reason: toggleTabSidebar()
        //        guard let webView = layoutManager.containerView.currentWebView else { return }
        //
        //        let readerScript = """
        //            (function() {
        //                let article = document.querySelector('article') ||
        //                              document.querySelector('main') ||
        //                              document.querySelector('[role="main"]') ||
        //                              document.body;
        //                return article ? article.innerHTML : null;
        //            })();
        //            """
        //
        //        let css = """
        //            <style>
        //                body {
        //                    font-family: -apple-system, Helvetica, Arial, sans-serif;
        //                    line-height: 1.6;
        //                    padding: 20vh 20vw;
        //                    background-color: #f8f8f8;
        //                    color: #333;
        //                }
        //
        //                img {
        //                    max-width: 100%;
        //                    height: auto;
        //                }
        //            </style>
        //            """
        //
        //        webView.evaluateJavaScript(readerScript) { result, error in
        //            if let content = result as? String {
        //                // self.showReaderView(content: content)
        //                mxPrint("WebView reader content: \(content)")
        //
        //                if let currentURL = webView.url {
        //                    webView.loadHTMLString(css + content, baseURL: currentURL)
        //                }
        //            } else {
        //                mxPrint(
        //                    "Error extracting content: \(String(describing: error))")
        //            }
        //        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }

        switch Int(event.keyCode) {
        case kVK_ANSI_T:
            toggleSearchBarForNewTab(nil)
            return true
        case kVK_ANSI_L:
            toggleSearchField(nil)
            return true
        case kVK_ANSI_W:
            if currentTabGroup.tabs.isEmpty {
                self.close()
                return true
            }
            currentTabGroup.removeCurrentTab()
            return true
        default:
            if let tabNumber = keycodeMap[event.keyCode] {
                switchToTab(index: tabNumber)
                return true
            }
        }

        return super.performKeyEquivalent(with: event)
    }

    func switchToTab(index: Int) {
        let count = currentTabGroup.tabs.count

        // Check if the tab index is valid
        if index < count {
            currentTabGroup.switchTab(toIndex: index)
        } else {
            guard count > 0 else { return }
            // Switch to the last tab if the index is out of range
            currentTabGroup.switchTab(toIndex: count - 1)
        }
    }
}

private let keycodeMap: [UInt16: Int] = [
    18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5,
    26: 6, 28: 7, 25: 8,
]
