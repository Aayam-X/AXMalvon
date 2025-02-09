//
//  AXWelcomeView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-29.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import SwiftUI
import WebKit

/* Test application for others to review
struct AXWelcomeView: View {
    @AppStorage("emailAddress") var emailAddress: String =
        "malvontestuser@gmail.com"
    @AppStorage("verticalTabs") var usesVerticalTabs: Bool = false

    @State private var buttonText: String = "Continue"

    var body: some View {
        VStack {
            Text("Welcome to Malvon!")
                .font(.largeTitle)
                .bold()

            Text("Would you like to enable vertical tabs?")
            Toggle(isOn: $usesVerticalTabs) {
                Text("Vertical Tabs")
            }

            Button("Continue") {
                verifyEmailAddress()
                AppDelegate.relaunchApplication()
            }
            .padding()
        }
        .padding()
    }

    func verifyEmailAddress() {
        emailAddress = "malvontestuser@gmail.com"
    }
}
 */

struct AXWelcomeView: View {
    @AppStorage("emailAddress")
    var emailAddress: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var buttonText: String = "Start Using"
    @State private var navigateToImportView = false  // State to control navigation

    var body: some View {
        if !navigateToImportView {
            VStack {
                Text("Welcome to Malvon!")
                    .font(.largeTitle)
                    .bold()

                Button(buttonText) {
                    buttonText = "Loading"
                    AppDelegate.relaunchApplication()
                }
            }
            .padding()
        } else {
            // AXImportCookieView()
            VStack {
                Text("Import from Other Browser")
                Text(
                    "Feature not yet implemented. Wait for a future release."
                )
                
                Button(buttonText) {
                    buttonText = "Loading"
                    AppDelegate.relaunchApplication()
                }
            }
            .padding()
        }
    }
}

#Preview {
    AXWelcomeView()
}
