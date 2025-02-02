//
//  AXContentBlocker.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-25.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import ContentBlockerEngine
import WebKit

private var ruleStore = WKContentRuleListStore.default()
private let fileURL = WBFileStorage.shared.cachedContainerURL?.appending(
    path: "blockerList.json")

class AXContentBlockerLoader {
    static let shared = AXContentBlockerLoader()
    private let dispatchGroup = DispatchGroup()
    private let queue = DispatchQueue(
        label: "com.axmalvon.contentblocker", attributes: .concurrent)
    private var isInitialized = false
    private var cachedRuleList: WKContentRuleList?
    private static var adguardScriptCache: [String] = []

    private init() {
        loadAdguardScripts()
        dispatchGroup.enter()

        ruleStore?.lookUpContentRuleList(forIdentifier: "ContentBlocker") {
            [weak self] ruleList, error in
            guard let self = self else { return }

            if let ruleList = ruleList {
                self.queue.async(flags: .barrier) {
                    self.cachedRuleList = ruleList
                    self.isInitialized = true
                }
                self.dispatchGroup.leave()
            } else {
                mxPrint(
                    "Error looking up rule list: \(error?.localizedDescription ?? "")"
                )
                self.compileAndLoadRules()
            }
        }
    }

    func disableAdBlock(for config: WKWebViewConfiguration) {
        config.userContentController.removeAllContentRuleLists()
        config.userContentController.removeScriptMessageHandler(
            forName: "advancedBlockingData")
    }

    func enableAdblock(
        for config: WKWebViewConfiguration, handler: WKScriptMessageHandler,
        completion: (() -> Void)? = nil
    ) {
        guard ruleStore != nil else {
            mxPrint("Rule store not initialized.")
            completion?()
            return
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            var ready = false
            self.queue.sync { ready = self.isInitialized }

            guard ready else {
                mxPrint("Rules not initialized")
                completion?()
                return
            }

            self.queue.sync {
                if let ruleList = self.cachedRuleList {
                    config.userContentController.add(ruleList)
                    mxPrint("Added precompiled rules to configuration")
                }
            }
            completion?()
        }

        enableAdguardScriptlets(for: config, handler: handler)
    }

    private func compileAndLoadRules() {
        guard let ruleStore = ruleStore, let fileURL = fileURL else {
            mxPrint("Missing rule store or blocker file")
            dispatchGroup.leave()
            return
        }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                let blockerListString = try String(
                    contentsOf: fileURL, encoding: .utf8)

                ruleStore.compileContentRuleList(
                    forIdentifier: "ContentBlocker",
                    encodedContentRuleList: blockerListString
                ) { [weak self] ruleList, error in
                    defer { self?.dispatchGroup.leave() }

                    guard let ruleList = ruleList, error == nil else {
                        mxPrint(
                            "Compilation failed: \(error?.localizedDescription ?? "")"
                        )
                        return
                    }

                    self?.queue.async(flags: .barrier) {
                        self?.cachedRuleList = ruleList
                        self?.isInitialized = true
                    }
                    mxPrint("Rules compiled successfully")
                }
            } catch {
                mxPrint(
                    "Failed loading blocker list: \(error.localizedDescription)"
                )
                self?.dispatchGroup.leave()
            }
        }
    }

    private func loadAdguardScripts() {
        guard Self.adguardScriptCache.isEmpty else { return }

        let scriptPaths = [
            "advanced-script",
            "extended-css",
            "scriptlet",
        ]

        Self.adguardScriptCache = scriptPaths.compactMap { name in
            guard
                let url = Bundle.main.url(
                    forResource: name, withExtension: "js"),
                let source = try? String(contentsOf: url, encoding: .utf8)
            else {
                mxPrint("Missing script: \(name)")
                return nil
            }
            return source
        }
    }

    private func enableAdguardScriptlets(
        for configuration: WKWebViewConfiguration,
        handler: WKScriptMessageHandler
    ) {
        let contentController = configuration.userContentController

        for scriptSource in Self.adguardScriptCache {
            let userScript = WKUserScript(
                source: scriptSource,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            contentController.addUserScript(userScript)
        }

        contentController.add(handler, name: "advancedBlockingData")
    }
}

actor ContentBlockerEngineWrapper {
    static let shared = ContentBlockerEngineWrapper()
    private let contentBlockerEngine: ContentBlockerEngine

    private init() {
        let json = Self.loadAdvancedRules()
        do {
            contentBlockerEngine = try ContentBlockerEngine(json)
        } catch {
            mxPrint("Content blocker init failed: \(error)")
            contentBlockerEngine = try! ContentBlockerEngine("[]")
        }
    }

    private static func loadAdvancedRules() -> String {
        (try? WBFileStorage.shared.loadJSON(filename: "advancedBlocking.json"))
            ?? "[]"
    }

    func getData(url: URL) throws -> String {
        try contentBlockerEngine.getData(url: url)
    }
}
