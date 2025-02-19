//
//  WBBlockerListManager.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-02.
//

import AppKit
import Combine
import ContentBlockerConverter
import UserNotifications
import os.log

enum FilterListCategory: String, CaseIterable, Identifiable, Codable {
    case all = "All"
    case ads = "Ads"
    case privacy = "Privacy"
    case security = "Security"
    case multipurpose = "Multipurpose"
    case annoyances = "Annoyances"
    case experimental = "Experimental"
    case custom = "Custom"
    case foreign = "Foreign"
    var id: String { self.rawValue }
}

struct FilterList: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let url: URL
    let category: FilterListCategory
    var isSelected: Bool = false
    var description: String = ""
    var version: String = ""
}

@MainActor
class FilterListManager: ObservableObject {
    @Published var filterLists: [FilterList] = []
    @Published var isUpdating = false
    @Published var progress: Float = 0
    @Published var missingFilters: [FilterList] = []
    @Published var showProgressView = false
    @Published var availableUpdates: [FilterList] = []
    @Published var showingUpdatePopup = false
    @Published var hasUnappliedChanges = false
    @Published var showMissingFiltersSheet = false
    @Published var showRecommendedFiltersAlert = false
    @Published var showResetToDefaultAlert = false
    @Published var showingNoUpdatesAlert = false

    private let customFilterListsKey = "customFilterLists"

    var customFilterLists: [FilterList] = []

    init() {
        loadFilterLists()
        loadSelectedState()
        checkAndCreateBlockerList()
        checkAndEnableFilters()
        Task { await updateMissingVersions() }  // Combine tasks
    }

    func loadFilterLists() {
        if let data = UserDefaults.standard.data(forKey: "filterLists"),
            let savedFilterLists = try? JSONDecoder().decode(
                [FilterList].self, from: data)
        {
            filterLists = savedFilterLists
        } else {
            filterLists = [
                FilterList(
                    id: UUID(), name: "AdGuard Base Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/2_optimized.txt"
                    )!, category: .ads, isSelected: true,
                    description: "Comprehensive ad-blocking rules by AdGuard."),
                FilterList(
                    id: UUID(), name: "AdGuard Tracking Protection Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/4_optimized.txt"
                    )!, category: .privacy, isSelected: true,
                    description:
                        "Blocks online tracking and web analytics systems."),
                FilterList(
                    id: UUID(), name: "AdGuard Annoyances Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/14_optimized.txt"
                    )!, category: .annoyances,
                    description:
                        "Removes cookie notices, in-page pop-ups, and other annoyances."
                ),
                FilterList(
                    id: UUID(), name: "AdGuard Social Media Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/3_optimized.txt"
                    )!, category: .annoyances,
                    description: "Blocks social media widgets and buttons."),
                FilterList(
                    id: UUID(), name: "Fanboy's Annoyances Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/122_optimized.txt"
                    )!, category: .annoyances,
                    description:
                        "Hides in-page pop-ups, banners, and other unwanted page elements."
                ),
                FilterList(
                    id: UUID(), name: "Fanboy's Social Blocking List",
                    url: URL(
                        string: "https://easylist.to/easylist/fanboy-social.txt"
                    )!, category: .annoyances,
                    description: "Blocks social media content on webpages."),
                FilterList(
                    id: UUID(), name: "EasyPrivacy",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/118_optimized.txt"
                    )!, category: .privacy, isSelected: true,
                    description:
                        "Blocks tracking scripts, web beacons, and other privacy-invasive elements."
                ),
                FilterList(
                    id: UUID(), name: "Online Malicious URL Blocklist",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/208_optimized.txt"
                    )!, category: .security, isSelected: true,
                    description:
                        "Protects against malicious URLs, phishing sites, and malware."
                ),
                FilterList(
                    id: UUID(), name: "Peter Lowe's Blocklist",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/204_optimized.txt"
                    )!, category: .multipurpose, isSelected: true,
                    description:
                        "Blocks ads and tracking servers to enhance privacy."),
                FilterList(
                    id: UUID(), name: "Hagezi Pro Mini",
                    url: URL(
                        string:
                            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.mini.txt"
                    )!, category: .multipurpose, isSelected: true,
                    description:
                        "Extensive blocklist targeting ads, trackers, and other unwanted content."
                ),
                FilterList(
                    id: UUID(), name: "d3Host List by d3ward",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/d3ward/toolz/master/src/d3host.adblock"
                    )!, category: .multipurpose, isSelected: true,
                    description:
                        "Comprehensive block list for ads and trackers."),
                FilterList(
                    id: UUID(), name: "Anti-Adblock List",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/207_optimized.txt"
                    )!, category: .multipurpose, isSelected: true,
                    description:
                        "Bypasses Anti-Adblock scripts used on some websites."),
                FilterList(
                    id: UUID(), name: "AdGuard Experimental Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/5_optimized.txt"
                    )!, category: .experimental,
                    description:
                        "Contains new rules and fixes not yet included in other filters."
                ),

                // --- Foreign Filter Lists ---
                // Spanish
                FilterList(
                    id: UUID(), name: "AdGuard Spanish/Portuguese Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/refs/heads/master/platforms/extension/safari/filters/9_optimized.txt"
                    )!, category: .foreign),

                // French
                FilterList(
                    id: UUID(), name: "Liste FR + AdGuard French Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/platforms/extension/safari/filters/16_optimized.txt"
                    )!, category: .foreign),

                // German
                FilterList(
                    id: UUID(),
                    name: "EasyList Germany + AdGuard German Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/refs/heads/master/platforms/extension/safari/filters/6_optimized.txt"
                    )!, category: .foreign),

                // Russian
                FilterList(
                    id: UUID(), name: "AdGuard Russian Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/refs/heads/master/platforms/extension/safari/filters/1_optimized.txt"
                    )!, category: .foreign),

                // Dutch
                FilterList(
                    id: UUID(), name: "AdGuard Dutch Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/refs/heads/master/platforms/extension/safari/filters/8_optimized.txt"
                    )!, category: .foreign),

                // Japanese
                FilterList(
                    id: UUID(), name: "AdGuard Japanese Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/refs/heads/master/platforms/extension/safari/filters/7_optimized.txt"
                    )!, category: .foreign),

                // Turkish
                FilterList(
                    id: UUID(), name: "AdGuard Turkish Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/refs/heads/master/platforms/extension/safari/filters/13_optimized.txt"
                    )!, category: .foreign),

                // Chinese
                FilterList(
                    id: UUID(), name: "AdGuard Chinese Filter",
                    url: URL(
                        string:
                            "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/refs/heads/master/platforms/extension/safari/filters/224_optimized.txt"
                    )!, category: .foreign),
            ]

            // Use resetToDefaultLists to set the correct default selections
            resetToDefaultLists()
        }

        loadCustomFilterLists()
    }

    private func loadSelectedState() {
        let defaults = UserDefaults.standard
        for (index, filter) in filterLists.enumerated() {
            filterLists[index].isSelected = defaults.bool(
                forKey: "filter_\(filter.name)")
        }
    }

    private func saveSelectedState() {
        let defaults = UserDefaults.standard
        for filter in filterLists {
            defaults.set(filter.isSelected, forKey: "filter_\(filter.name)")
        }
    }

    private func saveFilterLists() {
        if let data = try? JSONEncoder().encode(filterLists) {
            UserDefaults.standard.set(data, forKey: "filterLists")
        } else {
            print("Failed to encode filterLists for saving.")
        }
    }

    /// Checks if selected filters exist, downloads if missing
    func checkAndEnableFilters() {
        missingFilters.removeAll()
        for filter in filterLists where filter.isSelected {
            if !filterFileExists(filter) {
                missingFilters.append(filter)
            }
        }
        if !missingFilters.isEmpty {
            showMissingFiltersSheet = true
        } else {
            Task {
                await applyChanges()
            }
        }
    }

    /// Checks if a filter file exists locally
    private func filterFileExists(_ filter: FilterList) -> Bool {
        guard let containerURL = getSharedContainerURL() else { return false }
        let fileURL = containerURL.appendingPathComponent("\(filter.name).json")
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    func applyChanges() async {
        showProgressView = true
        isUpdating = true
        progress = 0

        let selectedFilters = filterLists.filter { $0.isSelected }
        let totalSteps = Float(selectedFilters.count)
        var completedSteps: Float = 0

        var allRules: [[String: Any]] = []
        var advancedRules: [[String: Any]] = []

        // Collect all rules first
        await withTaskGroup(
            of: (FilterList, [[String: Any]], [[String: Any]]?).self
        ) { group in
            for filter in selectedFilters {
                group.addTask {
                    if await !self.filterFileExists(filter) {
                        let success = await self.fetchAndProcessFilter(filter)
                        if !success {
                            print(
                                "Failed to fetch and process filter: \(filter.name)"
                            )
                            return (filter, [], nil)
                        }
                    }
                    let result =
                        await self.loadFilterRules(for: filter) ?? ([], nil)
                    return (filter, result.0, result.1)
                }
            }

            for await (_, rules, advanced) in group {
                allRules.append(contentsOf: rules)
                if let advanced = advanced {
                    advancedRules.append(contentsOf: advanced)
                }
                completedSteps += 1
                progress = completedSteps / totalSteps
            }
        }

        // Check rule count
        let totalRuleCount = allRules.count + advancedRules.count
        if totalRuleCount > 150000 {
            // Show alert and abort
            await MainActor.run {
                let alert = NSAlert()
                alert.messageText = "Too Many Rules"
                alert.informativeText =
                    "The selected filters would create \(totalRuleCount) rules, which exceeds the maximum limit of 150,000. Please disable some filters and try again."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()

                self.isUpdating = false
                self.showProgressView = false
            }
            return
        }

        saveBlockerList(allRules)
        saveAdvancedBlockerList(advancedRules)
        await reloadContentBlocker()

        self.hasUnappliedChanges = false
        self.isUpdating = false
        self.showProgressView = false
    }

    private func loadFilterRules(for filter: FilterList) -> (
        [[String: Any]], [[String: Any]]?
    )? {
        guard let containerURL = getSharedContainerURL() else { return nil }
        let fileURL = containerURL.appendingPathComponent("\(filter.name).json")
        let advancedFileURL = containerURL.appendingPathComponent(
            "\(filter.name)_advanced.json")

        do {
            let data = try Data(contentsOf: fileURL)
            let rules =
                try JSONSerialization.jsonObject(with: data, options: [])
                as? [[String: Any]]

            var advancedRules: [[String: Any]]? = nil
            if FileManager.default.fileExists(atPath: advancedFileURL.path) {
                let advancedData = try Data(contentsOf: advancedFileURL)
                advancedRules =
                    try JSONSerialization.jsonObject(
                        with: advancedData, options: []) as? [[String: Any]]
            }

            return (rules ?? [], advancedRules)
        } catch {
            print("Error loading rules for \(filter.name): \(error)")
            return nil
        }
    }

    private func saveBlockerList(_ rules: [[String: Any]]) {
        do {
            if let jsonData = try? JSONSerialization.data(
                withJSONObject: rules, options: []),
                let jsonString = String(data: jsonData, encoding: .utf8)
            {
                try WBFileStorage.shared.saveJSON(
                    jsonString, filename: "blockerList.json")

                // Only store the state in UserDefaults
                let containerDefaults = UserDefaults.standard
                containerDefaults.set(true, forKey: "blockerList")
                containerDefaults.synchronize()

                print("Successfully saved blockerList to file storage")
            } else {
                print("Error: Unable to serialize blockerList JSON data")
            }
        } catch {
            print("Error saving blockerList: \(error)")
        }
    }

    private func saveAdvancedBlockerList(_ rules: [[String: Any]]) {
        do {
            if let jsonData = try? JSONSerialization.data(
                withJSONObject: rules, options: []),
                let jsonString = String(data: jsonData, encoding: .utf8)
            {
                try WBFileStorage.shared.saveJSON(
                    jsonString, filename: "advancedBlocking.json")

                // Only store the state in UserDefaults
                let containerDefaults = UserDefaults.standard
                containerDefaults.set(true, forKey: "advancedBlocking")
                containerDefaults.synchronize()

                print("Successfully saved advancedBlocking to file storage")
            } else {
                print("Error: Unable to serialize advancedBlocking JSON data")
            }
        } catch {
            print("Error saving advancedBlocking: \(error)")
        }
    }

    func updateMissingFilters() async {
        showProgressView = true
        isUpdating = true
        progress = 0

        let totalSteps = Float(missingFilters.count)
        var completedSteps: Float = 0

        for filter in missingFilters {
            let success = await fetchAndProcessFilter(filter)
            if success {
                missingFilters.removeAll { $0.id == filter.id }
            }
            completedSteps += 1
            progress = completedSteps / totalSteps
        }

        await applyChanges()
        isUpdating = false
    }

    /// Fetches, processes, and saves a filter list
    private func fetchAndProcessFilter(_ filter: FilterList) async -> Bool {
        do {
            let (data, response) = try await URLSession.shared.data(
                from: filter.url)
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200,
                let content = String(data: data, encoding: .utf8)
            else {
                print("Failed to fetch \(filter.name)")  // More concise logging
                return false
            }

            let metadata = parseMetadata(from: content)
            if let index = filterLists.firstIndex(where: { $0.id == filter.id })
            {
                filterLists[index].version = metadata.version ?? "Unknown"
                filterLists[index].description = metadata.description ?? ""
            }
            saveFilterLists()

            try? content.write(
                to: getSharedContainerURL()?.appendingPathComponent(
                    "\(filter.name).txt") ?? URL(fileURLWithPath: ""),
                atomically: true, encoding: .utf8)

            let filteredRules = content.components(separatedBy: .newlines)
                .filter {
                    !$0.isEmpty && !$0.hasPrefix("!") && !$0.hasPrefix("[")
                }

            await convertAndSaveRules(filteredRules, for: filter)
            return true
        } catch {
            print("Error fetching \(filter.name): \(error)")  // More concise logging
            return false
        }
    }

    func updateMissingVersions() async {
        for index in filterLists.indices {
            let filter = filterLists[index]
            if filter.version.isEmpty && filterFileExists(filter) {
                if let newVersion = await fetchVersionFromURL(for: filter) {
                    filterLists[index].version = newVersion
                    print("Fetched version for \(filter.name): \(newVersion)")
                } else {
                    print("Failed to fetch version for \(filter.name)")
                }
            }
        }
        saveFilterLists()
    }

    private func fetchVersionFromURL(for filter: FilterList) async -> String? {
        do {
            let (data, response) = try await URLSession.shared.data(
                from: filter.url)
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                print(
                    "Failed to fetch version from URL for \(filter.name): Invalid response"
                )
                return nil
            }
            guard let content = String(data: data, encoding: .utf8) else {
                print("Unable to parse content from \(filter.url)")
                return nil
            }

            // Parse metadata for version
            let metadata = parseMetadata(from: content)
            return metadata.version ?? "Unknown"
        } catch {
            print(
                "Error fetching version from URL for \(filter.name): \(error.localizedDescription)"
            )
            return nil
        }
    }

    func parseMetadata(from content: String) -> (
        title: String?, description: String?, version: String?
    ) {
        var title: String?
        var description: String?
        var version: String?

        let regexPatterns = [
            "Title": "^!\\s*Title\\s*:?\\s*(.*)$",
            "Description": "^!\\s*Description\\s*:?\\s*(.*)$",
            "Version": "^!\\s*(?:version|last modified|updated)\\s*:?\\s*(.*)$",
        ]

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            for (key, pattern) in regexPatterns {
                if let regex = try? NSRegularExpression(
                    pattern: pattern, options: [.caseInsensitive]),
                    let match = regex.firstMatch(
                        in: trimmedLine, options: [],
                        range: NSRange(
                            location: 0, length: trimmedLine.utf16.count)),
                    match.numberOfRanges > 1,
                    let range = Range(match.range(at: 1), in: trimmedLine)
                {
                    let value = String(trimmedLine[range]).trimmingCharacters(
                        in: .whitespaces)
                    switch key {
                    case "Title":
                        title = value
                    case "Description":
                        description = value
                    case "Version":
                        version = value
                    default:
                        break
                    }
                }
            }

            // Break early if all metadata are found
            if title != nil && description != nil && version != nil {
                break
            }
        }

        return (title, description, version)
    }

    /// Converts Adblock rules to Safari-compatible JSON and saves them
    private func convertAndSaveRules(_ rules: [String], for filter: FilterList)
        async
    {  // Consolidated JSON saving logic
        let converter = ContentBlockerConverter()
        let result = converter.convertArray(
            rules: rules, safariVersion: .safari16_4, optimize: true,
            advancedBlocking: true)

        guard let containerURL = getSharedContainerURL() else { return }

        func saveJson(data: String?, filename: String) {
            guard let jsonData = data?.data(using: .utf8),
                let jsonArray = try? JSONSerialization.jsonObject(
                    with: jsonData) as? [[String: Any]],
                let limitedJsonData = try? JSONSerialization.data(
                    withJSONObject: Array(
                        jsonArray.prefix(result.convertedCount)),
                    options: .prettyPrinted)
            else { return }

            try? limitedJsonData.write(
                to: containerURL.appendingPathComponent(filename))
            print("Wrote \(filename)")
        }

        saveJson(data: result.converted, filename: "\(filter.name).json")
        saveJson(
            data: result.advancedBlocking,
            filename: "\(filter.name)_advanced.json")
    }

    private func enableFilter(_ filter: FilterList) {
        print("Enabling filter: \(filter.name)")
    }

    /// Retrieves the shared container URL
    private func getSharedContainerURL() -> URL? {
        return WBFileStorage.shared.cachedContainerURL
    }

    func reloadContentBlocker() async {  // More robust error handling
        do {
            let ruleCount =
                try
                (JSONSerialization.jsonObject(
                    with: WBFileStorage.shared.loadJSON(
                        filename: "blockerList.json"
                    ).data(using: .utf8)!) as? [[String: Any]])?.count ?? 0
            print("Reloading content blocker (\(ruleCount) rules)")

            //try await SFContentBlockerManager.reloadContentBlocker(withIdentifier: contentBlockerIdentifier)
            print("Content blocker reloaded")
        } catch {
            print("Error reloading content blocker: \(error)")
        }
    }

    func checkAndCreateBlockerList() {
        guard let containerURL = getSharedContainerURL() else {
            print("Error: Unable to access shared container")
            return
        }

        let blockerListURL = containerURL.appendingPathComponent(
            "blockerList.json")

        if !FileManager.default.fileExists(atPath: blockerListURL.path) {
            print("blockerList.json not found. Creating it...")
            let selectedFilters = filterLists.filter { $0.isSelected }
            var allRules: [[String: Any]] = []
            var advancedRules: [[String: Any]] = []

            for filter in selectedFilters {
                if let (rules, advanced) = loadFilterRules(for: filter) {
                    allRules.append(contentsOf: rules)
                    if let advanced = advanced {
                        advancedRules.append(contentsOf: advanced)
                    }
                }
            }

            saveBlockerList(allRules)
            saveAdvancedBlockerList(advancedRules)
        } else {
            print("blockerList.json found.")
        }
    }

    func toggleFilterListSelection(id: UUID) {
        if let index = filterLists.firstIndex(where: { $0.id == id }) {
            filterLists[index].isSelected.toggle()
            saveSelectedState()
            hasUnappliedChanges = true
        }
    }

    func filterLists(for category: FilterListCategory) -> [FilterList] {
        category == .all
            ? filterLists : filterLists.filter { $0.category == category }
    }

    func checkForUpdates() async {
        availableUpdates.removeAll()

        let enabledFilters = filterLists.filter { $0.isSelected }

        await withTaskGroup(of: FilterList?.self) { group in
            for filter in enabledFilters {
                group.addTask {
                    if await self.hasUpdate(for: filter) {
                        return filter
                    } else {
                        return nil
                    }
                }
            }

            for await filter in group {
                if let filter = filter {
                    availableUpdates.append(filter)
                }
            }
        }

        if !availableUpdates.isEmpty {
            showingUpdatePopup = true
        } else {
            showingNoUpdatesAlert = true
            print("No updates available.")
        }
    }

    /// Automatically updates filters and returns the list of updated filters
    func autoUpdateFilters() async -> [FilterList] {
        var updatedFilters: [FilterList] = []

        isUpdating = true
        showProgressView = true
        progress = 0

        let enabledFilters = filterLists.filter { $0.isSelected }
        let totalSteps = Float(enabledFilters.count)
        var completedSteps: Float = 0

        await withTaskGroup(of: (FilterList, Bool).self) { group in
            for filter in enabledFilters {
                group.addTask {
                    if await self.hasUpdate(for: filter) {
                        let success = await self.fetchAndProcessFilter(filter)
                        return (filter, success)
                    } else {
                        return (filter, false)
                    }
                }
            }

            for await (filter, success) in group {
                if success {
                    updatedFilters.append(filter)
                }
                completedSteps += 1
                progress = completedSteps / totalSteps
            }
        }

        if !updatedFilters.isEmpty {
            await applyChanges()
            print(
                "Applied updates to filters: \(updatedFilters.map { $0.name }.joined(separator: ", "))"
            )
        } else {
            print("No updates found for current filters.")
        }

        isUpdating = false
        showProgressView = false

        return updatedFilters
    }

    /// Checks if a filter has an update by comparing online content with local content
    private func hasUpdate(for filter: FilterList) async -> Bool {
        guard let containerURL = getSharedContainerURL() else { return false }
        let fileURL = containerURL.appendingPathComponent("\(filter.name).txt")

        do {
            let (data, _) = try await URLSession.shared.data(from: filter.url)
            let onlineContent = String(data: data, encoding: .utf8) ?? ""

            if FileManager.default.fileExists(atPath: fileURL.path) {
                let localContent = try String(
                    contentsOf: fileURL, encoding: .utf8)
                return onlineContent != localContent
            } else {
                return true  // If local file doesn't exist, consider it as needing an update
            }
        } catch {
            print(
                "Error checking update for \(filter.name): \(error.localizedDescription)"
            )
            return false
        }
    }

    func updateSelectedFilters(_ selectedFilters: [FilterList]) async {
        showProgressView = true
        isUpdating = true
        progress = 0

        let totalSteps = Float(selectedFilters.count)
        var completedSteps: Float = 0

        for filter in selectedFilters {
            let success = await fetchAndProcessFilter(filter)
            if success {
                if let index = availableUpdates.firstIndex(where: {
                    $0.id == filter.id
                }) {
                    availableUpdates.remove(at: index)
                }
                print("Successfully updated \(filter.name)")
            } else {
                print("Failed to update \(filter.name)")
            }
            completedSteps += 1
            progress = completedSteps / totalSteps
        }

        await applyChanges()
        isUpdating = false
        showProgressView = false
    }

    func resetToDefaultLists() {
        // Reset all filters to unselected first
        for index in filterLists.indices {
            filterLists[index].isSelected = false
        }

        // Enable only the recommended filters
        let recommendedFilters = [
            "AdGuard Base Filter",
            "AdGuard Tracking Protection Filter",
            "AdGuard Annoyances Filter",
            "EasyPrivacy",
            "Online Malicious URL Blocklist",
            "d3Host List by d3ward",
            "Anti-Adblock List",
        ]

        for index in filterLists.indices {
            if recommendedFilters.contains(filterLists[index].name) {
                filterLists[index].isSelected = true
            }
        }

        saveSelectedState()
        hasUnappliedChanges = true
        print("Reset to default recommended filters")

        // Check for missing filters
        checkAndEnableFilters()
    }

    // Make sure you're not running the app without filters on!
    func checkForEnabledFilters() {
        let enabledFilters = filterLists.filter { $0.isSelected }
        if enabledFilters.isEmpty {
            showRecommendedFiltersAlert = true
        }
    }

    func enableRecommendedFilters() {
        let recommendedFilters = [
            "AdGuard Base filter",
            "AdGuard Tracking Protection filter",
            "AdGuard Annoyances filter",
            "EasyPrivacy",
            "Online Malicious URL Blocklist",
            "d3Host List by d3ward",
            "Anti-Adblock List",
        ]

        for index in filterLists.indices {
            if recommendedFilters.contains(filterLists[index].name) {
                filterLists[index].isSelected = true
                print("Enabled recommended filter: \(filterLists[index].name)")
            }
        }
        saveSelectedState()
        hasUnappliedChanges = true
        print("Recommended filters have been enabled")

        // After enabling recommended filters, check for missing filters
        checkAndEnableFilters()
    }

    private func loadCustomFilterLists() {
        guard
            let data = UserDefaults.standard.data(forKey: customFilterListsKey),
            let decoded = try? JSONDecoder().decode(
                [FilterList].self, from: data)
        else {
            return
        }
        customFilterLists = decoded
        filterLists.append(contentsOf: customFilterLists)
    }

    private func saveCustomFilterLists() {
        if let encoded = try? JSONEncoder().encode(customFilterLists) {
            UserDefaults.standard.set(encoded, forKey: customFilterListsKey)
        }
    }

    func addCustomFilterList(name: String, url: URL, description: String = "") {
        let newFilterList = FilterList(
            id: UUID(),
            name: name,
            url: url,
            category: .custom,
            isSelected: false,
            description: description
        )
        customFilterLists.append(newFilterList)
        filterLists.append(newFilterList)
        saveCustomFilterLists()
        saveSelectedState()
    }

    func removeCustomFilterList(_ filterList: FilterList) {
        guard filterList.category == .custom else { return }
        if let index = filterLists.firstIndex(of: filterList) {
            filterLists.remove(at: index)
        }
        if let customIndex = customFilterLists.firstIndex(of: filterList) {
            customFilterLists.remove(at: customIndex)
        }
        saveCustomFilterLists()
        saveSelectedState()
    }
}

// MARK: - Extensions

extension FilterListManager {
    /// Returns all filters except those in the 'Foreign' category
    func allNonForeignFilters() -> [FilterList] {
        return filterLists.filter { $0.category != .foreign }
    }

    /// Returns all filters in the 'Foreign' category
    func foreignFilters() -> [FilterList] {
        return filterLists.filter { $0.category == .foreign }
    }
}
