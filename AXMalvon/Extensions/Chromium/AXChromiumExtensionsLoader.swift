//
//  AXChromiumExtensionsLoader.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-04.
//

import WebKit

@MainActor
private var userScript: WKUserScript? = nil

@MainActor
func loadChromiumRuntime() {
    let filePath = Bundle.main.path(
        forResource: "chromium_runtime", ofType: "js")!
    let chromiumScript = try? String(contentsOfFile: filePath, encoding: .utf8)

    if let chromiumScript = chromiumScript {
        userScript = WKUserScript(
            source: chromiumScript, injectionTime: .atDocumentStart,
            forMainFrameOnly: false)
    }
}

@MainActor
func enableChromiumAPIs(
    for configuration: WKWebViewConfiguration,
    handler: WKScriptMessageHandler
) {
    let contentController = configuration.userContentController

    if let userScript = userScript {
        contentController.addUserScript(userScript)
        contentController.add(handler, name: "chromeRuntime")
    } else {
        loadChromiumRuntime()
        if let userScript = userScript {
            contentController.addUserScript(userScript)
            contentController.add(handler, name: "chromeRuntime")
        }
    }
}
