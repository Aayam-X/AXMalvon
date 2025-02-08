//
//  AXBrowserTabView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-07.
//

import AppKit
import WebKit

class AXBrowserTabView: NSTabView {
    
    
    init() {
        super.init(frame: .zero)
        //self.tabViewType = .noTabsNoBorder
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
