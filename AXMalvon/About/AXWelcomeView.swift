//
//  AXWelcomeView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-29.
//

import SwiftUI
import WebKit

//struct AXWelcomeView: View {
//    @AppStorage("emailAddress") var emailAddress: String =
//        "malvontestuser@gmail.com"
//    @AppStorage("verticalTabs") var usesVerticalTabs: Bool = false
//
//    @State private var buttonText: String = "Continue"
//
//    var body: some View {
//        VStack {
//            Text("Welcome to Malvon!")
//                .font(.largeTitle)
//                .bold()
//
//            Text("Would you like to enable vertical tabs?")
//            Toggle(isOn: $usesVerticalTabs) {
//                Text("Vertical Tabs")
//            }
//
//            Button("Continue") {
//                verifyEmailAddress()
//                AppDelegate.relaunchApplication()
//            }
//            .padding()
//        }
//        .padding()
//    }
//
//    func verifyEmailAddress() {
//        emailAddress = "malvontestuser@gmail.com"
//    }
//}

struct AXWelcomeView: View {
    @AppStorage("emailAddress") var emailAddress: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var buttonText: String = "Continue"
    @State private var navigateToImportView = false  // State to control navigation

    var body: some View {
        if !navigateToImportView {
            VStack {
                Text("Welcome to Malvon!")
                    .font(.largeTitle)
                    .bold()

                Text(
                    "Those who have been accepted into the Malvon waitlist will automatically possess a valid email address needed to use this application. If you are not on the waitlist, please sign up for the waitlist by clicking the following link: https://ashp0.github.io/malvon-website/waitlist"
                )
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(10)

                TextField("Waitlist Email Address", text: $emailAddress)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .padding()

                Button(buttonText) {
                    buttonText = "Loading (Takes a maximum of 30 seconds)"
                    verifyEmailAddress()
                }
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Verification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage == "Email verified." {
                            //navigateToImportView = true
                            showAlert = true
                            AppDelegate.relaunchApplication()
                            exit(1)
                        }
                    })
            }
        } else {
            //AXImportCookieView()
            VStack {
                Text("Import from Other Browser")
                Text(
                    "Feature not yet implemented. Wait for a future release."
                )
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Verification"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage == "Email verified." {
                            showAlert = true
                            AppDelegate.relaunchApplication()
                        }
                    })
            }
        }
    }

    func verifyEmailAddress() {
        guard
            let url = URL(
                string:
                    "https://malvon-beta.web.app/?user_exists=\(emailAddress)"
            )
        else {
            alertMessage = "Invalid URL."
            showAlert = true
            return
        }

        let webView = WKWebView()
        let request = URLRequest(url: url)
        webView.load(request)

        Task {
            let timeout: TimeInterval = 30
            let startTime = Date()

            while true {
                let result = try await webView.evaluateJavaScript(
                    "document.body.innerText")

                if let result = result as? String {
                    if result.lowercased() == "yes" {
                        self.alertMessage = "Email verified."
                        self.showAlert = true
                        navigateToImportView = true

                        break
                    }
                } else {
                    self.alertMessage = "Failed to verify email."
                    // Try again
                }

                if Date().timeIntervalSince(startTime) > timeout {
                    alertMessage = "Verification timed out."
                    showAlert = true
                    return
                }

                try await Task.sleep(for: .seconds(3))
            }
        }
    }
}

#Preview {
    AXWelcomeView()
}
