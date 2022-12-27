//
//  AXPreferenceGeneralView.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-27.
//  Copyright © 2022 Aayam(X). All rights reserved.
//

import Cocoa

class AXPreferenceGeneralView: NSView {
    fileprivate var hasDrawn: Bool = false
    
    override func viewWillDraw() {
        if !hasDrawn {
            // TODO: Implement this
            
            self.setFrameSize(.init(width: 530, height: 220))
            
            hasDrawn = true
        }
    }
}
