//
//  AXProfileSettingsView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-24.
//

import SwiftUI
import WebKit

struct AXProfileSettingsView: View {
    var body: some View {
        VStack {
            Text("Profiles Settings")
                .font(.largeTitle)

            Button {
                Task {
                    await retrieveProfiles()
                }
            } label: {
                Text("Hello?")
            }
        }
        .padding()
    }

    func retrieveProfiles() async {
        let identifiers = await WKWebsiteDataStore.allDataStoreIdentifiers

        for identifier in identifiers {
            if identifier.uuidString == "DB8CAB79-1235-4C26-A5B6-30B829446FE7" {
                // Do nothing
            } else if identifier.uuidString
                == "E3B639AA-8015-45B0-BCDA-11811CBCF6D9"
            {
                // Do nothing
            } else {
                do {
                    try await WKWebsiteDataStore.remove(
                        forIdentifier: identifier)
                } catch {
                    print("Removing profile failed with error: \(error)")
                }
            }
        }

        print(identifiers)
    }
}

#Preview {
    AXProfileSettingsView()
}
