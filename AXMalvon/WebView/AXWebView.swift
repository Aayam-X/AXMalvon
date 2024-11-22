//
//  AXWebView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

class AXWebView: WKWebView {
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)

        customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1.1 Safari/605.1.15"
        allowsMagnification = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func otherMouseDown(with event: NSEvent) {
        // Support for the Logitech MX Master 3s Mouse
        let buttonNumber = event.buttonNumber

        switch buttonNumber {
        case 3:
            goBack()
            return
        case 4:
            goForward()
            return
        default: break
        }

        super.otherMouseDown(with: event)
    }
}
