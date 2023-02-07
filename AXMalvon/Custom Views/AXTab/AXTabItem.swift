//
//  AXTabItem.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

let newtabURL = Bundle.main.url(forResource: "newtab", withExtension: "html")

class AXTabItem {
    var title: String?
    var url: URL?
    var view: AXWebView
    
    init(view: AXWebView) {
        self.view = view
    }
    
    func load() {
        if let url = url {
            view.load(URLRequest(url: url))
        }
    }
}
