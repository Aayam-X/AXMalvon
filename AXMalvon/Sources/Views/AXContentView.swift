//
//  AXContentView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-03.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXContentView: NSView {
    weak var appProperties: AXSessionProperties!
    private var hasDrawn: Bool = false
    
    override func viewWillDraw() {
        if hasDrawn { return }
        defer { hasDrawn = true }
        
        appProperties.containerView.frame = bounds
        addSubview(appProperties.containerView)
        appProperties.containerView.autoresizingMask = [.height, .width]
    }
    
    init(appProperties: AXSessionProperties!) {
        super.init(frame: .zero)
        self.appProperties = appProperties
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
