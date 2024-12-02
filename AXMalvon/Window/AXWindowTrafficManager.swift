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
    private var overlays: [OverlayView] = []
    private var buttons: [NSButton]

    init(window: AXWindow) {
        self.window = window

        self.buttons = [
            window.standardWindowButton(.closeButton)!,
            window.standardWindowButton(.miniaturizeButton)!,
            window.standardWindowButton(.zoomButton)!,
        ]

        updateTrafficLights()
        hideTrafficLights(true)

        //        for (index, button) in buttons.enumerated() {
        //            button.frame.origin = NSPoint(x: 13.0 + CGFloat(index) * 20.0, y: 0)
        //            button.alphaValue = 0.3
        //
        //            let overlaySize = min(button.bounds.width, button.bounds.height)
        //            let overlayFrame = NSRect(
        //                x: (button.bounds.width - overlaySize) / 2,
        //                y: (button.bounds.height - overlaySize) / 2,
        //                width: overlaySize,
        //                height: overlaySize
        //            )
        //
        //            let overlayView = OverlayView(frame: overlayFrame)
        //            button.addSubview(overlayView, positioned: .above, relativeTo: nil)
        //            overlays.append(overlayView)
        //        }
    }

    func hideTrafficLights(_ b: Bool) {
        buttons.forEach { button in
            button.isHidden = b
        }
    }

    func updateTrafficLights() {
        // Update positioning
        for (index, button) in buttons.enumerated() {
            button.frame.origin = NSPoint(x: 13.0 + CGFloat(index) * 20.0, y: 0)
        }
    }

    func hideButtons() {
        hideTrafficLights(false)

        //        for button in buttons {
        //            button.alphaValue = 1.0
        //        }
        //        for overlay in overlays {
        //            overlay.removeFromSuperview()
        //        }
    }

    func showButtons() {
        hideTrafficLights(true)

        //        for (index, button) in buttons.enumerated() {
        //            button.alphaValue = 0.3
        //            button.addSubview(
        //                overlays[index], positioned: .above, relativeTo: nil)
        //        }
    }
}

private class OverlayView: NSView {
    init(frame: NSRect, color: NSColor = .lightGray) {
        super.init(frame: frame)

        self.wantsLayer = true
        if let layer = self.layer {
            layer.backgroundColor = color.cgColor
            layer.cornerRadius = frame.width / 2
            layer.masksToBounds = true
            layer.borderColor = NSColor.darkGray.cgColor
            layer.borderWidth = 1.0
        }
        self.alphaValue = 1.0  // Initially hidden

        let trackingArea = NSTrackingArea(
            rect: self.bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )

        self.addTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
