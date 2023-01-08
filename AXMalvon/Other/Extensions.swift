//
//  Extensions.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2022-12-25.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit

extension NSWindow {
    static func create(styleMask: NSWindow.StyleMask, size: NSSize) -> NSWindow {
        let window = NSWindow(
            contentRect: .init(origin: .zero, size: size),
            styleMask: [.titled, styleMask],
            backing: .buffered,
            defer: false
        )
        
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.isReleasedWhenClosed = false
        
        return window
    }
}

extension Array {
    subscript (safe index: Index) -> Element? {
        0 <= index && index < count ? self[index] : nil
    }
}

extension String {
    func isValidURL() -> Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
    
    func hasWhitespace() -> Bool {
        return rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }
    
    func string(after: Int) -> String {
        let index = self.index(startIndex, offsetBy: after)
        return String(self[index...])
    }
    
    func isValidEmail() -> Bool {
        guard self.count <= 254 else {
            return false
        }
        let pos = self.lastIndex(of: "@") ?? self.endIndex
        return (pos != self.startIndex)
        && ((self.lastIndex(of: ".") ?? self.startIndex) > pos)
        && (self[pos...].count > 4)
    }
    
    func isValidPassword() -> Bool {
        let password = self.trimmingCharacters(in: CharacterSet.whitespaces)
        let passwordRegx = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[_#?!@$%^&<>*~:`-]).{8,}$"
        let passwordCheck = NSPredicate(format: "SELF MATCHES %@", passwordRegx)
        return passwordCheck.evaluate(with: password)
    }
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        return path
    }
}

extension NSView {
    func toImage() -> NSImage? {
        guard let bitmapImageRepresentation = self.bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        bitmapImageRepresentation.size = bounds.size
        self.cacheDisplay(in: bounds, to: bitmapImageRepresentation)
        
        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmapImageRepresentation)
        
        return image
    }
}

extension NSImageView {
    func download(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let image = NSImage(data: data)
                self.image = image
            } catch {
                print("Error when finding favicon: URL: \(url) Reason: \(error.localizedDescription)")
            }
        }
    }
}

extension CGPoint {
    static func -(left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
}

extension NSURL {
    static func appDataURL() -> URL {
        do {
            let applicationSupportFolderURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let appName = "Malvon"
            let folder = applicationSupportFolderURL.appendingPathComponent("\(appName)/data", isDirectory: true)
            if !FileManager.default.fileExists(atPath: folder.path) {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            }
            return folder
        } catch {
            fatalError("Application Support Directory Not Found")
        }
    }
}
