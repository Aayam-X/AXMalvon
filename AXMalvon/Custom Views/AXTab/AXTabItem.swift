//
//  AXTabItem.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import AppKit

class AXTabItem {
    var title: String?
    var view: AXWebView
    var position: Int = 0
    var titleObserver: NSKeyValueObservation?
    
    init(view: AXWebView) {
        self.view = view
        
        startObserving()
    }
    
    public func stopObserving() {
        titleObserver?.invalidate()
    }
    
    private func startObserving() {
        titleObserver = self.view.observe(\.title, changeHandler: { [self] webView, value in
            title = webView.title
            // TODO: FIX THIS IMPLEMENTATION
            if let window = NSApplication.shared.keyWindow as? AXWindow {
                window.appProperties.sidebarView.tableView.reloadData()
            }
//            (NSApplication.shared.keyWindow as! AXWindow).appProperties.sidebarView.tableView.reloadData()
//            (view.window as! AXWindow).appProperties.sidebarView.tableView.reloadData()
//            Shared.Action.updateTabTitle(title: webView.title ?? "Untitled", position: self.position)
        })
    }
    
    static public func create() -> AXTabItem {
        let webView = AXWebView()

        webView.addConfigurations()
        webView.layer?.cornerRadius = 5.0
        webView.load(URLRequest(url: URL(string: "https://www.google.com")!))

//        return .init(title: webView, view: 0)
        return .init(view: webView)
    }
    
}
