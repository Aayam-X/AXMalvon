//
//  WBSettingsView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-02.
//

import SwiftUI

struct WBSettingsView: View {
    @AppStorage("updateInterval") private var updateInterval: TimeInterval =
        86400  // Default to 24 hours
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var updateController: WBUpdateController
    @EnvironmentObject var filterListManager: FilterListManager

    let intervalOptions: [(name: String, value: TimeInterval)] = [
        ("1 Hour", 3600),
        ("24 Hours", 86400),
        ("7 Days", 604800),
        ("14 Days", 1_209_600),
        ("30 Days", 2_592_000),
    ]

    var body: some View {
        VStack(spacing: 15) {
            // Header
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 10)

            Divider()

            // Update Interval Dropdown
            VStack(alignment: .leading, spacing: 8) {
                Picker("Check for updates every:", selection: $updateInterval) {
                    ForEach(intervalOptions, id: \.value) { option in
                        Text(option.name).tag(option.value)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(
                    "Note: Automatic updates currently only work while the app is running. It is recommended to update filter lists manually when needed rather than keeping the app running constantly."
                )
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)

            Spacer()

            // Close Button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Close")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 15)
            .frame(maxWidth: .infinity)
        }
        .frame(width: 400, height: 250)
        .padding()
        .onChange(of: updateInterval) { _, newValue in
            Task {
                await updateController.scheduleBackgroundUpdates(
                    filterListManager: filterListManager)
                print("Update interval changed to \(newValue) seconds")
            }
        }
    }
}
