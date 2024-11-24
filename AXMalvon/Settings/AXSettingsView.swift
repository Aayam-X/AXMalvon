//
//  AXSettingsView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-24.
//

import SwiftUI

struct AXSettingsView: View {
    @State private var selectedSection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsSection.allCases, selection: $selectedSection) {
                section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("Settings")
        } detail: {
            // Content
            if let section = selectedSection {
                section.contentView
            } else {
                Text("Select a setting")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Enum to manage sections
enum SettingsSection: String, Identifiable, CaseIterable {
    case general
    case appearance
    case profiles
    case notifications

    var id: String { self.rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .appearance: return "Appearance"
        case .profiles: return "Profiles"
        case .notifications: return "Notifications"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gear"
        case .appearance: return "paintbrush"
        case .profiles: return "person.and.background.dotted"
        case .notifications: return "bell"
        }
    }

    @ViewBuilder
    var contentView: some View {
        switch self {
        case .general:
            GeneralSettingsView()
        case .appearance:
            AppearanceSettingsView()
        case .profiles:
            AXProfileSettingsView()
        case .notifications:
            NotificationsSettingsView()
        }
    }
}

// Placeholder views for each section
struct GeneralSettingsView: View {
    var body: some View {
        Text("General Settings")
            .font(.largeTitle)
            .padding()
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        Text("Appearance Settings")
            .font(.largeTitle)
            .padding()
    }
}

struct NotificationsSettingsView: View {
    var body: some View {
        Text("Notifications Settings")
            .font(.largeTitle)
            .padding()
    }
}

#Preview {
    AXSettingsView()
}
