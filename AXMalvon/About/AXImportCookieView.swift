//
//  AXImportCookieView.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2024-12-01.
//

//import SQLite3
//import SwiftUI
//import WebKit
//
//class CookieManager: ObservableObject {
//    var defaultConfiguration: WKWebViewConfiguration? {
//        if let profile = AXProfile.loadProfile(name: "Default") {
//            return AXProfile.createConfig(with: profile.configID)
//        }
//        return nil
//    }
//
//    func readChromiumCookies(at dbPath: String) {
//        var db: OpaquePointer?
//
//        if sqlite3_open(dbPath, &db) == SQLITE_OK {
//            let query =
//                "SELECT host_key, name, value, path, expires_utc, secure, httponly FROM cookies;"
//            var statement: OpaquePointer?
//
//            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
//                while sqlite3_step(statement) == SQLITE_ROW {
//                    if let host = sqlite3_column_text(statement, 0),
//                        let name = sqlite3_column_text(statement, 1),
//                        let value = sqlite3_column_text(statement, 2),
//                        let path = sqlite3_column_text(statement, 3)
//                    {
//
//                        let hostKey = String(cString: host)
//                        let nameKey = String(cString: name)
//                        let valueKey = String(cString: value)
//                        let pathKey = String(cString: path)
//
//                        let isSecure = sqlite3_column_int(statement, 5) == 1
//                        let isHttpOnly = sqlite3_column_int(statement, 6) == 1
//
//                        var expiresDate: Date?
//                        let expiresUtc = sqlite3_column_int64(statement, 4)
//                        if expiresUtc != 0 {
//                            expiresDate = Date(
//                                timeIntervalSince1970: Double(
//                                    expiresUtc - 11_644_473_600_000_000)
//                                    / 1_000_000)
//                        }
//
//                        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
//                            .domain: hostKey,
//                            .path: pathKey,
//                            .name: nameKey,
//                            .value: valueKey,
//                            .secure: isSecure,
//                            .expires: expiresDate as Any,
//                        ]
//
//                        if let cookie = HTTPCookie(properties: cookieProperties)
//                        {
//                            self.insertCookie(cookie)
//                        }
//                    }
//                }
//            }
//            sqlite3_finalize(statement)
//        }
//
//        sqlite3_close(db)
//
//        AppDelegate.relaunchApplication()
//    }
//
//    private func insertCookie(_ cookie: HTTPCookie) {
//        guard let defaultConfiguration else { return }
//
//        Task {
//            await defaultConfiguration.websiteDataStore.httpCookieStore
//                .setCookie(cookie)
//        }
//    }
//}
//
//struct AXImportCookieView: View {
//    @StateObject private var cookieManager = CookieManager()
//
//    var body: some View {
//        VStack {
//            Text("Import from Another Browser")
//                .font(.title)
//                .bold()
//
//            Divider()
//
//            Text("Choose a browser to import cookies from:")
//
//            Button {
//                cookieManager.readChromiumCookies(
//                    at:
//                        "\(NSHomeDirectory())/Library/Application Support/Google/Chrome/Default/Cookies"
//                )
//            } label: {
//                Text("Google Chrome")
//            }
//
//            Button {
//                showFilePicker()
//            } label: {
//                Text("Import using Chromium SQLite")
//            }
//        }
//        .padding()
//    }
//
//    private func showFilePicker() {
//        let openPanel = NSOpenPanel()
//        openPanel.title = "Select Chromium SQLite Cookie File"
//        openPanel.canChooseFiles = true
//        openPanel.canChooseDirectories = false
//        openPanel.allowsMultipleSelection = false
//        openPanel.allowedContentTypes = [.fileURL]
//
//        if openPanel.runModal() == .OK {
//            if let selectedURL = openPanel.url {
//                cookieManager.readChromiumCookies(at: selectedURL.path)
//            }
//        }
//    }
//}
//
//#Preview {
//    AXImportCookieView()
//}

//class ChromeCookieImporter {
//    /// Imports cookies from Google Chrome's SQLite database into a WKWebView
//    /// - Parameters:
//    ///   - webView: The WKWebView to import cookies into
//    ///   - completionHandler: Called when cookie import is complete
//    static func importChromeCookes(into webView: WKWebView, completionHandler: @escaping (Int) -> Void) {
//        // Get Chrome's default cookie database path
//        let cookiePath = FileManager.default.homeDirectoryForCurrentUser
//            .appendingPathComponent("Library/Application Support/Google/Chrome/Default/Cookies").path
//
//        // Ensure the database file exists
//        guard FileManager.default.fileExists(atPath: cookiePath) else {
//            completionHandler(0)
//            return
//        }
//
//        // Open the SQLite database
//        var database: OpaquePointer?
//        guard sqlite3_open(cookiePath, &database) == SQLITE_OK else {
//            completionHandler(0)
//            return
//        }
//
//        // Prepare SQL query to fetch cookies
//        let querySql = """
//            SELECT host_key, name, value, path, expires_utc, is_secure, is_httponly
//            FROM cookies
//        """
//        var statement: OpaquePointer?
//
//        guard sqlite3_prepare_v2(database, querySql, -1, &statement, nil) == SQLITE_OK else {
//            sqlite3_close(database)
//            completionHandler(0)
//            return
//        }
//
//        // Group to manage async cookie imports
//        let group = DispatchGroup()
//        var successfulCookieCount = 0
//
//        // Process each cookie
//        while sqlite3_step(statement) == SQLITE_ROW {
//            group.enter()
//
//            // Extract cookie properties
//            guard let hostKey = sqlite3_column_text(statement, 0),
//                  let name = sqlite3_column_text(statement, 1),
//                  let value = sqlite3_column_text(statement, 2),
//                  let path = sqlite3_column_text(statement, 3) else {
//                group.leave()
//                continue
//            }
//
//            let hostKeyStr = String(cString: hostKey)
//            let nameStr = String(cString: name)
//            let valueStr = String(cString: value)
//            let pathStr = String(cString: path)
//
//            // Convert expires_utc to Date
//            let expiresUtc = sqlite3_column_int64(statement, 4)
//            let isSecure = sqlite3_column_int(statement, 5) != 0
//            let isHttpOnly = sqlite3_column_int(statement, 6) != 0
//
//            // Convert Chrome's timestamp (WebKit epoch) to Date
//            let date = convertChromeTimestamp(expiresUtc)
//
//            // Create and set cookie
//            var cookieProperties: [HTTPCookiePropertyKey: Any] = [
//                .domain: hostKeyStr.hasPrefix(".") ? hostKeyStr : "." + hostKeyStr, // Ensure leading dot for subdomains
//                .name: nameStr,
//                .value: valueStr,
//                .path: pathStr,
//                .secure: isSecure,
//                .expires: date ?? Date().addingTimeInterval(86400)
//            ]
//
//            if let httpOnlyCookie = HTTPCookie(properties: cookieProperties) {
//                // Import cookie into WKWebView
//                webView.configuration.websiteDataStore.httpCookieStore.setCookie(httpOnlyCookie) {
//                    group.leave()
//                    successfulCookieCount += 1
//                    mxPrint("Cookie imported: \(cookieProperties)")
//                }
//            } else {
//                group.leave()
//            }
//        }
//
//        // Cleanup
//        sqlite3_finalize(statement)
//        sqlite3_close(database)
//
//        // Notify when all cookies are imported
//        group.notify(queue: .main) {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                completionHandler(successfulCookieCount)
//            }
//        }
//    }
//
//    /// Converts Chrome's timestamp to Date
//    /// Chrome uses WebKit epoch (Jan 1, 1601) vs Unix epoch (Jan 1, 1970)
//    private static func convertChromeTimestamp(_ timestamp: Int64) -> Date? {
//        // Chrome timestamp is in microseconds since Jan 1, 1601
//        let webKitEpoch = TimeInterval(timestamp / 1000000)
//        let unixTimestamp = webKitEpoch - 11644473600 // Difference between WebKit and Unix epochs
//        return Date(timeIntervalSince1970: unixTimestamp)
//    }
//}
