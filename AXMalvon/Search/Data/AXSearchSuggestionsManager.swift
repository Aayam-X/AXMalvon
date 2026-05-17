//
//  AXSearchSuggestionsManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

/// Drives the address-bar suggestions row. Pulls three independent feeds —
/// local search-frequency, per-profile history, and Google's autocomplete —
/// and pushes results to its `on*Updated` callbacks. Local lookups hit the
/// SwiftData store on the main actor; the Google query runs in a detached
/// Task to keep the keyboard latency low.
@MainActor
final class SuggestionsManager {
    private var debounceWorkItem: DispatchWorkItem?
    private var googleSuggestionsTask: Task<Void, Never>?
    private let localDebounceInterval: TimeInterval = 0.15
    private let googleDebounceInterval: TimeInterval = 0.3
    private var immediateUpdateCount = 0
    private let maxImmediateUpdates = 3

    /// Nil for private-browsing profiles where history isn't recorded —
    /// the history-suggestion stream silently skips when this is absent.
    var historyManager: AXHistoryManager?

    init(historyManager: AXHistoryManager?) {
        self.historyManager = historyManager
    }

    var onQueryUpdated: (@MainActor (_ query: String) -> Void)?
    var onTopSearchesUpdated: (@MainActor (_ searches: [String]) -> Void)?
    var onHistoryUpdated: (@MainActor (_ history: [(title: String, url: String)]) -> Void)?
    var onGoogleSuggestionsUpdated: (@MainActor (_ suggestions: [String]) -> Void)?

    func updateSuggestions(with query: String) {
        debounceWorkItem?.cancel()
        googleSuggestionsTask?.cancel()

        onQueryUpdated?(query)

        if immediateUpdateCount < maxImmediateUpdates {
            immediateUpdateCount += 1
            performSuggestionsUpdate(query: query)
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.performSuggestionsUpdate(query: query)
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + localDebounceInterval, execute: workItem
        )
    }

    private func performSuggestionsUpdate(query: String) {
        // Local lookups touch the SwiftData mainContext, so they have to
        // run on the main actor. Result sets are bounded (~100s of rows)
        // so the synchronous cost is acceptable. Threshold is 1 — any
        // URL the user has typed before is fair game for autocomplete.
        let topSearches = AXSearchDatabase.shared
            .getRelevantSearchSuggestions(prefix: query, minOccurrences: 1)
        onTopSearchesUpdated?(topSearches)

        let history = historyManager
            .map { $0.search(query: query).map { ($0.title, $0.address) } }
            ?? []
        onHistoryUpdated?(history)

        // Google's autocomplete is a network call — push it off-actor so
        // the address-bar keystroke loop stays snappy.
        let extraDelay = googleDebounceInterval - localDebounceInterval
        googleSuggestionsTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(extraDelay))
            guard !Task.isCancelled, let self else { return }
            let suggestions = await Self.fetchGoogleSuggestions(for: query)
            guard !Task.isCancelled else { return }
            self.onGoogleSuggestionsUpdated?(suggestions)
        }
    }

    private static func fetchGoogleSuggestions(for query: String) async -> [String] {
        guard !query.isEmpty else { return [] }
        guard
            let encoded = query.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed),
            let url = URL(
                string:
                    "https://suggestqueries.google.com/complete/search?client=firefox&q=\(encoded)"
            )
        else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard
                let jsonArray = try JSONSerialization
                    .jsonObject(with: data, options: []) as? [Any],
                jsonArray.count > 1,
                let suggestions = jsonArray[1] as? [String]
            else { return [] }
            return suggestions
        } catch {
            return []
        }
    }
}
