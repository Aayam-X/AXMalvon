//
//  AXWebView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit
import WebKit

private let safariUserAgent =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15"

class AXWebView: WKWebView {    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)

        self.customUserAgent = safariUserAgent
        allowsMagnification = true

        widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive =
            true
        heightAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive =
            true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func otherMouseDown(with event: NSEvent) {
        // Support for the Logitech MX Master 3s Mouse

        switch event.buttonNumber {
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

extension WKWebViewConfiguration {
    func enableDefaultMalvonPreferences() {
        for pref in STATIC_WebViewPreferences {
            preferences.setValue(true, forKey: pref)
        }

        preferences.isElementFullscreenEnabled = true
        preferences.setValue(false, forKey: "backspaceKeyNavigationEnabled")
    }
}

private let STATIC_WebViewPreferences = [
    "allowsPictureInPictureMediaPlayback",
    "appNapEnabled",
    "acceleratedCompositingEnabled",
    "webGLEnabled",
    "largeImageAsyncDecodingEnabled",
    "mediaSourceEnabled",
    "acceleratedDrawingEnabled",
    "animatedImageAsyncDecodingEnabled",
    "developerExtrasEnabled",
    "canvasUsesAcceleratedDrawing",
]
