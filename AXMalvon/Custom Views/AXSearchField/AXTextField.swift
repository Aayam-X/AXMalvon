//
//  AXTextField.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-25.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit

class AXTextField: NSTextField {
    // Prevent the text from being selected when becoming first responder
    override func becomeFirstResponder() -> Bool {
        let status = super.becomeFirstResponder()
        
        let selectionRange = currentEditor()?.selectedRange
        currentEditor()?.selectedRange = .init(location: selectionRange?.length ?? 0, length: 0)
        
        return status
    }
}
