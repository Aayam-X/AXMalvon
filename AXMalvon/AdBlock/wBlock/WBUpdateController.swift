//
//  WBUpdateController.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-02.
//

import Foundation
import SwiftUI
import UserNotifications
import os.log

@MainActor
class WBUpdateController: ObservableObject {
    static let shared = WBUpdateController()

    @Published var isCheckingForUpdates = false
    @Published var updateAvailable = false
    @Published var latestVersion: String?

    private var updateTimer: DispatchSourceTimer?

    private init() {}

    /// Schedules background updates for filter lists
    func scheduleBackgroundUpdates(filterListManager: FilterListManager) async {
        // Cancel existing timer if any
        updateTimer?.cancel()
        updateTimer = nil

        // Get the selected update interval
        let interval = UserDefaults.standard.double(forKey: "updateInterval")
        let updateInterval = interval > 0 ? interval : 86400  // Default to 1 day if not set

        // Log that we're scheduling background updates
        print(
            "Scheduling background updates with interval: \(updateInterval) seconds"
        )

        let timer = DispatchSource.makeTimerSource(
            queue: DispatchQueue.global())
        timer.schedule(
            deadline: .now() + updateInterval, repeating: updateInterval)
        timer.setEventHandler { [weak self] in
            Task {
                print("Automatic update check started.")
                let updatedFilters = await filterListManager.autoUpdateFilters()
                if !updatedFilters.isEmpty {
                    await self?.sendUpdateNotification(
                        updatedFilters: updatedFilters)
                } else {
                    print(
                        "No updates found during automatic update check.")
                }
            }
        }
        timer.resume()
        updateTimer = timer
    }

    /// Sends a user notification listing the updated filters
    private func sendUpdateNotification(updatedFilters: [FilterList]) async {
        let filterNames = updatedFilters.map { $0.name }.joined(separator: ", ")
        let content = UNMutableNotificationContent()
        content.title = "wBlock Filters Updated"
        content.body = "The following filters have been updated: \(filterNames)"
        content.sound = .default

        // Create the notification request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil)

        // Schedule the notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Notification scheduled successfully.")
        } catch {
            print(
                "Failed to schedule notification: \(error.localizedDescription)"
            )
        }
    }
}
