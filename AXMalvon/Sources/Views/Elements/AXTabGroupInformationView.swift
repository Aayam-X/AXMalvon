//
//  AXTabGroupInformationView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-10.
//

import AppKit
import SwiftUI

// Define SwiftUI view for tab groups and profiles
struct AXTabGroupInformationSwiftUIView: View {
    weak var appProperties: AXSessionProperties!
    
    @State private var selectedTabGroup = ""
    
    @State private var tabGroupName: String = ""
    @State private var tabGroupColor: Color = .red
    @State private var selectedProfile: String = "School"
    
    var tabGroups: [String] {
        appProperties.tabManager.currentProfile.tabGroups.map(\.name)
    }

    var profiles: [String] {
        appProperties.tabManager.profiles.map(\.name)
    }
    
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .indigo, .purple, .gray, .black]
    
    init(appProperties: AXSessionProperties!) {
        self.appProperties = appProperties
        // Initialize selectedTabGroup here
        _selectedTabGroup = State(initialValue: appProperties.tabManager.currentProfile.currentTabGroup.name)
    }
    
    var body: some View {
        TabView {
            VStack {
                Text("Tab Groups")
                    .font(.headline)
                
                // PopupButton for selecting tab groups
                Picker("Select Tab Group", selection: $selectedTabGroup) {
                    ForEach(tabGroups, id: \.self) { group in
                        Text(group)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedTabGroup) { _, _ in
                    updateTabGroup()
                }
                
                // TextField for changing the tab group name
                TextField("Tab Group Name", text: $tabGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical)
                
                // Color selection
                Text("Tab Group Color")
                    .font(.subheadline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .onTapGesture {
                                    tabGroupColor = color
                                    updateColor()
                                }
                                .overlay(
                                    Circle()
                                        .stroke(tabGroupColor == color ? Color.gray : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
            }
            .tabItem {
                Text("Tab Groups")
            }
            
            VStack {
                Text("Profiles")
                    .font(.headline)
                
                // PopupButton for selecting profiles
                Picker("Select Profile", selection: $selectedProfile) {
                    ForEach(profiles, id: \.self) { profile in
                        Text(profile)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .tabItem {
                Text("Profiles")
            }
        }
        .padding()
        .frame(width: 300, height: 250)
    }
    
    func updateTabGroup() {
        // Find the index of the item that matches the "selectedTabGroup" variable
        if let index = appProperties.tabManager.currentProfile.tabGroups.firstIndex(where: { $0.name == selectedTabGroup }) {
            // Use the index to switch to the tab group
            appProperties.tabManager.switchTabGroups(to: index)
        } else {
            // Handle the case where no matching tab group is found
            print("Tab group with name '\(selectedTabGroup)' not found.")
        }
    }

    func updateColor() {
        let color = NSColor(tabGroupColor)
        appProperties?.updateColor(newColor: color)
        appProperties.tabManager.currentTabGroup.color = color.withAlphaComponent(0.3)
    }
}

// Embed the SwiftUI view within the NSViewController
class AXTabGroupInformationView: NSViewController {
    weak var appProperties: AXSessionProperties?
    
    init(appProperties: AXSessionProperties?) {
        self.appProperties = appProperties
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        // Create the SwiftUI view
        let swiftUIView = AXTabGroupInformationSwiftUIView(appProperties: appProperties)
        
        // Create an NSHostingView with the SwiftUI view
        self.view = NSHostingView(rootView: swiftUIView)
    }
}
