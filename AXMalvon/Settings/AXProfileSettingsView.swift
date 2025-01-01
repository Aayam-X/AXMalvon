//
//  AXProfileSettingsView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-24.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import SwiftUI
import WebKit

class AXProfileManager: ObservableObject {
    @Published var profiles: [AXProfile] = []

    init() {
        // Load profiles from UserDefaults or create a default profile
        let names = ["Default", "School"]
        profiles = names.map { AXProfile(name: $0) }
    }
}

struct AXProfileSettingsView: View {
    @ObservedObject var profileManager = AXProfileManager()
    @State private var selectedIndex: Int?
    @State private var showsInspector: Bool = false

    var body: some View {
        VStack {
            Text("Profiles Settings")
                .font(.largeTitle)

            List(
                profileManager.profiles.indices, id: \.self,
                selection: $selectedIndex
            ) { index in
                Text(profileManager.profiles[index].name)
            }
            .onChange(of: selectedIndex) { _, newValue in
                showsInspector = newValue != nil
            }
        }
        .padding()
        .inspector(isPresented: $showsInspector) {
            if let index = selectedIndex,
                profileManager.profiles.indices.contains(index) {
                AXProfileSettingsInspector(
                    profile: $profileManager.profiles[index])
            }
        }
    }
}

struct AXProfileSettingsInspector: View {
    @Binding var profile: AXProfile
    @State private var profileName: String

    init(profile: Binding<AXProfile>) {
        self._profile = profile
        self._profileName = State(initialValue: profile.wrappedValue.name)
    }

    var body: some View {
        VStack {
            Text("Edit Profile")
                .font(.headline)
                .padding()

            TextField("Profile Name", text: $profileName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Save") {
                profile.name = profileName
            }
            .padding()
        }
    }
}

#Preview {
    AXProfileSettingsView()
}
