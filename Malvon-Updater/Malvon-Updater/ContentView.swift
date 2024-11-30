//
//  ContentView.swift
//  Malvon-Updater
//
//  Created by Ashwin Paudel on 2024-11-29.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    @State private var statusMessage = "Ready to check for updates."
    @State private var isChecking = false
    @State private var isUpdating = false
    @State private var isUpdateAvailable = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(statusMessage)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: checkForUpdates) {
                Text("Check for Updates")
                    .padding()
                    .cornerRadius(8)
            }
            .disabled(isChecking)
            
            if isUpdateAvailable {
                Button(action: updateApplication) {
                    Text("Update Application")
                        .padding()
                        .background(isUpdating ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isUpdating)
            }
        }
        .padding()
    }
    
    func checkForUpdates() {
        isChecking = true
        statusMessage = "Checking for updates..."
        
        let versionURL = URL(string: "https://raw.githubusercontent.com/ashp0/malvon-website/refs/heads/main/.github/workflows/version.txt")!
        
        let task = URLSession.shared.dataTask(with: versionURL) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    statusMessage = "Failed to check for updates: \(error.localizedDescription)"
                    isChecking = false
                }
                return
            }
            
            guard let data = data, let latestVersion = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                DispatchQueue.main.async {
                    statusMessage = "Failed to read version information."
                    isChecking = false
                }
                return
            }
            
            if let localVersion = getAppVersion() {
                if localVersion != latestVersion {
                    DispatchQueue.main.async {
                        statusMessage = "Update ready: \(localVersion) → \(latestVersion)"
                        isUpdateAvailable = true
                    }
                } else {
                    DispatchQueue.main.async {
                        statusMessage = "You are up-to-date (version \(localVersion))."
                    }
                }
            } else {
                DispatchQueue.main.async {
                    statusMessage = "Could not determine local app version."
                }
            }
            
            isChecking = false
        }
        
        task.resume()
    }
    
    func updateApplication() {
        isUpdating = true
        statusMessage = "Starting update..."
        
        let updateURL = URL(string: "https://github.com/ashp0/malvon-website/raw/refs/heads/main/.github/workflows/Malvon.zip")!
        let downloadDestination = FileManager.default.temporaryDirectory.appendingPathComponent("update-malvon-\(UUID()).zip")
        
        let downloadTask = URLSession.shared.downloadTask(with: updateURL) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    statusMessage = "Download failed: \(error?.localizedDescription ?? "Unknown error")"
                    isUpdating = false
                }
                return
            }
            
            // Move downloaded file to destination
            do {
                try FileManager.default.moveItem(at: tempURL, to: downloadDestination)
                DispatchQueue.main.async {
                    statusMessage = "Download completed. Extracting..."
                }
                extractAndReplace(downloadDestination)
            } catch {
                DispatchQueue.main.async {
                    statusMessage = "Failed to move downloaded file: \(error.localizedDescription)"
                    isUpdating = false
                }
            }
        }
        
        downloadTask.resume()
    }
    
    func extractAndReplace(_ zipFilePath: URL) {
        let unzipDestination = FileManager.default.temporaryDirectory.appendingPathComponent("extractedApp")
        
        do {
            try FileManager.default.createDirectory(at: unzipDestination, withIntermediateDirectories: true)
            let process = Process()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = ["-o", zipFilePath.path, "-d", unzipDestination.path]
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
            try FileManager.default.copyItem(at: appFile, to: URL(fileURLWithPath: currentAppPath))
            
            // Run xattr -cr
            let xattrProcess = Process()
            xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
            xattrProcess.arguments = ["-cr", currentAppPath]
            try xattrProcess.run()
            xattrProcess.waitUntilExit()
            
            DispatchQueue.main.async {
                statusMessage = "Update completed successfully."
                isUpdating = false
                
                Task {
                    _ = try? await Task.sleep(for: .seconds(1))
                    exit(1)
                }
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
              let version = infoDict["CFBundleShortVersionString"] as? String else {
            return nil
        }
        return version
    }
}


#Preview {
    ContentView()
}
