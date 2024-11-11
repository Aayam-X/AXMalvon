//
//  AXWebView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-05.
//

import AppKit
import WebKit

class AXWebView: WKWebView {
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
//        configuration.preferences.setValue(true, forKey: "offlineApplicationCacheIsEnabled")
//        configuration.preferences.setValue(true, forKey: "fullScreenEnabled")
//        configuration.preferences.setValue(true, forKey: "allowsPictureInPictureMediaPlayback")
//        configuration.preferences.setValue(true, forKey: "acceleratedDrawingEnabled")
//        configuration.preferences.setValue(true, forKey: "largeImageAsyncDecodingEnabled")
//        configuration.preferences.setValue(true, forKey: "animatedImageAsyncDecodingEnabled")
//        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
//        configuration.preferences.setValue(true, forKey: "loadsImagesAutomatically")
//        configuration.preferences.setValue(true, forKey: "acceleratedCompositingEnabled")
//        configuration.preferences.setValue(true, forKey: "canvasUsesAcceleratedDrawing")
//        configuration.preferences.setValue(true, forKey: "localFileContentSniffingEnabled")
//        configuration.preferences.setValue(true, forKey: "usesPageCache")
//        configuration.preferences.setValue(true, forKey: "aggressiveTileRetentionEnabled")
//        configuration.preferences.setValue(true, forKey: "appNapEnabled")
//        configuration.preferences.setValue(true, forKey: "aggressiveTileRetentionEnabled")
//        configuration.preferences.setValue(false, forKey: "backspaceKeyNavigationEnabled")
        super.init(frame: frame, configuration: configuration)
        
        
        customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Safari/605.1.15"
        allowsMagnification = true
        self.layer?.borderColor = NSColor.controlAccentColor.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isOpaque: Bool { false }
}
