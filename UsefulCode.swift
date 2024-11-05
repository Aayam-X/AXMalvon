//
//  UsefulCode.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-06.
//  Copyright © 2022-2024 Aayam(X). All rights reserved.
//

import SecurityInterface

// Dispkay certificate
SFCertificateTrustPanel.shared().beginSheet(for: appProperties?.window, modalDelegate: nil, didEnd: nil, contextInfo: nil, trust: appProperties?.currentTab.view.serverTrust, message: "TLS Certificate Details")



// MARK: - WebKit Experimental Features
import WebKit
// Experimental Menu Items
//let experimentalFeatures = WKPreferences.value(forKey: "experimentalFeatures")
// as! _WKExperimentalFeature

// Bridging Header
#import <WebKit/WKPreferencesPrivate.h>

// SwiftCode

import ObjectiveC

let preferencesClass: AnyClass = object_getClass(WKPreferences())!
let experimentalFeaturesKey = "experimentalFeatures"
let experimentalFeatures = object_getIvar(preferencesClass, class_getInstanceVariable(preferencesClass, experimentalFeaturesKey)!) as! _WKExperimentalFeature
