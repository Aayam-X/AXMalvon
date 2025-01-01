//
//  AXSearchSuggestionsManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-30.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import AppKit

class SuggestionsManager {
    private var debounceWorkItem: DispatchWorkItem?
    private var currentTask: URLSessionDataTask?
    private let localDebounceInterval: TimeInterval = 0.15
    private let googleDebounceInterval: TimeInterval = 0.3  // Longer delay for Google suggestions

    var historyManager: AXHistoryManager

    init(historyManager: AXHistoryManager) {
        self.historyManager = historyManager
    }

    // Split callback functions for each type of update
    var onQueryUpdated: ((_ query: String) -> Void)?
    var onTopSearchesUpdated: ((_ searches: [String]) -> Void)?
    var onHistoryUpdated: ((_ history: [(title: String, url: String)]) -> Void)?
    var onGoogleSuggestionsUpdated: ((_ suggestions: [String]) -> Void)?

    func updateSuggestions(with query: String) {
        // Cancel previous work items and tasks
        debounceWorkItem?.cancel()
        currentTask?.cancel()

        // Immediately update query
        onQueryUpdated?(query)

        // Create a single work item that handles both local and Google suggestions
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            // First, update local suggestions
            DispatchQueue.global(qos: .background).async {
                // Update top searches
                let filteredSuggestions = AXSearchDatabase.shared
                    .getRelevantSearchSuggestions(
                        prefix: query,
                        minOccurrences: 3
                    )
                DispatchQueue.main.async {
                    self.onTopSearchesUpdated?(filteredSuggestions)
                }
            }

            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let self = self else { return }
                // Update history
                let historyResults = self.historyManager.search(query: query)
                let filteredWebsites = historyResults.map {
                    ($0.title, $0.address)
                }
                DispatchQueue.main.async {
                    self.onHistoryUpdated?(filteredWebsites)
                }
            }

            // After local suggestions are handled, wait for the additional delay before fetching Google suggestions
            DispatchQueue.main.asyncAfter(
                deadline: .now()
                    + (self.googleDebounceInterval - self.localDebounceInterval)
            ) {
                self.fetchGoogleSuggestions(for: query) { suggestions in
                    DispatchQueue.main.async {
                        self.onGoogleSuggestionsUpdated?(suggestions)
                    }
                }
            }
        }

        // Store the work item for cancellation purposes
        debounceWorkItem = workItem

        // Schedule the work item with the local debounce interval
        DispatchQueue.main.asyncAfter(
            deadline: .now() + localDebounceInterval, execute: workItem)
    }
}

extension SuggestionsManager {
    private func fetchGoogleSuggestions(
        for query: String, completion: @escaping ([String]) -> Void
    ) {
        guard !query.isEmpty else {
            completion([])
            return
        }

        let urlString =
            "https://suggestqueries.google.com/complete/search?client=firefox&q=\(query)"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        currentTask = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }

            do {
                if let jsonArray = try JSONSerialization.jsonObject(
                    with: data, options: []) as? [Any],
                    jsonArray.count > 1,
                    let suggestions = jsonArray[1] as? [String] {
                    completion(suggestions)
                } else {
                    completion([])
                }
            } catch {
                completion([])
            }
        }

        currentTask?.resume()
    }
}
