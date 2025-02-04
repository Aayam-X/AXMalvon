//
//  AXExtensionDownloaderView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2025-02-04.
//

import SwiftUI

struct AXExtensionDownloaderView: View {
    @State var crxExtension: CRXExtension
    @State private var permissions: [String] = []

    @State private var installButtonDisabled: Bool = true

    var onDismiss: (() -> Void)
    var onInstall: (() -> Void)

    var body: some View {
        VStack {
            HStack(spacing: 10) {
                // Left Side: Extension Name and Warning Message
                VStack(alignment: .leading, spacing: 10) {
                    Text("Install Browser Extension")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)

                    Text(
                        "Downloading an extension from an untrusted source can be dangerous."
                    )
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.bottom, 10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name: \(crxExtension.name)")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1))

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                // Right Side: Permissions List
                VStack(alignment: .leading, spacing: 10) {
                    if !permissions.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(
                                        systemName:
                                            "exclamationmark.triangle.fill"
                                    )
                                    .foregroundColor(.yellow)
                                    Text("Permissions Warning")
                                        .font(.headline)
                                        .foregroundColor(.yellow)
                                }

                                ForEach(permissions, id: \.self) { permission in
                                    Text("• \(permission)")
                                }
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }

            Spacer()

            // Buttons Row
            HStack {
                Button("Cancel") {
                    // Implement deletion logic here.
                    crxExtension.remove()
                    onDismiss()
                }
                .buttonStyle(.bordered)

                Button("Show Folder Path") {
                    if let folder = crxExtension.extensionFolder {
                        NSWorkspace.shared.open(folder)
                    }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Install") {
                    // Implement extension installation logic here.
                    onInstall()
                    print(self.permissions)
                }
                .buttonStyle(.borderedProminent)
                .disabled(installButtonDisabled)
            }
        }
        .frame(width: 500, height: 350)
        .padding()
        .onAppear {
            Task {
                await crxExtension.download()
                self.permissions =
                    crxExtension.parseManifest()?.permissions ?? []
                installButtonDisabled = false
            }
        }
    }
}
