//
//  AXDownloads.swift
//  AXMalvon
//
//  Created by Ashwin Paudel on 2023-01-05.
//  Copyright © 2022-2023 Aayam(X). All rights reserved.
//

import AppKit
import WebKit

// TODO: We must implement this

struct AXDownloadItem {
    var fileName: String
    var location: String
    var date: String!
    var url: URL!
    unowned var download: WKDownload!
}

class AXDownload {
    static var filePath: URL = NSURL.appDataURL().appendingPathComponent("browser.downloads")
    
    static func checkIfFileExists() {
        let file = AXDownload.filePath
        if !FileManager.default.fileExists(atPath: file.path) {
            try! String("").write(to: file, atomically: true, encoding: .utf8)
        }
    }
    
    static func appendItem(title: String, url: String) {
        let today = Date()
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "dd/MM/yyyy"
        let dateString = dateFormat.string(from: today)
        
        let string = "\(title)\r\(url)\r\(dateString)\n"
        let data = string.data(using: .utf8)!
        let handle = FileHandle(forWritingAtPath: AXDownload.filePath.path)!
        handle.seekToEndOfFile()
        handle.write(data)
        handle.closeFile()
    }
    
    static func getAllItems() -> [AXDownloadItem] {
        var items: [AXDownloadItem] = []
        
        let contents = try! String(contentsOf: AXDownload.filePath)
        let lines = contents.split(separator: "\n")
        
        for line in lines {
            let item = parseLine(line)
            items.append(item)
        }
        
        return items
    }
    
    static func removeAll() {
        let file = AXDownload.filePath
        try! String("").write(to: file, atomically: true, encoding: .utf8)
    }
    
    static func updateDownloadFile(items: [AXDownloadItem]) {
        var result = ""
        
        for item in items {
            result += "\(item.fileName) \(item.location) \(item.date)\n"
        }
        
        try! result.write(to: AXDownload.filePath, atomically: true, encoding: .utf8)
    }
}

fileprivate func parseLine(_ line: String.SubSequence) -> AXDownloadItem {
    let values = line.components(separatedBy: " ")
    
    let item = AXDownloadItem(fileName: values.first!, location: values[1], date: values.last!)
    return item
}
