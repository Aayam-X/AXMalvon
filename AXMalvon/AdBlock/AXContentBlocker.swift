//
//  AXContentBlocker.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-25.
//

import WebKit

private var ruleStore = WKContentRuleListStore.default()
private let fileURL = Bundle.main.url(
    forResource: "contentBlocker", withExtension: "json")

// Do nothing in debug to allow for faster build times
#if DEBUG
    class AXContentBlockerLoader {
        static let shared = AXContentBlockerLoader()
        func enableAdblock(for config: WKWebViewConfiguration) {}
    }
#else
    class AXContentBlockerLoader {
        static let shared = AXContentBlockerLoader()
        private let dispatchGroup = DispatchGroup()
        private let queue = DispatchQueue(label: "com.app.contentblocker")
        private var isInitialized = false

        private init() {
            // Enter dispatch group before starting initialization
            dispatchGroup.enter()

            ruleStore?.lookUpContentRuleList(forIdentifier: "ContentBlocker") { [weak self] ruleList, error in
                guard let self = self else {
                    self?.dispatchGroup.leave()
                    return
                }

                if let error = error, ruleList == nil {
                    mxPrint("Error looking up rule list: \(error)")
                    self.compileAndLoadRules()
                } else {
                    // Rules already exist, mark as initialized
                    self.queue.async {
                        self.isInitialized = true
                        self.dispatchGroup.leave()
                    }
                }
            }
        }

        func enableAdblock(
            for config: WKWebViewConfiguration, completion: (() -> Void)? = nil
        ) {
            guard let ruleStore = ruleStore else {
                mxPrint("Rule store not initialized.")
                completion?()
                return
            }

            // Wait for rule compilation to complete
            dispatchGroup.notify(queue: .main) { [weak self] in
                guard let self = self else { return }

                // Check if rules are already initialized
                self.queue.sync {
                    if !self.isInitialized {
                        mxPrint("Rules not yet initialized")
                        completion?()
                        return
                    }
                }

                mxPrint("Looking up compiled rules")
                ruleStore.lookUpContentRuleList(forIdentifier: "ContentBlocker") { ruleList, error in
                    if let ruleList = ruleList {
                        config.userContentController.add(ruleList)
                        mxPrint("Successfully added rules to configuration")
                    } else {
                        mxPrint("Error looking up rule list: \(error)")
                    }
                    completion?()
                }
            }
        }

        private func compileAndLoadRules() {
            guard let ruleStore = ruleStore, let fileURL = fileURL else {
                mxPrint("Missing rule store or content blocker file.")
                dispatchGroup.leave()
                return
            }

            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self else {
                    return
                }

                do {
                    let blockerListString = try String(
                        contentsOf: fileURL, encoding: .utf8)

                    ruleStore.compileContentRuleList(
                        forIdentifier: "ContentBlocker",
                        encodedContentRuleList: blockerListString
                    ) { [weak self] ruleList, error in
                        guard let self = self else { return }

                        if let error = error {
                            mxPrint("Failed to compile rules: \(error)")
                        } else if ruleList != nil {
                            mxPrint("Successfully compiled and loaded rules.")
                            self.queue.async {
                                self.isInitialized = true
                            }
                        }
                        self.dispatchGroup.leave()
                    }
                } catch {
                    mxPrint("Failed to load content blocker file: \(error)")
                    self.dispatchGroup.leave()
                }
            }
        }
    }

#endif
