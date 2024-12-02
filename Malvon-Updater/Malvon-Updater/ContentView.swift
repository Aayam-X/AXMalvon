//
//  ContentView.swift
//  Malvon-Updater
//
//  Created by Ashwin Paudel on 2024-11-29.
//

import SwiftUI

enum AppVersionProvider {
    static func appVersion(in bundle: Bundle = .main) -> String {
        guard
            let version = bundle.object(
                forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        else {
            fatalError(
                "CFBundleShortVersionString should not be missing from info dictionary"
            )
        }
        return version
    }
}

struct ContentView: View {
    @State var statusMessage: String = ""
    @State var isUpdateAvailable: Bool = true
    @State var isUpdating: Bool = false

    @State var updateCompleted: Bool = false
    @State var showCheckmark: Bool = false

    @State var updateMessage: String =
        "Finding the latest version..."
    @State var latestVersion: String = "1.0.0"

    var body: some View {
        ZStack {
            VisualEffectView()  // Assume this is implemented elsewhere
                .edgesIgnoringSafeArea(.all)

            if updateCompleted {
                // Green Checkmark Animation
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .scaleEffect(showCheckmark ? 1 : 0)
                            .frame(width: 150, height: 150)
                            .animation(
                                .easeOut(duration: 0.5), value: showCheckmark)

                        Image(systemName: "checkmark")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(showCheckmark ? 1 : 0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.5),
                                value: showCheckmark)
                    }

                    Text("Update Completed Successfully")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .onAppear {
                    showCheckmark = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        let appURL = URL(
                            fileURLWithPath: "/Applications/Malvon.app")
                        let workspaceConfig = NSWorkspace.OpenConfiguration()
                        workspaceConfig.activates = true

                        NSWorkspace.shared.openApplication(
                            at: appURL, configuration: workspaceConfig)

                        // Delay exit to ensure the application launch request is processed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            exit(0)
                        }
                    }
                }
            } else {
                HStack {
                    // Left Section: App Icon and Name
                    VStack {
                        if let image = NSImage(
                            named: NSImage.applicationIconName)
                        {
                            Image(nsImage: image)  // Replace with actual app icon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .shadow(radius: 5)
                        } else {
                            Image(systemName: "square.fill")  // Replace with actual app icon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .shadow(radius: 5)
                        }

                        Text("Malvon \(latestVersion)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                    .shadow(
                        color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)

                    Divider()  // The divider between sections

                    // Right Section: Update Information
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("Update is Available")
                            .font(.title)
                            .fontWeight(.bold)

                        // Update Description
                        if isUpdateAvailable
                        {
                            TextEditor(text: .constant(updateMessage))
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(
                                    color: Color.black.opacity(0.1), radius: 5,
                                    x: 0, y: 2)
                        }

                        // Update Button
                        VStack {
                            Button(action: updateApplication) {
                                Text(isUpdating ? "Updating..." : "Update Now")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        isUpdating ? Color.gray : Color.green
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .shadow(
                                        color: Color.black.opacity(0.2),
                                        radius: 5,
                                        x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .disabled(isUpdating)

                            Text(statusMessage)
                                .font(.caption)
                                .fontWeight(.light)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .frame(maxHeight: .infinity)
                .onAppear {
                    Task {
                        await checkForUpdates()
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions
    func checkForUpdates() async {
        statusMessage = "Checking for updates..."

        guard
            let versionURL = URL(
                string:
                    "https://raw.githubusercontent.com/ashp0/malvon-website/refs/heads/main/.github/workflows/version.txt"
            ),
            let updateInfoURL = URL(
                string:
                    "https://raw.githubusercontent.com/ashp0/malvon-website/refs/heads/main/.github/workflows/info.txt"
            )
        else {
            statusMessage = "Invalid update URL."
            return
        }

        do {
            let latestVersion = try await fetchText(from: versionURL)
            updateMessage = try await fetchText(from: updateInfoURL)

            if let localVersion = getAppVersion() {
                if localVersion != latestVersion {
                    statusMessage = "An update is available for Malvon"
                    self.latestVersion = latestVersion
                    isUpdateAvailable = true
                } else {
                    statusMessage =
                        "You are up-to-date (version \(localVersion))."
                }
            } else {
                statusMessage = "Could not determine local app version."
            }
        } catch {
            statusMessage =
                "Unable to check for updates: \(error.localizedDescription)"
        }
    }

    func updateApplication() {
        statusMessage = "Starting update..."

        let updateURL = URL(
            string:
                "https://github.com/ashp0/malvon-website/raw/refs/heads/main/.github/workflows/Malvon.zip"
        )!
        let downloadDestination = FileManager.default.temporaryDirectory
            .appendingPathComponent("update-malvon-\(UUID()).zip")

        let downloadTask = URLSession.shared.downloadTask(with: updateURL) {
            tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    statusMessage =
                        "Download failed: \(error?.localizedDescription ?? "Unknown error")"
                    isUpdating = false
                }
                return
            }

            // Move downloaded file to destination
            do {
                try FileManager.default.moveItem(
                    at: tempURL, to: downloadDestination)
                DispatchQueue.main.async {
                    statusMessage = "Download completed. Extracting..."
                }
                extractAndReplace(downloadDestination)
            } catch {
                DispatchQueue.main.async {
                    statusMessage =
                        "Failed to move downloaded file: \(error.localizedDescription)"
                    isUpdating = false
                }
            }
        }

        downloadTask.resume()
    }

    func extractAndReplace(_ zipFilePath: URL) {
        let unzipDestination = FileManager.default.temporaryDirectory
            .appendingPathComponent("extractedApp")

        do {
            try FileManager.default.createDirectory(
                at: unzipDestination, withIntermediateDirectories: true)
            let process = Process()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = [
                "-o", zipFilePath.path, "-d", unzipDestination.path,
            ]
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                DispatchQueue.main.async {
                    statusMessage = "Extraction failed."
                    isUpdating = false
                }
                return
            }

            let appFile = unzipDestination.appendingPathComponent("Malvon.app")
            let currentAppPath = "/Applications/Malvon.app"

            // Replace the current app
            try? FileManager.default.removeItem(atPath: currentAppPath)
            try FileManager.default.copyItem(
                at: appFile, to: URL(fileURLWithPath: currentAppPath))

            // Run xattr -cr
            let xattrProcess = Process()
            xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            xattrProcess.arguments = ["-cr", currentAppPath]
            try xattrProcess.run()
            xattrProcess.waitUntilExit()

            DispatchQueue.main.async {
                statusMessage = "Update completed successfully."
                isUpdating = false
                updateCompleted = true
            }
        } catch {
            DispatchQueue.main.async {
                statusMessage = "Update failed: \(error.localizedDescription)"
                isUpdating = false
            }
        }
    }

    func getAppVersion() -> String? {
        guard let infoDict = Bundle.main.infoDictionary,
            let version = infoDict["CFBundleShortVersionString"] as? String
        else {
            return nil
        }
        return version
    }

    func fetchText(from url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let text = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        return text
    }
}

// MARK: - VisualEffectView for macOS-like background
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear  //<<here clear
            drawsBackground = false
        }

    }
}

#Preview {
    ContentView()
}
