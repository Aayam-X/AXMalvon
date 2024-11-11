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
    weak var appProperties: AXSessionProperties?
    
    @State private var selectedTabGroup: String = "Math"
    @State private var tabGroupName: String = ""
    @State private var tabGroupColor: Color = .red
    @State private var selectedProfile: String = "School"
    
    let tabGroups = ["Math", "Science", "English", "Global Politics"]
    let profiles = ["School", "Personal"]
    let colors: [Color] = [.red, .pink, .orange, .yellow, .blue]
    
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
                
                // TextField for changing the tab group name
                TextField("Tab Group Name", text: $tabGroupName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical)
                
                // Color selection
                Text("Tab Group Color")
                    .font(.subheadline)
                
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
    
    func updateColor() {
        appProperties?.updateColor(newColor: NSColor(tabGroupColor))
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

#Preview {
    AXTabGroupInformationSwiftUIView()
}
