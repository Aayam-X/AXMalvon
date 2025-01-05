//
//  AXAppearanceSettingsView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-01-05.
//  Copyright © 2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("verticalTabs")
    private var verticalTabs = false

    var body: some View {
        Text("Appearance Settings")
            .font(.largeTitle)
            .padding()

        Toggle(isOn: $verticalTabs) {
            Text("Vertical Tabs")
        }
        .onChange(of: verticalTabs) {
            updateAppearance()
        }
    }

    func updateAppearance() {
        for window in NSApplication.shared.windows {
            guard let newWindow = window as? AXWindow else { continue }

            newWindow.switchViewLayout(nil)
        }
    }
}
