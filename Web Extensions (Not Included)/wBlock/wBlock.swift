//
//  wBlock.swift
//  wBlock
//
//  Created by Ashwin Paudel on 2024-11-21.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import SwiftUI

struct wBlockView: View {
    var body: some View {
        VStack {
            Text("Hello wBlock")
                .font(.title)
                .foregroundColor(.blue)

            Button {
                print("What's good what's good")
            } label: {
                Text("Click me")
            }

        }
        .padding()
    }
}

@objc public class wBlock: NSObject {

    // FIXME: XPC Services does not sandbox views
    @MainActor @objc public func createView() -> NSView {
        // Ensure UI code runs on the main thread
        let swiftUIView = wBlockView()
        let hostingView = NSHostingView(rootView: swiftUIView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 200)
        return hostingView
    }

    @objc public func blockerListPath() -> URL? {
        guard let bundle = Bundle(identifier: "com.ayaamx.AXMalvon.wBlock")
        else { return nil }

        let blockerList = bundle.url(
            forResource: "blockerList", withExtension: "json")

        return blockerList
        // Download if bundle doesn't exist
        //        if let bundleURL = Bundle(identifier: "com.ayaamx.AXMalvon.wBlock")?
        //            .url(forResource: "blockerList", withExtension: "json")
        //        {
        //            return bundleURL
        //        }
        //        // FIXME: Download the file from https://raw.githubusercontent.com/ashp0/AdBlockList/refs/heads/main/blockerList.json
        //
        //        return nil
    }
}
