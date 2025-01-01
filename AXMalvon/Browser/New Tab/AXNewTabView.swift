//
//  AXNewTabView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2024-12-31.
//  Copyright © 2022-2025 Ashwin Paudel, Aayam(X). All rights reserved.
//

import SwiftUI

protocol AXNewTabViewDelegate: AnyObject {
    func didClickVisitedSite(_ site: URL)
    
    // TODO: AXSearchQueryHandler
    // Creating this file will handle any given search query and either show a URL or a string
    func didSearchFor(_ query: String)
}

struct AXNewTabView: View {
    weak var delegate: AXNewTabViewDelegate?
    @State private var searchText: String = ""

    let mostVisitedSites: [(title: String, url: String, iconName: String)] = [
        ("Google", "https://www.google.com", "google.com"),
        ("YouTube", "https://www.youtube.com", "youtube.com"),
        ("Apple", "https://www.apple.com", "apple.com"),
        ("Twitter", "https://twitter.com", "twitter.com"),
        ("Reddit", "https://www.reddit.com", "reddit.com")
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 40) {
                    // Centered Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 12)

                        TextField("Search or enter website address", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .onSubmit {
                                delegate?.didSearchFor(searchText)
                            }

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 8)
                        }
                    }
                    .frame(width: min(600, geometry.size.width - 40)) // Responsive width
                    .frame(height: 44)
                    .background(Color(.systemGray))
                    .cornerRadius(22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color(.systemGray), lineWidth: 1)
                    )

                    // Most Visited Sites
                    ScrollView {
                        LazyVGrid(
                            columns: gridLayout(for: geometry.size.width),
                            spacing: 20
                        ) {
                            ForEach(mostVisitedSites, id: \ .url) { site in
                                MostVisitedSiteView(title: site.title, url: site.url, iconName: site.iconName) {
                                    if let url = URL(string: site.url) {
                                        delegate?.didClickVisitedSite(url)
                                    }
                                }
                                .frame(height: 100)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 80)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func gridLayout(for width: CGFloat) -> [GridItem] {
        let minimumItemWidth: CGFloat = 100
        let spacing: CGFloat = 20
        let availableWidth = width - 40 // Account for horizontal padding
        let numberOfColumns = max(1, Int(availableWidth / (minimumItemWidth + spacing)))

        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: numberOfColumns)
    }
}

struct MostVisitedSiteView: View {
    let title: String
    let url: String
    let iconName: String
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: "https://\(iconName)/favicon.ico")) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            }
            .frame(width: 32, height: 32)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
    }
}

struct AXNewTabView_Previews: PreviewProvider {
    static var previews: some View {
        AXNewTabView()
    }
}
