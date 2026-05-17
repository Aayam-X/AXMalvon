//
//  AXProfileSettingsView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-24.
//  Copyright © 2022-2026 Ashwin Paudel, Aayam(X). All rights reserved.
//

import SwiftData
import SwiftUI

/// Profile management UI. Drives directly off the SwiftData store via
/// ``@Query`` so additions, deletions, and renames are reflected without
/// going through any intermediate ``AXProfile`` runtime wrappers — the
/// previous version cloned wrappers on appear and crashed when the user
/// navigated away and back to this section.
struct AXProfileSettingsView: View {
    @Query(sort: \MalvonProfile.position) private var profiles: [MalvonProfile]
    @Environment(\.modelContext) private var modelContext

    @State private var selection: PersistentIdentifier?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Profiles")
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }

            List(selection: $selection) {
                ForEach(profiles) { profile in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.tint)
                        Text(profile.name)
                        Spacer()
                        Text("\(profile.tabGroups.count) groups")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .tag(profile.persistentModelID)
                }
            }
            .frame(minHeight: 200)

            HStack(spacing: 6) {
                Button {
                    addProfile()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add profile")

                Button(role: .destructive) {
                    removeSelected()
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(canRemove == false)
                .help("Remove selected profile")

                Spacer()
                Text("Changes to existing profiles apply on relaunch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .inspector(isPresented: .constant(selection != nil)) {
            if let selection,
                let profile = profiles.first(where: {
                    $0.persistentModelID == selection
                })
            {
                ProfileInspector(profile: profile)
            } else {
                ContentUnavailableView(
                    "No selection",
                    systemImage: "person.circle",
                    description: Text("Select a profile to edit it.")
                )
            }
        }
    }

    private var canRemove: Bool {
        selection != nil && profiles.count > 1
    }

    private func addProfile() {
        let new = MalvonProfile(
            name: defaultNewName(),
            position: profiles.count
        )
        modelContext.insert(new)
        try? modelContext.save()
        selection = new.persistentModelID
    }

    private func removeSelected() {
        guard let selection,
            let profile = profiles.first(where: {
                $0.persistentModelID == selection
            })
        else { return }
        modelContext.delete(profile)
        try? modelContext.save()
        self.selection = nil
    }

    /// Generates a non-colliding default name like "New Profile",
    /// "New Profile 2", etc.
    private func defaultNewName() -> String {
        let existing = Set(profiles.map(\.name))
        if !existing.contains("New Profile") { return "New Profile" }
        var n = 2
        while existing.contains("New Profile \(n)") { n += 1 }
        return "New Profile \(n)"
    }
}

private struct ProfileInspector: View {
    @Bindable var profile: MalvonProfile

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name", text: $profile.name)
                LabeledContent("Tab groups") {
                    Text("\(profile.tabGroups.count)")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("History entries") {
                    Text("\(profile.historyEntries.count)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Storage") {
                LabeledContent("Data store") {
                    Text(profile.dataStoreUUID.uuidString)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    AXProfileSettingsView()
        .modelContainer(PersistenceController.preview)
        .frame(width: 600, height: 400)
}
