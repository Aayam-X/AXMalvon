//
//  AXAboutView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-23.
//

import SwiftUI

struct AXAboutView: View {
    @State private var iconOffset: CGSize = .zero

    var body: some View {
        HStack(spacing: 20) {
            // App Icon
            ZStack {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .offset(iconOffset)
                    .shadow(radius: 10)
                    .onHover { hovering in
                        if hovering {
                            withAnimation(.easeOut(duration: 0.3)) {
                                iconOffset = .zero
                            }
                        } else {
                            withAnimation(.easeIn(duration: 0.3)) {
                                iconOffset = .zero
                            }
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                withAnimation(.easeOut(duration: 0.1)) {
                                    iconOffset = CGSize(
                                        width: value.location.x - 50,
                                        height: value.location.y - 50)
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.3)) {
                                    iconOffset = .zero
                                }
                            }
                    )
            }
            .frame(width: 120, height: 120)

            // Right Content
            VStack(alignment: .leading, spacing: 10) {
                Text("Malvon")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(
                    "Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved."
                )
                .font(.subheadline)
                .foregroundColor(.secondary)

                HStack {
                    Button(action: {
                        // Contact button action
                    }) {
                        Text("Contact")
                    }

                    Button(action: {
                        // Donate button action
                    }) {
                        Text("Donate")
                    }
                }
            }
            Spacer()
        }
        .padding([.horizontal, .bottom], 20)
        .background(.white)
    }
}

#Preview {
    AXAboutView()
}
