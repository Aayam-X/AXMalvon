//
//  AXTabItem.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-06.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

let newtabURL = Bundle.main.url(forResource: "newtab", withExtension: "html")

struct AXTabItem: Codable {
    var title: String?
    var url: URL?
    var view: AXWebView
    
    enum CodingKeys: CodingKey {
        case title
        case url
    }
    
    static var webViewConfigurationUserInfoKey: CodingUserInfoKey {
        return CodingUserInfoKey(rawValue: "config")!
    }
    
    init(view: AXWebView) {
        self.view = view
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.title = try values.decode(String.self, forKey: .title)
        self.url = try? values.decode(URL.self, forKey: .url)
        
        view = AXWebView(frame: .zero, configuration: decoder.userInfo[AXTabItem.webViewConfigurationUserInfoKey] as! WKWebViewConfiguration)
        view.addConfigurations()
        view.layer?.cornerRadius = 5.0
    }
    
    func load() {
        if let url = url {
            view.load(URLRequest(url: url))
        }
    }
}
