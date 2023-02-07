//
//  UsefulCode.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-06.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import SecurityInterface

// Dispkay certificate
SFCertificateTrustPanel.shared().beginSheet(for: appProperties?.window, modalDelegate: nil, didEnd: nil, contextInfo: nil, trust: appProperties?.currentTab.view.serverTrust, message: "TLS Certificate Details")


import WebKit
// Experimental Menu Items
let experimentalFeatures = WKPreferences.value(forKey: "experimentalFeatures")
// as! _WKExperimentalFeature


// Cookie or something
let response = navigationResponse.response as! HTTPURLResponse
let headFields = response.allHeaderFields as! [String: String]


print("HEADERF FIELDS: \(headFields)")
// let cookies = HTTPCookie.cookies(withResponseHeaderFields: headFields, for: response.url!)
// for cookie in cookies {
//  print("name: \(cookie.name) value: \(cookie.value)")
// }
