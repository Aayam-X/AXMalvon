//
//  AXProfile.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-11-17.
//

import WebKit

class AXProfile {
    var name: String
    var configuration: WKWebViewConfiguration

    var tabGroups: [AXTabGroup] = []
    var currentTabGroup: AXTabGroup

    // Tab Group related functions
    var currentTabGroupIndex = 0 {
        didSet {
            currentTabGroup = tabGroups[currentTabGroupIndex]
        }
    }

    private let fileName: String

    init(name: String) {
        self.name = name
        fileName = "TabGroups-\(name).json"
        self.currentTabGroup = .init(name: "Default")

        // WebView configuration
        self.configuration = WKWebViewConfiguration()

        let defaults = UserDefaults.standard

        if let configID = defaults.string(forKey: "configurationID-\(name)") {
            let uuid = UUID(uuidString: configID)!
            self.configuration = WKWebViewConfiguration()
            self.configuration.websiteDataStore = .init(forIdentifier: uuid)
        } else {
            let newID = UUID()
            defaults.set(newID.uuidString, forKey: "configurationID-\(name)")

            self.configuration = WKWebViewConfiguration()
            self.configuration.websiteDataStore = .init(forIdentifier: newID)
        }

        addOtherConfigs()

        loadTabGroups()
        print(fileURL)
    }

    // MARK: - User Defaults
    private var fileURL: URL {
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!

        #if DEBUG
            let directoryURL = appSupportDirectory.appendingPathComponent(
                "AXMalvon", isDirectory: true)
        #else
            let directoryURL = appSupportDirectory.appendingPathComponent(
                "Malvon", isDirectory: true)
        #endif

        // Ensure the directory exists
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(
                at: directoryURL, withIntermediateDirectories: true,
                attributes: nil)
        }

        return directoryURL.appendingPathComponent(fileName)
    }

    func saveTabGroups() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(tabGroups)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save tab groups: \(error)")
        }
    }

    func loadTabGroups() {
        let decoder = JSONDecoder()
        decoder.userInfo[.webConfiguration] = self.configuration

        do {
            let data = try Data(contentsOf: fileURL)
            tabGroups = try decoder.decode([AXTabGroup].self, from: data)
        } catch {
            print("Failed to load tab groups or file does not exist: \(error)")
            tabGroups = [AXTabGroup(name: "Untitled Tab Group")]
        }
    }

    func addOtherConfigs() {
        configuration.preferences.setValue(true, forKey: "fullScreenEnabled")
        configuration.preferences.setValue(
            true, forKey: "allowsPictureInPictureMediaPlayback")
        configuration.preferences.setValue(
            true, forKey: "acceleratedDrawingEnabled")
        configuration.preferences.setValue(
            true, forKey: "largeImageAsyncDecodingEnabled")
        configuration.preferences.setValue(
            true, forKey: "animatedImageAsyncDecodingEnabled")
        configuration.preferences.setValue(
            true, forKey: "developerExtrasEnabled")
        configuration.preferences.setValue(
            true, forKey: "loadsImagesAutomatically")
        configuration.preferences.setValue(
            true, forKey: "acceleratedCompositingEnabled")
        configuration.preferences.setValue(
            true, forKey: "canvasUsesAcceleratedDrawing")
        configuration.preferences.setValue(
            true, forKey: "localFileContentSniffingEnabled")
        configuration.preferences.setValue(true, forKey: "appNapEnabled")
        configuration.preferences.setValue(
            false, forKey: "backspaceKeyNavigationEnabled")
    }
}
