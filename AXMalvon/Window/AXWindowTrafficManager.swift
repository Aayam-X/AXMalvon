//
//  AXWindowTrafficManager.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-11-10.
//  Copyright © 2022-2024 Ashwin Paudel, Aayam(X). All rights reserved.
//

import Cocoa

class AXTrafficLightOverlayManager {
    var window: AXWindow
    private var buttons: [NSButton]!

    init(window: AXWindow) {
        self.window = window

        if window.verticalTabs {
            self.buttons = [
                window.standardWindowButton(.closeButton)!,
                window.standardWindowButton(.miniaturizeButton)!,
                window.standardWindowButton(.zoomButton)!,
            ]

            updateTrafficLights()
            hideTrafficLights()
        }
    }

    func _hideTrafficLights(_ b: Bool) {
        guard window.verticalTabs else { return }

        buttons.forEach { button in
            button.isHidden = b
        }
    }

    func updateTrafficLights() {
        guard window.verticalTabs == true else { return }

        // Update positioning
        for (index, button) in buttons.enumerated() {
            button.frame.origin = NSPoint(
                x: 13.0 + CGFloat(index) * 20.0, y: -2)
        }
    }

    func displayTrafficLights() {
        _hideTrafficLights(false)
    }

    func hideTrafficLights() {
        _hideTrafficLights(true)
    }
}
